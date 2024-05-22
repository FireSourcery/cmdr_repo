import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:cmdr/common/defined_types.dart';

import '../../byte_struct/byte_struct.dart';
import '../../byte_struct/typed_data_ext.dart';
import '../../byte_struct/typed_field.dart';

export '../../byte_struct/byte_struct.dart';

/// Collective def of Packet format specs
// Abstract factory pattern
// for values available without a Packet instance, over prototype object
// effectively the child packet type encapsulated, child class 'static' methods
abstract interface class PacketInterface {
  // const for each packet instance
  // can implement in PacketId for per packet behavior
  int get startId; // alternatively Uint8List
  int get lengthMax; // length in bytes
  int get idHeaderLength; // defined as length only as they start at offset 0
  int get payloadHeaderLength;
  Endian get endian;
  PacketId? idOf(int intId);
  PacketHeader headerOf(TypedData typedData);
  PacketHeaderSync syncHeaderOf(TypedData typedData);

  /// defined position, relative to `packet`.
  /// header fields for buildHeader/parseHeader
  /// required for HeaderParser.
  /// can be derived from header Struct when get offset is available
  TypedOffset get startFieldPart;
  TypedOffset get idFieldPart;
  TypedOffset get lengthFieldPart;
  TypedOffset get checksumFieldPart;

  PacketIdSync get ack;
  PacketIdSync get nack;
  PacketIdSync get abort;

  Packet cast(TypedData typedData);

  // pass to build idOf internally
  // List<PacketId> get values;
  // List<PacketIdSync> get values;
}

