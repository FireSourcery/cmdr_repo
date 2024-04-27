import 'dart:ffi'; 
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '/src/byte_struct/byte_struct.dart';
import 'packet_handlers.dart';

export '/src/byte_struct/byte_struct.dart';


typedef PacketConstructor<P extends Packet> = P Function();

/// collective def of Packet format specs
/// Builder Base and prototype, fields view over bytes list
/// use abstract class over on generic, there should not be indefinite number of types
// abstract class Packet extends ByteStruct {
abstract class Packet {
  Packet();
  Packet._buffer(int length) : _packet = Uint8List(length);
  // factory Packet.castWith(PacketConstructor typedPacket, Uint8List bytes) => typedPacket().cast(bytes); // this way only constructor invokes child constructor

  ////////////////////////////////////////////////////////////////////////////////
  /// Specs
  ////////////////////////////////////////////////////////////////////////////////
  // const for each instance, alternatively use config object
  // implement in PacketId for per packet behavior
  // length in bytes
  @protected
  int get configHeaderLength; // Payload start, determines packet type
  @protected
  int get configLengthMax;
  @protected
  int get configStartField;
  @protected
  Endian get configEndian;

  //config get ack nack abort

  /// defined position, relative to `packet`.
  /// header fields for buildHeader/parseHeader
  TypedOffset get startField;
  TypedOffset get idField;
  TypedOffset get lengthField;
  TypedOffset get checksumField;

  PacketId? idOf(int intId);

  /// no type inference when passing `Field` to ByteData
  /// protected as they are only valid on completion.
  @protected
  int get startFieldValue => startField.fieldValue(byteData);
  @protected
  int get idFieldValue => idField.fieldValue(byteData);
  @protected
  int get lengthFieldValue => lengthField.fieldValue(byteData);
  @protected
  int get checksumFieldValue => checksumField.fieldValue(byteData);

  @protected
  set startFieldValue(int value) => startField.setFieldValue(byteData, value);
  @protected
  set idFieldValue(int value) => idField.setFieldValue(byteData, value);
  @protected
  set lengthFieldValue(int value) => lengthField.setFieldValue(byteData, value);
  @protected
  set checksumFieldValue(int value) => checksumField.setFieldValue(byteData, value);

  int? get startFieldOrNull => startField.fieldValueOrNull(byteData);
  int? get idFieldOrNull => idField.fieldValueOrNull(byteData);
  int? get lengthFieldOrNull => lengthField.fieldValueOrNull(byteData);
  int? get checksumFieldOrNull => checksumField.fieldValueOrNull(byteData);

  PacketId get packetId => idOf(idFieldValue) ?? PacketIdInternal.undefined;
  PacketId? get packetIdOrNull => (idFieldOrNull != null) ? idOf(idFieldOrNull!) : null;

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  @protected
  late Uint8List _packet; // pointer to a buffer // view is mutable, byteBuffer is fixed
  ByteData get byteData => ByteData.sublistView(_packet);
  Uint8List get bytes => _packet;
  int get length => _packet.length;
  bool get isEmpty => _packet.isEmpty;

  ////////////////////////////////////////////////////////////////////////////////
  /// buffer functions
  ////////////////////////////////////////////////////////////////////////////////
  // buffer use only
  // alteratively use interface for create function
  Packet allocate([int? length]) => (this.._packet = Uint8List(length?.clamp(length, configLengthMax) ?? configLengthMax));

  // update view length via new view
  // sets packet.length (via new view of fixed length) by totalLength
  // need Uint8List.`view` on buffer to exceed packet view length. sublistView will no exceed current length
  // caller handlers error checking
  @protected
  set length(int totalLength) => _packet = Uint8List.view(_packet.buffer, _packet.offsetInBytes, totalLength);
  @protected
  set payloadLength(int payloadLength) => (length = configHeaderLength + payloadLength); // sets packet.length by payloadLength, used by build
  @protected
  set bytes(Uint8List dataIn) => _packet.setAll(0, dataIn);
  //todo move to buffer
  void copyBytes(Uint8List dataIn) {
    // minus offset if view does not start at buffer 0
    assert(dataIn.length <= _packet.buffer.lengthInBytes - _packet.offsetInBytes);
    length = dataIn.length;
    bytes = dataIn;
  }

