import 'dart:typed_data';
import 'dart:ffi';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../utilities/basic_ext.dart';
import '../bytes/byte_struct.dart';

export '../bytes/byte_struct.dart';

part 'packet_id.dart';
part 'packet_header.dart';

//todo refactor

/// Collective def of Packet format. Descriptor / 'Class variables'
// Abstract factory pattern
// effectively Packet `subtype` encapsulated
// values available without a Packet instance  {
// include handlers for header and payload format
@immutable
abstract interface class PacketFormat<T extends Packet> {
  const PacketFormat();
  // 'Packet' factory / subtype constructor
  TypedDataCaster<T> get caster;
  T cast(TypedData typedData);

  // const refs. 'static' for each packet subtype instance
  // can implement in PacketId for per packet behavior
  int get lengthMax; // length in bytes
  int get lengthMin; // same as idHeaderLength, min before cast check id on parse
  Endian get endian;

  int get headerLength; // defined as length only as header start at offset 0
  int get syncHeaderLength;
  // int get fixedHeaderLength; // an alternate header for fixed size payload as determined by id
  int get startId; // alternatively Uint8List, if id length > 8 bytes

  /// control char ids
  PacketSyncId get ack;
  PacketSyncId get nack;
  PacketSyncId get abort;

  // factory functions
  PacketId? idOf(int intId);
  PacketHeader headerOf(TypedData typedData);
  PacketSyncHeader syncHeaderOf(TypedData typedData);
  // PacketIdCaster({required Iterable<List<PacketId>> idLists, required List<PacketSyncId> syncIds})
  // : _lookUpMap = Map<int, PacketId>.unmodifiable({
  //     for (final idList in idLists)
  //       for (final id in idList) id.intId: id,
  //   });

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
}

/// [Packet] as interface for `immutable view` of `varying view length`.
///
/// Cannot extend Struct directly.
/// ffi.Struct current does not allow length < full struct length, or mixin
/// alternatively, use extension type on TypedData
///
/// Components/Header/Payload may extend Struct for convenience of defining sized fields.
abstract class Packet {
  Packet(TypedData typedData) : packetData = ByteData.sublistView(typedData); // inherited constructor. caller pass back to PacketClass
  // const Packet.view(this.packetData);

  /// Class variables per subtype class, or should this be mixin
  PacketFormat get format;
  // header must be complete in ffi.Struct case
  // can resolve as field in class if compiler does not optimize
  PacketHeader get asHeader => format.headerOf(packetData);
  PacketSyncHeader get asSync => format.syncHeaderOf(packetData);

  // per instance
  // pointer to a buffer, immutable view/length
  // mutable view use PacketBuffer
  final ByteData packetData;

  Uint8List get bytes => Uint8List.sublistView(packetData);

  /// derive from either header or packetInterface
  /// alternatively, define as SizeField key
  int get payloadIndex => format.headerLength;
  int get payloadLengthMax => format.lengthMax - payloadIndex;

  /// immutable, of varying length, by default
  /// mutable with mixin, or PacketBuffer
  /// immutable, always lengthMax, in case of mixin on struct
  int get length => packetData.lengthInBytes;
  int get payloadLength => length - payloadIndex; // only if casting does not throw

  ///
  /// Header/Payload Pointers using defined boundaries
  ///
  // rename bytes
  Uint8List get idHeader => Uint8List.sublistView(packetData, 0, format.lengthMin);
  Uint8List get header => Uint8List.sublistView(packetData, 0, format.headerLength);
  Uint8List get payload => Uint8List.sublistView(packetData, payloadIndex);

  ByteData get headerWords => ByteData.sublistView(header, 0, format.headerLength);
  @visibleForTesting
  Uint8List get headerAvailable => Uint8List.sublistView(packetData, 0, format.headerLength.clamp(0, length));

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
  R? payloadAtOrNull<R extends TypedDataList<int>>([int byteOffset = 0, int? length]) => packetData.arrayOrNullAt<R>(byteOffset + payloadIndex);

  int payloadWordAt<R extends NativeType>(int byteOffset) => payloadWords.wordAt<R>(byteOffset, format.endian);
  // throws if header parser fails, length reports lesser value, while checksum passes
  int? payloadWordAtOrNull<R extends NativeType>(int byteOffset) => payloadWords.wordOrNullAt<R>(byteOffset, format.endian);

  @override
  String toString() => '[start: $startFieldOrNull, id: $idFieldOrNull, length: $lengthFieldOrNull, checksum: $checksumFieldOrNull][${bytes.skip(format.headerLength)}]';
  // String toString() => '${bytes.take(packetClass.headerLength)} ${bytes.skip(packetClass.headerLength)}';

  ///
  /// [Checksum]
  /// overridable for alternate field offsets and algorithms
  ///

  static int sum(Uint8List data) => data.sum;

