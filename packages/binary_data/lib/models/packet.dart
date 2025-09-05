import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'package:type_ext/basic_ext.dart';

import '../bytes/byte_struct.dart';
export '../bytes/byte_struct.dart';

/// Collective def of Packet format specs. 'Class variables'
// Abstract factory pattern
// effectively Packet `subtype` encapsulated
// values available without a Packet instance, over prototype object
// abstract mixin class PacketClass<T extends Packet> implements ByteStruct <T, ByteField>  {
abstract interface class PacketClass<T extends Packet> {
  // const for each packet instance
  // can implement in PacketId for per packet behavior
  int get lengthMax; // length in bytes
  int get lengthMin; // same as idHeaderLength, min before cast check id on parse
  Endian get endian;

  int get headerLength; // defined as length only as header start at offset 0
  int get syncHeaderLength;
  // int get fixedHeaderLength; // an alternate header for fixed size payload as determined by id
  int get startId; // alternatively Uint8List

  PacketSyncId get ack;
  PacketSyncId get nack;
  PacketSyncId get abort;

  PacketId? idOf(int intId);
  // PacketIdCaster get idClass;

  /// Header Definition
  /// defined position, relative to `packet`.
  /// header fields for buildHeader/parseHeader
  /// required for HeaderParser.
  /// can be derived from header Struct when get offset is available
  ByteField get startFieldDef;
  ByteField get idFieldDef;
  ByteField get lengthFieldDef;
  ByteField get checksumFieldDef;

  List<ByteField> get keys => [startFieldDef, idFieldDef, lengthFieldDef, checksumFieldDef];

  // factory functions
  // child class constructor
  TypedDataCaster<T> get caster;
  T cast(TypedData typedData);

  // not all types must be implemented
  PacketHeader headerOf(TypedData typedData);
  PacketSyncHeader syncHeaderOf(TypedData typedData);

  // R headerAs<R extends PacketHeader>(TypedData typedData);

  // at least one header type must be implemented, with fields able to determine completion
  // TypedDataCaster<PacketHeader> get headerCaster;
  // TypedDataCaster<PacketHeader> get idHeaderCaster; // minimal header to determine id, consistent for all types
  // PacketIdHeader idHeaderOf(TypedData typedData);
  // PacketFixedHeader fixedHeaderOf(TypedData typedData);
  // PacketVariableHeader variableHeaderOf(TypedData typedData);

  // pass to build idOf internally
  // PacketIdCaster get idCaster;
}

/// Packet as interface for mutable view length.
/// as oppose to extending struct directly,
/// Components extend Struct to convince of defining sized. `PacketCaster` retain mutable length
///
/// ffi.Struct current does not allow length < full struct length, or mixin
/// alternatively, use extension type on TypedData
abstract class Packet {
  Packet(TypedData typedData) : packetData = ByteData.sublistView(typedData);

  /// Class variables per subtype class, or should this be mixin
  PacketClass get packetClass;
  // header must be complete in ffi.Struct case
  // can resolve as field in class if compiler does not optimize
  PacketHeader get asHeader => packetClass.headerOf(packetData);
  PacketSyncHeader get asSync => packetClass.syncHeaderOf(packetData);

  // per instance
  // pointer to a buffer, immutable view/length
  // mutable view use PacketBuffer
  final ByteData packetData;

  Uint8List get bytes => Uint8List.sublistView(packetData);

  /// derive from either header or packetInterface
  /// alternatively, define as SizeField key
  int get payloadIndex => packetClass.headerLength;
  int get payloadLengthMax => packetClass.lengthMax - payloadIndex;

  /// immutable, of varying length, by default
  /// mutable with mixin, or PacketBuffer
  /// immutable, always lengthMax, in case of mixin on struct
  int get length => packetData.lengthInBytes;
  int get payloadLength => length - payloadIndex; // only if casting does not throw

  ////////////////////////////////////////////////////////////////////////////////
  /// Header/Payload Pointers using defined boundaries
  ////////////////////////////////////////////////////////////////////////////////
  // rename bytes
  Uint8List get idHeader => Uint8List.sublistView(packetData, 0, packetClass.lengthMin);
  Uint8List get header => Uint8List.sublistView(packetData, 0, packetClass.headerLength);
  Uint8List get payload => Uint8List.sublistView(packetData, payloadIndex);