  void clear() => length = 0;

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  Packet castBytes(Uint8List bytes) => (this.._packet = bytes);
  Packet castTypedData(TypedData data) => (this.._packet = Uint8List.sublistView(data));
  Packet castPacket(Packet data) => (this.._packet = Uint8List.sublistView(data._packet));
  Packet cast<S>(S data) {
    _packet = switch (S) {
      const (Uint8List) => data,
      const (TypedData) => Uint8List.sublistView(data as TypedData),
      const (Packet) => Uint8List.sublistView((data as Packet)._packet),
      _ => throw UnsupportedError('$S'),
    } as Uint8List;
    return this;
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Header Bytes
  ////////////////////////////////////////////////////////////////////////////////
  @protected
  Uint8List get header => Uint8List.sublistView(_packet, 0, configHeaderLength);
  @protected
  ByteData get headerWords => ByteData.sublistView(_packet, 0, configHeaderLength);

  Uint8List get headerAvailable => Uint8List.sublistView(_packet, 0, configHeaderLength.clamp(0, length));
  Uint8List? get headerOrNull => (length >= configHeaderLength) ? header : null;

  // Uint8List get syncHeader => Uint8List.sublistView(_packet, 0, id.end);

  ////////////////////////////////////////////////////////////////////////////////
  /// Payload Bytes
  ////////////////////////////////////////////////////////////////////////////////
  int get payloadIndex => configHeaderLength;
  int get payloadLengthMax => configLengthMax - configHeaderLength;

  /// payload as TypedIntList, for list operations
  /// truncated views, end set by packet.length. uses packet element size
  Uint8List get payload => Uint8List.sublistView(_packet, payloadIndex);
  Uint8List get payloadAsList8 => Uint8List.sublistView(_packet, payloadIndex);
  Uint16List get payloadAsList16 => Uint16List.sublistView(_packet, payloadIndex);
  Uint32List get payloadAsList32 => Uint32List.sublistView(_packet, payloadIndex);

  /// payload as "words" of select length, for individual entry operations
  /// payload.buffer == packet.buffer, starts at 0 of back buffer
  ByteData get payloadWords => ByteData.sublistView(_packet, payloadIndex);

  int get payloadLength => _packet.length - payloadIndex; // accounted for in payloadView, payload.length

  // set payload(Uint8List dataIn) => payload.setAll(0, dataIn);

  /// using ffi NativeType for signature types only
  /// with range check
  List<int> payloadAt<R extends TypedData>(int byteOffset) => payload.sublistViewOrEmpty<R>(byteOffset);
  int payloadWordAt<R extends NativeType>(int byteOffset) => payloadWords.wordAt<R>(byteOffset, configEndian); // throws if header parser fails, length reports lesser value, while checksum passes
  int? payloadWordAtOrNull<R extends NativeType>(int byteOffset) => payloadWords.wordAtOrNull<R>(byteOffset, configEndian);

  ////////////////////////////////////////////////////////////////////////////////
  /// Checksum
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

  static int sum(Uint8List u8list) => u8list.sum;

  int Function(Uint8List u8list) get checksumAlgorithm => sum;

  // all bytes excluding checksumField
  int checksum() {
    final int checksumMask = ((1 << checksumField.size * 8) - 1);
    var checkSum = 0;
    checkSum += checksumAlgorithm(Uint8List.sublistView(_packet, 0, checksumField.offset));
    checkSum += checksumAlgorithm(Uint8List.sublistView(_packet, checksumField.end));
    return checkSum & checksumMask;
  }

  // @visibleForTesting
  // int get checksumTest => checksum();

  ////////////////////////////////////////////////////////////////////////////////
  /// Components
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  /// Header
  ////////////////////////////////////////////////////////////////////////////////
  // @protected
  // HeaderHandler castHeader(Packet source) {
  //   assert(this is HeaderHandler);
  //   packet = source.bytes;
  //   return this as HeaderHandler;
  // }

  // todo allocate as header handler
  // header handler cannot be shared async,
  // HeaderStatus? parseHeaderWith(HeaderHandler handler) => handler.castHeader(this).parseHeader();

  // void buildHeaderWith(HeaderHandler handler, PacketId packetId, [int? requestLength]) {
  //   handler.castHeader(this).buildHeader(packetId, requestLength);
  //   length = handler.length;
  // }

  void fillStartField() => startFieldValue = configStartField;

  void buildIdHeader(PacketId packetId) {
    fillStartField();
    idFieldValue = packetId.asInt;
    length = idField.end;
  }

  void buildPayloadHeader(PacketId requestId, [int? requestLength]) {
    fillStartField();
    idFieldValue = requestId.asInt;
    lengthFieldValue = requestLength ?? length;
    checksumFieldValue = checksum();
  }

  void buildHeader(PacketId packetId, {int? lengthField, bool buildChecksum = true}) {
    fillStartField();
    idFieldValue = packetId.asInt;
    if (lengthField != null) lengthFieldValue = lengthField;
    if (buildChecksum) checksumFieldValue = checksum();
  }

  M? parseResponseMeta<T, R, M>(PacketTypeId<T, R> id, [dynamic requestStatus]) {
    // return  handler.castPayload<R>(this).parsePayload(reqMeta);
    return null;
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Payload
  ////////////////////////////////////////////////////////////////////////////////
  bool buildPayloadLength(int length) {
    if (length > payloadLengthMax) return false;
    payloadLength = length;
    return true;
  }
  // packet handler override
  // M? buildPayload<T, M>(T? args);
  // R? parsePayload<R, M>([M? status]);

  // cast as PayloadHandler
  @protected
  PayloadHandler<T> castPayload<T>(Packet source) {
    assert(this is PayloadHandler<T>);
    return (this.._packet = source.bytes) as PayloadHandler<T>;
  }

  // M? buildPayloadAs<T, M>(PacketTypeId packetId, T? args);
  // R? parsePayloadAs<R, M>(PacketTypeId packetId, [M? status]);

  M buildPayloadAs<T, M>(PayloadHandler<T> handler, T args) {
    final M reqMeta = handler.castPayload<T>(this).buildPayload(args);
    length = handler.length; // length stored in cast packet
    return reqMeta;
  }

  R parsePayloadAs<R, M>(PayloadHandler<R> handler, [M? reqMeta]) {
    return handler.castPayload<R>(this).parsePayload(reqMeta);
  }

  /// Request Response Type
  // caller ensure id defines handles
  dynamic buildRequestPayload<T, R>(PacketTypeId<T, R> id, T args) {
    return buildPayloadAs<T, dynamic>(id.requestPayload!(), args);
  }

  R parseResponsePayload<T, R>(PacketTypeId<T, R> id, [dynamic requestStatus]) {
    return parsePayloadAs<R, dynamic>(id.responsePayload!(), requestStatus);
  }

// T? parseRequestPayload(Packet packet) => requestPayload?.call().castPayload(packet).parsePayload();
// dynamic buildResponsePayload(Packet packet, R args) => responsePayload?.call().castPayload(packet).buildPayload(args);
}

// Abstract factory pattern
// hold static constructors
abstract class PacketInterface {
  // @protected
  // int get configLengthMax;

  // allocates a new pointer only
  Packet create(); // constructor of child packet class
  Packet newView(Uint8List dataIn) => create().cast(dataIn);
  Packet newBuffer([int? length]) => create().allocate(length);

  // id factory
  // PacketId idOf(int intId);
  Map<int, PacketId> get lookUpMap; // enforce 1:1 into to id map
  PacketId? idOf(int intId) => lookUpMap[intId];

  // PacketSyncId? syncIdOf(PacketSyncIdInternal intId);

  // PacketSyncId get ack;
  // PacketSyncId get nack;
  // PacketSyncId get abort;
}

// exposes set bytes
// class PacketBuffer extends Packet {
//   PacketBuffer(super.maxLength) : super._buffer();

//   //  Packet allocate([int? length]) => (this.._packet = Uint8List(length?.clamp(length, configLengthMax) ?? configLengthMax));

//   // void copyBytes(Uint8List dataIn) {
//   //   if (dataIn.length < _packet.buffer.lengthInBytes - _packet.offsetInBytes) length = dataIn.length; // minus offset if view does not start at buffer 0
//   //   bytes = dataIn;
//   // }

//   @override
//   int get configLengthMax => throw UnimplementedError();
//   @override
//   Endian get configEndian => throw UnimplementedError();
//   @override
//   int get configHeaderLength => throw UnimplementedError();
//   @override
//   int get configStartField => throw UnimplementedError();

//   @override
//   TypedOffset<NativeType> get checksumField => throw UnimplementedError();
//   @override
//   TypedOffset<NativeType> get idField => throw UnimplementedError();
//   @override
//   TypedOffset<NativeType> get lengthField => throw UnimplementedError();
//   @override
//   TypedOffset<NativeType> get startField => throw UnimplementedError();
// }

// Id either hold packet handler function - requires passing packet
// or hold a constructor to create a handler instance to process as packet
abstract interface class PacketId implements Enum {
  const PacketId();
  int get asInt; // asIdField
}

enum PacketIdInternal implements PacketId {
  undefined;

  int get asInt => throw UnsupportedError('');
}

// type label allow pattern matching
abstract interface class PacketSyncId implements PacketId {
  const PacketSyncId();
}

enum PacketSyncIdInternal implements PacketSyncId {
  ack,
  nack,
  abort;

  int get asInt => throw UnsupportedError('');
}

// abstract interface class PacketTypeId<T> implements PacketId { }
// abstract interface class ProtocolRequestResponseId<T, R> {

/// Id holds generic type parameters
/// paired id, can under define responseId for 1-way
/// enhanced enum
/// T as requestPayload
/// R as responsePayload
/// 1 or both if id shared by request and response
abstract interface class PacketTypeId<T, R> implements PacketId {
  const PacketTypeId();

  PacketTypeId? get responseId; // null for 1-way or matching response, override for non matching

  // payload handlers per id, handle as packet
  // Packet Id must be const,
  //  store a constructor which create a mappable pointer
  //  alternatively a const instance with pre allocated buffer
  PayloadHandlerConstructor<T>? get requestPayload;
  PayloadHandlerConstructor<R>? get responsePayload;

  // Codec functions require double buffering, since header and payload is a contiguous list.
  // Uint8List encodePayload(T input);
  // T decodePayload(Uint8List input);
}