  int Function(Uint8List data) get checksumAlgorithm => sum;

  int get checksumIndex => format.checksumFieldDef.offset;
  int get checksumSize => format.checksumFieldDef.size;

  /// all bytes excluding checksumField
  /// using length contained in [bytes] view, or length param length
  int checksum([int? length]) {
    assert((() => (length == null) ? this.length == asHeader.lengthField : true)());
    final checksumMask = ((1 << (checksumSize * 8)) - 1);
    final checksumEnd = checksumIndex + checksumSize;

    var checkSum = 0;
    checkSum += checksumAlgorithm(Uint8List.sublistView(packetData, 0, checksumIndex));
    checkSum += checksumAlgorithm(Uint8List.sublistView(packetData, checksumEnd, length ?? this.length));
    return checkSum & checksumMask;
  }

  @visibleForTesting
  int get checksumTest => checksum();

  // todo move to header handler
  //   header context included in 'this'
  //   cannot be implemented in packet header, ffi.Struct cannot mixin,
  // alternatively extension?
  //

  void fillStartField() => asSync.startField = format.startId;

  void buildHeaderAsSync(PacketId packetId) {
    fillStartField();
    asSync.idField = packetId.intId;
  }

  void buildHeaderAsRequest(PacketId requestId, int payloadLength) {
    fillStartField();
    asHeader.idField = requestId.intId;
    asHeader.lengthField = payloadLength + format.headerLength;
    asHeader.checksumField = checksum(payloadLength + format.headerLength);
  }

  void buildHeader(PacketId packetId, int payloadLength) {
    return switch (packetId) {
      PacketSyncId() => buildHeaderAsSync(packetId),
      PacketIdRequest() => buildHeaderAsRequest(packetId, payloadLength),
      PacketId() => throw UnimplementedError(),
    };
  }

  // void buildHeaderAs(PacketHeaderCaster caster, PacketId packetId) => caster(header).build(packetId, this);

  //   move to header parser
  // use shorter type, casting as longer header on smaller bytes will throw. optionally use field offset
  PacketId? get packetId => format.idOf(asSync.idField); // idOf(idFieldPart.fieldValue(headerWords));
  PacketSyncId? parseSyncId() => switch (packetId) {
    PacketSyncId syncId => syncId,
    _ => null,
  };
  int get parsePayloadLength => asHeader.lengthField - format.headerLength; // until casting is available

  /// for valueOrNull from header status
  bool isValidStart(int value) => (value == format.startId);
  bool isValidId(int value) => (format.idOf(value) != null);
  bool isValidLength(int value) => (value == value.clamp(format.headerLength, format.lengthMax)); // where length is total length
  bool isValidChecksum(int value) => (value == checksum());

  // bool get isStartValid => isValidStart(headerAsSyncType.startFieldValue);
  // bool get isIdValid => isValidId(headerAsSyncType.idFieldValue);
  // bool get isLengthValid => isValidLength(headerAsPayloadType.lengthFieldValue);
  // bool get isChecksumValid => isValidChecksum(headerAsPayloadType.checksumFieldValue);

  ///
  /// On partial header, truncated view, header status during parsing
  /// using cast length
  ///
  // header struct cannot cast less than full length
  int? get startFieldOrNull => format.startFieldDef.getInOrNull(packetData);
  int? get idFieldOrNull => format.idFieldDef.getInOrNull(packetData);
  int? get lengthFieldOrNull => format.lengthFieldDef.getInOrNull(packetData);
  int? get checksumFieldOrNull => format.checksumFieldDef.getInOrNull(packetData);

  // null if not yet received
  bool? get isStartFieldValid => startFieldOrNull.ifNonNull(isValidStart);
  bool? get isIdFieldValid => idFieldOrNull.ifNonNull(isValidId);
  // non-sync only
  bool? get isLengthFieldValid => lengthFieldOrNull.ifNonNull(isValidLength);
  bool? get isChecksumFieldValid => checksumFieldOrNull.ifNonNull(isValidChecksum); // assert(length == lengthFieldOrNull), isPacketComplete == true

  /// derived values using field offset + size
  // null if not found or invalid..
  PacketId? get packetIdOrNull => switch (idFieldOrNull) {
    int value => format.idOf(value),
    null => null,
  };

  int? get packetLengthOrNull => switch (packetIdOrNull) {
    PacketSyncId() => format.syncHeaderLength,
    PacketId() => lengthFieldOrNull,
    null => null,
  };

  bool get isPacketComplete => switch (packetLengthOrNull) {
    int value => (length >= value),
    null => false,
  };