  // @override
  // String toString();

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  ByteData get headerWords => ByteData.sublistView(header, 0, packetClass.headerLength);
  @visibleForTesting
  Uint8List get headerAvailable => Uint8List.sublistView(packetData, 0, packetClass.headerLength.clamp(0, length));

  /// for building/parsing payload 'as' packet,
  /// not needed when payload is a struct with named fields,
  /// temporarily work around returning Lists

  /// payload as TypedIntList, for list operations
  /// truncated views, end set by packet.length. uses packet element size
  Uint8List get payloadAsList8 => Uint8List.sublistView(packetData, payloadIndex);
  Uint16List get payloadAsList16 => Uint16List.sublistView(packetData, payloadIndex);
  Uint32List get payloadAsList32 => Uint32List.sublistView(packetData, payloadIndex);

  /// payload as "words" of select length, for individual entry operations
  /// payload.buffer == packet.buffer, starts at 0 of back buffer
  ByteData get payloadWords => ByteData.sublistView(packetData, payloadIndex);

  /// using ffi NativeType for signature types only
  /// with range check
  /// under length packet will be reject at parser
  R payloadAt<R extends TypedDataList<int>>([int byteOffset = 0, int? length]) => packetData.arrayAt<R>(byteOffset + payloadIndex, length);
  // List<int> payloadAt<R extends TypedData>(int byteOffset) => payload.asIntListOrEmpty<R>(byteOffset );
  // List<int> payloadAt<R extends TypedDataList<int>>([int byteOffset = 0, int? length]) => packetData.arrayOrEmptyAt<R>(byteOffset + payloadIndex);

  int payloadWordAt<R extends NativeType>(int byteOffset) => payloadWords.wordAt<R>(byteOffset, packetClass.endian);
  // throws if header parser fails, length reports lesser value, while checksum passes
  int? payloadWordAtOrNull<R extends NativeType>(int byteOffset) => payloadWords.wordOrNullAt<R>(byteOffset, packetClass.endian);

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

  int get checksumIndex => packetClass.checksumFieldDef.offset;
  int get checksumSize => packetClass.checksumFieldDef.size;

  /// all bytes excluding checksumField
  /// using length contained in [bytes] view, or length param length
  int checksum([int? length]) {
    assert((() => (length == null) ? this.length == asHeader.lengthField : true).call());
    final checksumMask = ((1 << (checksumSize * 8)) - 1);
    final checksumEnd = checksumIndex + checksumSize;

    var checkSum = 0;
    checkSum += checksumAlgorithm(Uint8List.sublistView(packetData, 0, checksumIndex));
    checkSum += checksumAlgorithm(Uint8List.sublistView(packetData, checksumEnd, length ?? this.length));
    return checkSum & checksumMask;
  }

  @visibleForTesting
  int get checksumTest => checksum();

  ////////////////////////////////////////////////////////////////////////////////
  /// [Header]
  ///   header context included in 'this'
  ///   cannot be implemented in packet header, ffi.Struct cannot mixin,
  /// alternatively extension?
  ////////////////////////////////////////////////////////////////////////////////

  void fillStartField() => asSync.startField = packetClass.startId;

  void buildHeaderAsSync(PacketId packetId) {
    fillStartField();
    asSync.idField = packetId.intId;
  }

  void buildHeaderAsRequest(PacketId requestId, int payloadLength) {
    fillStartField();
    asHeader.idField = requestId.intId;
    asHeader.lengthField = payloadLength + packetClass.headerLength;
    asHeader.checksumField = checksum(payloadLength + packetClass.headerLength);
  }

  void buildHeader(PacketId packetId, int payloadLength) {
    return switch (packetId) {
      PacketSyncId() => buildHeaderAsSync(packetId),
      PacketIdRequest() => buildHeaderAsRequest(packetId, payloadLength),
      PacketId() => throw UnimplementedError(),
    };
  }