/// Packet as interface for mutable view length.
/// as oppose to extending struct directly,
/// Components extend Struct to convince of defining sized. `PacketCaster` retain mutable length
///
/// ffi.Struct current does not allow length < full struct length, or mixin
abstract mixin class Packet implements PacketInterface {
  const Packet();
  // factory Packet.view(PacketCaster packetCaster, Packet packet, int offset, [int? length]) => packetCaster(packet.range(offset, length));

  // alternatively
  // PacketInterface get packetInterface;

  /// derive from either header or packetInterface
  int get payloadIndex => payloadHeaderLength;
  int get payloadLengthMax => lengthMax - payloadIndex;
  int get checksumIndex => checksumFieldPart.offset;
  int get checksumSize => checksumFieldPart.size;

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  // per instance
  // pointer to a buffer, immutable.
  // mutable view use PacketBuffer
  // Holds offset, not directly retain ByteBuffer, to allow packets parts to be defined relatively
  Uint8List get bytes;

  /// immutable, of varying length, by default
  /// mutable with mixin, or PacketBuffer
  /// immutable, always lengthMax, in case of mixin on struct
  int get length => bytes.lengthInBytes;
  int get payloadLength => length - payloadIndex;

  ////////////////////////////////////////////////////////////////////////////////
  /// Header/Payload Pointers using defined boundaries
  ////////////////////////////////////////////////////////////////////////////////
  @protected
  Uint8List get idHeader => Uint8List.sublistView(bytes, 0, idHeaderLength);
  @protected
  Uint8List get header => Uint8List.sublistView(bytes, 0, payloadHeaderLength);
  Uint8List get payload => Uint8List.sublistView(bytes, payloadIndex);

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  @protected
  ByteData get headerWords => ByteData.sublistView(header, 0, idHeaderLength);

  @visibleForTesting
  Uint8List get headerAvailable => Uint8List.sublistView(bytes, 0, payloadHeaderLength.clamp(0, length));

  /// for building/parsing payload 'as' packet,
  /// not needed when payload is a struct with named fields,
  /// temporarily work around returning Lists

  /// payload as TypedIntList, for list operations
  /// truncated views, end set by packet.length. uses packet element size
  Uint8List get payloadAsList8 => Uint8List.sublistView(bytes, payloadIndex);
  Uint16List get payloadAsList16 => Uint16List.sublistView(bytes, payloadIndex);
  Uint32List get payloadAsList32 => Uint32List.sublistView(bytes, payloadIndex);

  /// payload as "words" of select length, for individual entry operations
  /// payload.buffer == packet.buffer, starts at 0 of back buffer
  ByteData get payloadWords => ByteData.sublistView(bytes, payloadIndex);

  /// using ffi NativeType for signature types only
  /// with range check
  List<int> payloadAt<R extends TypedData>(int byteOffset) => payload.intListViewOrEmpty<R>(byteOffset);
  int payloadWordAt<R extends NativeType>(int byteOffset) => payloadWords.wordAt<R>(byteOffset, endian); // throws if header parser fails, length reports lesser value, while checksum passes
  int? payloadWordAtOrNull<R extends NativeType>(int byteOffset) => payloadWords.wordAtOrNull<R>(byteOffset, endian);

  ////////////////////////////////////////////////////////////////////////////////
  /// [Checksum]
  ////////////////////////////////////////////////////////////////////////////////
  static int crc16(Uint8List u8list) {
    var crc = 0;
    for (var j = 0; j < u8list.length; ++j) {
      var byte = u8list[j];
      crc ^= (byte << 8);
      crc = crc;
      for (var i = 0; i < 8; ++i) {
        int temp = (crc << 1);
        if (crc & 0x8000 != 0) {
          temp ^ (0x1021);
        }
        crc = temp;
      }
    }
    return crc;
  }

  static int sum(Uint8List data) => data.sum;

  int Function(Uint8List data) get checksumAlgorithm => sum;

  // static int sum(int previousValue, int element) => previousValue + element;
  // int Function(int previousValue, int element) get checksumAlgorithm => sum;

  /// all bytes excluding checksumField
  /// using length contained in [bytes] view, or length param length
  int checksum([int? payloadLength]) {
    assert((() => (payloadLength == null) ? length == headerAsPayloadType.lengthFieldValue : true).call());
    final checksumMask = ((1 << (checksumSize * 8)) - 1);
    final checksumEnd = checksumIndex + checksumSize;
    final afterChecksumSize = (payloadHeaderLength - checksumEnd) + (payloadLength ?? this.payloadLength);

    var checkSum = 0;
    checkSum += checksumAlgorithm(Uint8List.sublistView(bytes, 0, checksumIndex));
    checkSum += checksumAlgorithm(Uint8List.sublistView(bytes, checksumEnd, afterChecksumSize));
    return checkSum & checksumMask;
  }

  @visibleForTesting
  int get checksumTest => checksum();

  ////////////////////////////////////////////////////////////////////////////////
  /// [Header]
  ///   header context included in 'this'
  ///   cannot be implemented in packet header, struct cannot mixin,
  /// alternatively extension?
  ////////////////////////////////////////////////////////////////////////////////
  // header must be complete
  // can resolve as field in class if compiler does not optimize
  @protected
  PacketHeader get headerAsPayloadType => headerOf(bytes);
  @protected
  PacketHeaderSync get headerAsSyncType => syncHeaderOf(bytes);

  void buildHeaderAs<P extends PacketHeader>(HeaderCaster<P> caster, PacketId packetId) => caster(header).build(packetId, this);

  void fillStartField() => headerAsSyncType.startFieldValue = startId;

  void buildHeaderAsSync(PacketId packetId) {
    fillStartField();
    headerAsSyncType.idFieldValue = packetId.intId;
  }

  void buildHeaderAsPayload(PacketId requestId, int payloadLength) {
    fillStartField();
    headerAsPayloadType.idFieldValue = requestId.intId;
    headerAsPayloadType.lengthFieldValue = payloadLength + payloadHeaderLength;
    headerAsPayloadType.checksumFieldValue = checksum(payloadLength);
  }

  void buildHeader(PacketId packetId, int payloadLength) {
    return switch (packetId) {
      PacketIdSync() => buildHeaderAsSync(packetId),
      PacketIdRequestResponse() => buildHeaderAsPayload(packetId, payloadLength),
      PacketId() => throw UnimplementedError(),
    };
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// parse header
  ////////////////////////////////////////////////////////////////////////////////
  // use shorter type, casting as longer header on smaller bytes will throw. optionally use field offset
  PacketId? get packetId => idOf(headerAsSyncType.idFieldValue); // idOf(idFieldPart.fieldValue(headerWords));
  PacketIdSync? parseSyncId() => switch (packetId) { PacketIdSync syncId => syncId, _ => null };

  /// for valueOrNull from header status
  bool isValidStart(int value) => (value == startId);
  bool isValidId(int value) => (idOf(value) != null);
  bool isValidLength(int value) => (value == value.clamp(payloadHeaderLength, lengthMax));
  bool isValidChecksum(int value) => (value == checksum());

  // bool get isStartValid => isValidStart(headerAsSyncType.startFieldValue);
  // bool get isIdValid => isValidId(headerAsSyncType.idFieldValue);
  // bool get isLengthValid => isValidLength(headerAsPayloadType.lengthFieldValue);
  // bool get isChecksumValid => isValidChecksum(headerAsPayloadType.checksumFieldValue);

  ////////////////////////////////////////////////////////////////////////////////
  /// On partial header, truncated view, header status during parsing
  /// defined using TypedOffset
  ////////////////////////////////////////////////////////////////////////////////
  ByteData get _byteData => ByteData.sublistView(bytes);

  // header struct cannot cast less than full length
  int? get startFieldOrNull => startFieldPart.fieldValueOrNull(_byteData);
  int? get idFieldOrNull => idFieldPart.fieldValueOrNull(_byteData);
  int? get lengthFieldOrNull => lengthFieldPart.fieldValueOrNull(_byteData);
  int? get checksumFieldOrNull => checksumFieldPart.fieldValueOrNull(_byteData);

  // null if not yet received
  bool? get isStartFieldValid => startFieldOrNull.isThen(isValidStart);
  bool? get isIdFieldValid => idFieldOrNull.isThen(isValidId);
  // non-sync only
  bool? get isLengthFieldValid => lengthFieldOrNull.isThen(isValidLength);
  bool? get isChecksumFieldValid => checksumFieldOrNull.isThen(isValidChecksum); // assert(length == lengthFieldOrNull), isPacketComplete == true

  /// derived values using field offset + size
  PacketId? get packetIdOrNull => switch (idFieldOrNull) { int value => idOf(value), null => null }; // null if not found or invalid..
  int? get packetLengthOrNull => switch (packetIdOrNull) { PacketIdSync() => idHeaderLength, PacketId() => lengthFieldOrNull, null => null };
  bool get isPacketComplete => switch (packetLengthOrNull) { int value => (length >= value), null => false };

  ////////////////////////////////////////////////////////////////////////////////
  /// [Payload]
  /// build with Id, pass Header reference
  /// typed with user input values, directly accepting struct would miss deriving meta
  ////////////////////////////////////////////////////////////////////////////////
  PayloadMeta buildPayloadAs<T extends Payload, V>(PayloadCaster<T> caster, V values) => caster(payload).build(values, this);

  V parsePayloadAs<R extends Payload, V>(PayloadCaster<R> caster, [PayloadMeta? stateMeta]) => caster(payload).parse(this, stateMeta);

  PayloadMeta buildRequest<T extends Payload, TV>(PacketIdRequestResponse<T, dynamic> packetId, TV requestArgs) {
    PayloadMeta meta = buildPayloadAs(packetId.requestCaster!, requestArgs);
    if (meta.length > payloadLengthMax) return const PayloadMeta(0);
    buildHeaderAsPayload(packetId, meta.length); // uncontrained view on build, or implement in buffer after set length
    return meta;
  }

  // as response passes stateMeta
  RV? parseResponse<R extends Payload, RV>(PacketIdRequestResponse<dynamic, R> packetId, PayloadMeta? reqStateMeta) {
    return parsePayloadAs(packetId.responseCaster!, reqStateMeta);
  }
}

// allow buffer to be less than packet length, unlike Struct, Payload, Header
typedef PacketCaster<P extends Packet> = P Function(TypedData typedData);

// non-Struct backed packets, parent constructor, enforce that a sublistView is used
// optionally resolve getters to fields
abstract class PacketBase extends ByteStructBase with Packet {
  PacketBase(super.bytes, [super.offset = 0, super.length]);
  PacketBase.origin(super.bytesBuffer, [super.offset = 0, super.length]) : super.origin();
}

// abstract mixin class PacketCreator {
//   int get lengthMax; // length in bytes
//   Packet cast(TypedData typedData);
//   Packet alloc() => cast(Uint8List(lengthMax));
//   Packet create([Uint8List? typedData, int offset = 0, int? length]) => cast(Uint8List.sublistView((typedData ?? Uint8List(lengthMax)), offset, length));
//   Packet call([Uint8List? typedData, int offset = 0, int? length]) => create(typedData, offset, length);
// }

////////////////////////////////////////////////////////////////////////////////
/// Struct Components Header/Payload
////////////////////////////////////////////////////////////////////////////////

/// [Header] Constructor
typedef HeaderCaster<P extends PacketHeader> = P Function(TypedData typedData);

/// effectively the Packet control block
/// a basic opinionated implementation, union with sync header
/// can be defined on a Struct, fixed length
/// interface only, ffi.Struct cannot mixin
abstract interface class PacketHeader {
  /// each field can be upto 8 bytes
  /// override in struct should optimize, over get via TypedOffset
  int get startFieldValue;
  int get idFieldValue;
  int get lengthFieldValue;
  int get checksumFieldValue;

  set startFieldValue(int value);
  set idFieldValue(int value);
  set lengthFieldValue(int value);
  set checksumFieldValue(int value);

  // /// no type inference when passing `Field` to ByteData
  // /// only valid on completion.
  // int get startFieldValue => startField.fieldValue(_byteData);
  // int get idFieldValue => idField.fieldValue(_byteData);
  // int get lengthFieldValue => lengthField.fieldValue(_byteData);
  // int get checksumFieldValue => checksumField.fieldValue(_byteData);
  // set startFieldValue(int value) => startField.setFieldValue(_byteData, value);
  // set idFieldValue(int value) => idField.setFieldValue(_byteData, value);
  // set lengthFieldValue(int value) => lengthField.setFieldValue(_byteData, value);
  // set checksumFieldValue(int value) => checksumField.setFieldValue(_byteData, value);

  void build(PacketId packetId, Packet? packet); // can be overridden for additional types
}

abstract interface class PacketHeaderSync {
  int get startFieldValue;
  int get idFieldValue;
  set startFieldValue(int value);
  set idFieldValue(int value);
  // int get lengthFieldValue(int value) => throw UnsupportedError('lengthFieldValue not available');
  // int get checksumFieldValue(int value) => throw UnsupportedError('checksumFieldValue not available');
  // set lengthFieldValue(int value) => throw UnsupportedError('lengthFieldValue not available');
  // set checksumFieldValue(int value) => throw UnsupportedError('checksumFieldValue not available');
}

/// [Payload] Constructor - handler per id
/// Struct.create<T>
// typedef PayloadCaster<T extends Payload> = T Function(TypedData typedData);
typedef PayloadCaster<P extends Payload<V>, V> = P Function(TypedData typedData);
// typedef PayloadCasterByValue<V> = Payload<V> Function(TypedData typedData);
// abstract interface class PayloadFactory<T extends Payload> {
//   T call(TypedData typedData);
//   T allocate();
// }

/// extends Struct and Payload
/// Payload need to contain a static cast function
/// factory Child.cast(TypedData target);
/// convert in place, on allocated buffer
/// Alternative
// Codec functions require double buffering, since header and payload is a contiguous list.
// same as cast, build, asTypedData
// Uint8List encodePayload(T input);
// T decodePayload(Uint8List input);
// Passing buffer same as cast then build
// encodeOn(Uint8List buffer, T input);
/// build/parse with a reference to the header, although both are part of a contiguous buffer
/// payload class without direct context of header allows stronger encapsulation
/// if Payload is a struct, then it does not have to declare filler header fields
abstract interface class Payload<V> {
  // V get values;
  PayloadMeta build(V args, [covariant Packet? header]);
  V parse([covariant Packet header, covariant PayloadMeta? stateMeta]);
}

// length state maintained by caller, cannot be included as struct field
class PayloadMeta {
  const PayloadMeta(this.length, [this.other]);
  final int length;
  final Record? other;
}

////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////
/// Packet with `mutable length` , copyBytes, + casters
///
/// pass PacketCaster<P>, this way user does not have to extend PacketBuffer with child type methods
/// alternatively implements Packet require proxy or user create separate class mixin ChildType
/// ideally this could implement packet and uin8list
class PacketBuffer {
  PacketBuffer._(this.packetCaster, this._packetBuffer, this._byteBuffer)
      : _packetView = packetCaster(_byteBuffer.asUint8List(0, 0)),
        _bytesView = _byteBuffer.asUint8List(0, 0);

  PacketBuffer.buffer(PacketCaster packetCaster, Uint8List bytes) : this._(packetCaster, packetCaster(bytes), bytes.buffer);
  PacketBuffer.size(PacketCaster packetCaster, int size) : this.buffer(packetCaster, Uint8List(size));

  // todo user packet interface for accessors
  PacketBuffer(PacketInterface packetInterface, [int? size]) : this.buffer(packetInterface.cast, Uint8List(size ?? packetInterface.lengthMax));

  final ByteBuffer _byteBuffer; // PacketBuffer can directly retain byteBuffer, its own buffer starts at offset 0, methods are provided as relative via Packet,
  final Packet _packetBuffer; // holds full view, max length buffer, with named fields. build functions uncontrained, then sets length

  Uint8List _bytesView; // holds truncated view, mutable length.
  Packet _packetView; // final if casting is not implemented, or packet extends struct

  @protected
  final PacketCaster packetCaster; // inherited class may use for addition buffers

  // resolve views on length update
  // disallow changing pointers directly, caller use length
  int get length => _bytesView.length;
  set length(int value) {
    // runtime assertion is handled by parser
    assert(value <= bytes.buffer.lengthInBytes - bytes.offsetInBytes); // minus offset if view does not start at buffer 0, case of inheritance

    _bytesView = _byteBuffer.asUint8List(0, value); // need Uint8List.view. sublistView will not exceed current length
    _packetView = packetCaster(_bytesView);

    assert(_bytesView.length == _packetView.length);
  }

  void clear() => length = 0;

  Uint8List get bytes => _bytesView;
  Packet get packet => _packetView;

  /// receiving for parse, or socket
  void copyBytes(Uint8List dataIn, [int offset = 0]) {
    length = dataIn.length;
    bytes.setAll(offset, dataIn);
  }

  void addBytes(Uint8List dataIn) {
    final initialLength = length;
    length = initialLength + dataIn.length;
    bytes.setAll(initialLength, dataIn);
  }

  // int get payloadLength => length - packet.payloadIndex;
  // set payloadLength(int value) => (length = packet.payloadHeaderLength + value);

  /// build functions mutate length
  PayloadMeta buildRequest<T extends Payload, TV>(PacketIdRequestResponse<T, dynamic> packetId, TV requestArgs) {
    PayloadMeta meta = _packetBuffer.buildRequest(packetId, requestArgs);
    length = packet.payloadHeaderLength + meta.length; // payloadLength = meta.length;
    return meta;
  }

  void buildSync(PacketId packetId) {
    _packetBuffer.buildHeaderAsSync(packetId);
    length = packet.idHeaderLength;
  }

  /// parse functions redirect, socket call packet directly
  RV? parseResponse<R extends Payload, RV>(PacketIdRequestResponse<dynamic, R> packetId, [PayloadMeta? reqStateMeta]) {
    return packet.parseResponse(packetId, reqStateMeta);
  }

  PacketIdSync? parseSyncId() => packet.parseSyncId();
}

////////////////////////////////////////////////////////////////////////////
/// [PacketId] Types
////////////////////////////////////////////////////////////////////////////
/// build idOf from lists internally
class PacketIdCaster {
  PacketIdCaster(this.syncIds, this.payloadIds)
      : _lookUpMap = Map<int, PacketId>.unmodifiable({
          for (final id in syncIds) id.intId: id,
          for (final id in payloadIds) id.intId: id,
        });

  final List<PacketIdSync> syncIds;
  final List<PacketIdRequestResponse> payloadIds;
  final Map<int, PacketId> _lookUpMap;

  PacketId? call(int intId) => _lookUpMap[intId];
}

abstract interface class PacketId implements Enum {
  const PacketId();
  int get intId;
}

enum PacketIdInternal implements PacketId {
  undefined;

  int get intId => throw UnsupportedError('');
}

// separate type label allow pattern matching
abstract interface class PacketIdSync implements PacketId {
  const PacketIdSync();
}

// Id hold a constructor to create a handler instance to process as packet
// abstract interface class PacketIdPayload<T extends Payload> implements PacketId {
//   T call(TypedData typedData);
// }

/// Id as payload factory
/// paired request response id for simplicity in case of shared id by request and response
/// under define responseId for 1-way e.g <T, void>
///   handlers must be constructors, mutable objects cannot be const for enum
// abstract interface class PacketIdRequestResponse<T extends Payload, R extends Payload> implements PacketId {
abstract interface class PacketIdRequestResponse<T, R> implements PacketId {
  const PacketIdRequestResponse();

  PacketId? get responseId; // null for 1-way or matching response, override for non matching
  // PayloadCaster<T, dynamic>? get requestCaster;
  // PayloadCaster<R, dynamic>? get responseCaster;
  PayloadCaster<Payload<T>, T>? get requestCaster;
  PayloadCaster<Payload<R>, R>? get responseCaster;
}

////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////
@Packed(1)
final class EchoPayload extends Struct implements Payload<(int, int)> {
  @Uint32()
  external int value0;
  @Uint32()
  external int value1;

  factory EchoPayload({int value1 = 0, int value0 = 0}) => Struct.create<EchoPayload>()..build((value1, value0));

  factory EchoPayload.cast(TypedData typedData) => Struct.create<EchoPayload>(typedData); // ensures Struct.create<EchoPayload> is compiled at compile time

  @override
  PayloadMeta build((int, int) args, [Packet? header]) {
    final (newValue0, newValue1) = args;
    value0 = newValue0;
    value1 = newValue1;
    return const PayloadMeta(8);
  }

  @override
  (int, int) parse(Packet? header, void stateMeta) {
    return (value0, value1);
  }
}

enum PacketIdRequestResponseInternal<T extends Payload, R extends Payload> implements PacketIdRequestResponse<T, R> {
  echo(0xFF, requestCaster: EchoPayload.cast, responseCaster: EchoPayload.cast);

  const PacketIdRequestResponseInternal(this.intId, {required this.requestCaster, required this.responseCaster, this.responseId});

  @override
  final int intId;
  @override
  final PacketId? responseId;
  @override
  final PayloadCaster<T> requestCaster;
  @override
  final PayloadCaster<R> responseCaster;
}