  ///
  /// [Payload]
  /// build with Id, pass Header reference
  /// typed with user input values, directly accepting struct would miss deriving meta
  ///
  // full context is PacketId<V, dynamic> packetId, V requestArgs, TypedData buffer

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

///
///
///
/// Packet with `mutable length`, copyBytes + cast view
///
/// pass [PacketCaster] or [PacketFormat]
class PacketBuffer<T extends Packet> extends ByteStructBuffer<T> {
  PacketBuffer(this.packetClass, [int? size]) : super.caster(packetClass.caster, size ?? packetClass.lengthMax);

  final PacketFormat<T> packetClass;
  int get _headerLength => packetClass.headerLength;
  int get _syncHeaderLength => packetClass.syncHeaderLength;
  int get _payloadIndex => packetClass.headerLength;

  Packet get _packetBuffer => bufferAsStruct;
  Packet get viewAsPacket => viewAsStruct;

  // ByteStructBuffer
  // final PacketCaster packetCaster; // inherited class may use for addition buffers
  // final ByteBuffer _byteBuffer; // PacketBuffer can directly retain byteBuffer, its own buffer starts at offset 0, methods are provided as relative via Packet,
  // final Packet _packetBuffer; // holds full view, max length buffer, with named fields. build functions unconstrained, then sets length
  // Uint8List _bytesView; // holds truncated view, mutable length.
  // Packet _packetView; // final if casting is not implemented, or packet extends struct

  int get payloadLength => viewLength - _payloadIndex;
  set payloadLength(int value) => viewLength = _payloadIndex + value;

  /// build functions mutate viewLength
  PayloadMeta buildRequest<V>(PacketIdRequest<V, dynamic> packetId, V requestArgs) {
    PayloadMeta payloadMeta = _packetBuffer.buildRequest(packetId, requestArgs);
    viewLength = _headerLength + payloadMeta.length;
    return payloadMeta;
  }

  /// parse functions redirect, socket call packet directly
  V parseResponse<V>(PacketIdRequest<dynamic, V> packetId, [PayloadMeta? reqStateMeta]) {
    return _packetBuffer.parseResponse(packetId, reqStateMeta); // ffi Struct must use full buffer range.
  }

  void buildSync(PacketId packetId) {
    _packetBuffer.buildHeaderAsSync(packetId);
    viewLength = _syncHeaderLength;
  }

  PacketSyncId? parseSyncId() => _packetBuffer.parseSyncId();

  // /// `full Struct view` using a main struct type, max length buffer, with keyed fields, build functions unconstrained.
  // @protected
  // final T bufferAsStruct;
  // @protected
  // final TypedDataCaster<T> structCaster; // need to retain this?

  // // check bounds with struct class
  // // try partial view
  // T get viewAsStruct => structCaster(viewAsBytes);

  // /// `view as ByteStruct`
  // /// view as `length available` in buffer, maybe a partial or incomplete view
  // /// nullable accessors in effect, length is set in contents
  // S viewAs<S>(TypedDataCaster<S> caster) => caster(viewAsBytes);

  // /// `view as ffi.Struct` must be on full length or Struct.create will throw
  // /// view as `full length`, `including invalid data.`
  // /// a buffer backing larger than all potential calls is expected to be allocated at initialization
  // S? viewBufferAsStruct<S extends Struct>(TypedDataCaster<S> caster) => caster(bufferAsBytes);
}

/// T is [ByteStruct] or [ffi.Struct]
typedef TypedDataCaster<T> = T Function(TypedData typedData);

/// buffer type
/// for partial view
// T as ffi.Struct caster or ByteStruct caster
// wrapper around ffi.Struct or extend ByteStructBase
class ByteStructBuffer<T> extends TypedDataBuffer {
  ByteStructBuffer._(super._bufferView, this.structCaster) : bufferAsStruct = structCaster(_bufferView), super.of();

  // caster for persistent view
  ByteStructBuffer.caster(TypedDataCaster<T> structCaster, int size) : this._(Uint8List(size), structCaster);

  /// `full Struct view` using a main struct type, max length buffer, with keyed fields, build functions unconstrained.
  @protected
  final T bufferAsStruct;
  @protected
  final TypedDataCaster<T> structCaster; // need to retain this?

  // check bounds with struct class
  // try partial view
  T get viewAsStruct => structCaster(viewAsBytes);

  /// `view as ByteStruct`
  /// view as `length available` in buffer, maybe a partial or incomplete view
  /// nullable accessors in effect, length is set in contents
  S viewAs<S>(TypedDataCaster<S> caster) => caster(viewAsBytes);

  /// `view as ffi.Struct` must be on full length or Struct.create will throw
  /// view as `full length`, `including invalid data.`
  /// a buffer backing larger than all potential calls is expected to be allocated at initialization
  S? viewBufferAsStruct<S extends Struct>(TypedDataCaster<S> caster) => caster(bufferAsBytes);

  // build(dynamic values) => throw UnimplementedError();
  // parse(dynamic values) => throw UnimplementedError();
}