  void buildHeaderAs(PacketHeaderCaster caster, PacketId packetId) => caster(header).build(packetId, this);

  ////////////////////////////////////////////////////////////////////////////////
  /// alternatively move to header parser
  /// parse header
  ////////////////////////////////////////////////////////////////////////////////
  // use shorter type, casting as longer header on smaller bytes will throw. optionally use field offset
  PacketId? get packetId => packetClass.idOf(asSync.idField); // idOf(idFieldPart.fieldValue(headerWords));
  PacketSyncId? parseSyncId() => switch (packetId) {
    PacketSyncId syncId => syncId,
    _ => null,
  };
  int get parsePayloadLength => asHeader.lengthField - packetClass.headerLength; // until casting is available

  /// for valueOrNull from header status
  bool isValidStart(int value) => (value == packetClass.startId);
  bool isValidId(int value) => (packetClass.idOf(value) != null);
  bool isValidLength(int value) => (value == value.clamp(packetClass.headerLength, packetClass.lengthMax)); // where length is total length
  bool isValidChecksum(int value) => (value == checksum());

  // bool get isStartValid => isValidStart(headerAsSyncType.startFieldValue);
  // bool get isIdValid => isValidId(headerAsSyncType.idFieldValue);
  // bool get isLengthValid => isValidLength(headerAsPayloadType.lengthFieldValue);
  // bool get isChecksumValid => isValidChecksum(headerAsPayloadType.checksumFieldValue);

  ////////////////////////////////////////////////////////////////////////////////
  /// On partial header, truncated view, header status during parsing
  /// using cast length
  ////////////////////////////////////////////////////////////////////////////////
  // header struct cannot cast less than full length
  int? get startFieldOrNull => packetClass.startFieldDef.getInOrNull(packetData);
  int? get idFieldOrNull => packetClass.idFieldDef.getInOrNull(packetData);
  int? get lengthFieldOrNull => packetClass.lengthFieldDef.getInOrNull(packetData);
  int? get checksumFieldOrNull => packetClass.checksumFieldDef.getInOrNull(packetData);

  // null if not yet received
  bool? get isStartFieldValid => startFieldOrNull.ifNonNull(isValidStart);
  bool? get isIdFieldValid => idFieldOrNull.ifNonNull(isValidId);
  // non-sync only
  bool? get isLengthFieldValid => lengthFieldOrNull.ifNonNull(isValidLength);
  bool? get isChecksumFieldValid => checksumFieldOrNull.ifNonNull(isValidChecksum); // assert(length == lengthFieldOrNull), isPacketComplete == true

  /// derived values using field offset + size
  // null if not found or invalid..
  PacketId? get packetIdOrNull => switch (idFieldOrNull) {
    int value => packetClass.idOf(value),
    null => null,
  };

  int? get packetLengthOrNull => switch (packetIdOrNull) {
    PacketSyncId() => packetClass.syncHeaderLength,
    PacketId() => lengthFieldOrNull,
    null => null,
  };

  bool get isPacketComplete => switch (packetLengthOrNull) {
    int value => (length >= value),
    null => false,
  };

  ////////////////////////////////////////////////////////////////////////////////
  /// [Payload]
  /// build with Id, pass Header reference
  /// typed with user input values, directly accepting struct would miss deriving meta
  ////////////////////////////////////////////////////////////////////////////////
  PayloadMeta buildPayloadAs<V>(PayloadCaster<V> caster, V values) => caster(payload).build(values, this);

  // caster taking boundary can probably make this a bit more efficient
  V parsePayloadAs<V>(PayloadCaster<V> caster, [PayloadMeta? stateMeta]) => caster(payload).parse(this, stateMeta);

  PayloadMeta buildRequest<V>(PacketIdRequest<V, dynamic> packetId, V requestArgs) {
    PayloadMeta meta = buildPayloadAs(packetId.requestCaster!, requestArgs);
    if (meta.length > payloadLengthMax) return const PayloadMeta(0); // should this be assert/error?
    buildHeaderAsRequest(packetId, meta.length); // unconstrained view on build, or implement in buffer after set length
    return meta;
  }

  // as response passes stateMeta
  V parseResponse<V>(PacketIdRequest<dynamic, V> packetId, [PayloadMeta? reqStateMeta]) {
    return parsePayloadAs(packetId.responseCaster!, reqStateMeta);
  }
}

// allow buffer to be less than packet length, unlike Struct, Payload, Header
typedef PacketCaster<P extends Packet> = P Function(TypedData typedData);
// typedef PacketCaster = Packet Function(TypedData typedData);

////////////////////////////////////////////////////////////////////////////////
/// Struct Components Header/Payload
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// [Header]
////////////////////////////////////////////////////////////////////////////////
typedef PacketHeaderCaster = PacketHeader Function(TypedData typedData);
// typedef PacketHeaderSyncCaster = PacketHeaderSync Function(TypedData typedData);
// typedef PacketHeaderCaster<P extends PacketHeader> = P Function(TypedData typedData);

/// Minimal header
/// ControlChar
abstract interface class PacketIdHeader {
  int get startField;
  int get idField;
  set startField(int value);
  set idField(int value);
}

/// effectively the Packet control block
/// a basic opinionated implementation, union with sync header
/// can be defined on a Struct, fixed length
/// interface only, ffi.Struct cannot mixin
/// handle length before cast
abstract interface class PacketHeader implements PacketIdHeader {
  int get startField; // > 1 byte user handle using Word module
  int get idField;
  int get lengthField;
  int get checksumField;

  set startField(int value);
  set idField(int value);
  set lengthField(int value);
  set checksumField(int value);

  void build(PacketId packetId, Packet? packet); // can be overridden for additional types
}

abstract interface class PacketFixedHeader implements PacketIdHeader {
  int get startField;
  int get idField;
  int get checksumField;

  set startField(int value);
  set idField(int value);
  set checksumField(int value);
}

// meta char
abstract interface class PacketSyncHeader implements PacketIdHeader {
  int get startField;
  int get idField;
  set startField(int value);
  set idField(int value);
}

// extension PacketHeaderMethods on PacketHeader {}

////////////////////////////////////////////////////////////////////////////////
/// [Payload<V>]
////////////////////////////////////////////////////////////////////////////////
/// extends Struct and Payload
/// Payload need to contain a static cast function
/// factory Child.cast(TypedData target);
/// convert in place, on allocated buffer
/// build/parse with a reference to the header, although both are part of a contiguous buffer
/// payload class without direct context of header
///   allows stronger encapsulation
///   does not have to declare filler header fields
/// for simplicity, the packet header includes all meta parameters, parsing a payload does not need stateMeta
//  Alternative
// Codec functions would double buffer with return Uint8List
// same as cast, build, asTypedData
// Uint8List encodePayload(T input);
// T decodePayload(Uint8List input);

abstract interface class Payload<V> {
  PayloadMeta build(V values, covariant Packet header);
  V parse(covariant Packet header, covariant PayloadMeta? stateMeta);
  // parseMeta(Packet header)
}

// abstract interface class PayloadFixed<V> {
//   V get values;
//   set values(V values);
// }

/// [Payload] Constructor - handler per id
/// Struct.create<T>
typedef PayloadCaster<V> = Payload<V> Function(TypedData typedData);

/// any additional state not included in the header
// length state maintained by caller. cannot be included as struct field, that would be a part of the payload data
class PayloadMeta {
  const PayloadMeta(this.length, [this.other]);
  final int length;
  final Record? other;
}

////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////
/// Packet with `mutable length`, copyBytes + cast view
///
/// pass [PacketCaster] or [PacketClass]
class PacketBuffer<T extends Packet> extends ByteStructBuffer<T> {
  PacketBuffer(this.packetClass, [int? size]) : super.caster(packetClass.caster, size ?? packetClass.lengthMax);

  final PacketClass<T> packetClass;
  int get headerLength => packetClass.headerLength;
  int get syncHeaderLength => packetClass.syncHeaderLength;
  int get payloadIndex => packetClass.headerLength;

  Packet get _packetBuffer => bufferAsStruct;
  Packet get viewAsPacket => viewAsStruct;

  // ByteStructBuffer
  // final PacketCaster packetCaster; // inherited class may use for addition buffers
  // final ByteBuffer _byteBuffer; // PacketBuffer can directly retain byteBuffer, its own buffer starts at offset 0, methods are provided as relative via Packet,
  // final Packet _packetBuffer; // holds full view, max length buffer, with named fields. build functions unconstrained, then sets length
  // Uint8List _bytesView; // holds truncated view, mutable length.
  // Packet _packetView; // final if casting is not implemented, or packet extends struct

  int get payloadLength => viewLength - payloadIndex;
  set payloadLength(int value) => viewLength = payloadIndex + value;

  /// build functions mutate viewLength
  PayloadMeta buildRequest<V>(PacketIdRequest<V, dynamic> packetId, V requestArgs) {
    PayloadMeta payloadMeta = _packetBuffer.buildRequest(packetId, requestArgs);
    viewLength = headerLength + payloadMeta.length;
    return payloadMeta;
  }

  /// parse functions redirect, socket call packet directly
  V parseResponse<V>(PacketIdRequest<dynamic, V> packetId, [PayloadMeta? reqStateMeta]) {
    return _packetBuffer.parseResponse(packetId, reqStateMeta); // ffi Struct must use full buffer range.
  }

  void buildSync(PacketId packetId) {
    _packetBuffer.buildHeaderAsSync(packetId);
    viewLength = syncHeaderLength;
  }

  PacketSyncId? parseSyncId() => _packetBuffer.parseSyncId();
}

////////////////////////////////////////////////////////////////////////////
/// [PacketId] Types
////////////////////////////////////////////////////////////////////////////
/// build idOf from lists internally
/// PacketIdFactory
class PacketIdCaster {
  PacketIdCaster({required Iterable<List<PacketId>> idLists, required List<PacketSyncId> syncIds})
    : _lookUpMap = Map<int, PacketId>.unmodifiable({
        for (final idList in idLists)
          for (final id in idList) id.intId: id,
      });

  final Map<int, PacketId> _lookUpMap;

  PacketId? call(int intId) => _lookUpMap[intId];

  // if expand to PacketIdClass
  // final List<PacketIdSync> syncIds = [];
  // PacketIdSync get ack;
  // PacketIdSync get nack;
  // PacketIdSync get abort;
}

// separate type label allow pattern matching
// the base type can be sealed
abstract interface class PacketId implements Enum {
  int get intId;
}

abstract interface class PacketSyncId implements PacketId {}

// // Id hold a constructor to create a handler instance to process as packet
abstract interface class PacketPayloadId<V> implements PacketId {
  PayloadCaster<V> get payloadCaster;
}

// abstract interface class PacketFixedId<V> implements PacketPayloadId<V> {
//   int get length;
// }

// abstract interface class PacketVariableId<V> implements PacketPayloadId<V> {
//   // int get lengthMax;
//   // int lengthOf(V values);
// }

/// Id as payload factory
/// A `Request` matched with a `Response`
/// paired request response id for simplicity in case of shared id by request and response
/// can under define responseId for 1-way
/// handlers as constructors, const for enum
abstract interface class PacketIdRequest<T, R> implements PacketId {
  PacketId? get responseId; // null for 1-way or matching response, override for non matching
  PayloadCaster<T>? get requestCaster;
  PayloadCaster<R>? get responseCaster;
}

////////////////////////////////////////////////////////////////////////////
/// Example
////////////////////////////////////////////////////////////////////////////
// enum PacketIdInternal implements PacketId {
//   undefined;

//   int get intId => throw UnsupportedError('');
// }

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
  (int, int) parse([Packet? header, void stateMeta]) {
    return (value0, value1);
  }
}

enum PacketIdRequestResponseInternal<T, R> implements PacketIdRequest<T, R> {
  echo(0xFF, requestCaster: EchoPayload.cast, responseCaster: EchoPayload.cast);

  const PacketIdRequestResponseInternal(this.intId, {required this.requestCaster, required this.responseCaster, this.responseId});

  @override
  final int intId;
  @override
  final PacketId? responseId;
  @override
  final PayloadCaster<T>? requestCaster;
  @override
  final PayloadCaster<R>? responseCaster;
}
