// ignore_for_file: constant_identifier_names

import 'base/packet.dart';
import 'base/packet_handlers.dart';

class MotPacket extends Packet {
  MotPacket();

  @override
  final int configStartField = 0xA5;
  @override
  final int configLengthMax = 40;
  @override
  final int configHeaderLength = 8;
  @override
  final Endian configEndian = Endian.little;

  ////////////////////////////////////////////////////////////////////////////////
  /// Header
  /// `[Start, Id, Checksum[2], Length, Flex[3]]`
  ///  [PayLoad][32]
  ////////////////////////////////////////////////////////////////////////////////
  @override
  final TypedOffset<Uint8> startField = const TypedOffset<Uint8>(0);
  @override
  final TypedOffset<Uint8> idField = const TypedOffset<Uint8>(1);
  @override
  final TypedOffset<Uint16> checksumField = const TypedOffset<Uint16>(2);
  @override
  final TypedOffset<Uint8> lengthField = const TypedOffset<Uint8>(4);

  @override
  MotPacketId? idOf(int intId) => MotPacketId.of(intId);
  // Uint8List get flexField => Uint8List.view(packet, 4, 4);

  int get flex0FieldValue => bytes[5];
  int get flex1FieldValue => bytes[6];
  int get flex2FieldValue => bytes[7];

  set flex0FieldValue(int value) => bytes[5] = value;
  set flex1FieldValue(int value) => bytes[6] = value;
  set flex2FieldValue(int value) => bytes[7] = value;

  int get flexUpper16FieldValue => headerWords.getUint16(6, configEndian);
  set flexUpper16FieldValue(int value) => headerWords.setUint16(6, value, configEndian);
}

class MotPacketHeaderHandler extends MotPacket with HeaderHandler implements HeaderHandler {
  // @override
  // PacketId? idOf(int intId) => MotPacketId.of(intId);
  @override
  final MotPacketSyncId ack = MotPacketSyncId.MOT_PACKET_SYNC_ACK;
  @override
  final MotPacketSyncId nack = MotPacketSyncId.MOT_PACKET_SYNC_NACK;
  @override
  final MotPacketSyncId abort = MotPacketSyncId.MOT_PACKET_SYNC_ABORT;
}

sealed class MotPacketId implements PacketId {
  static MotPacketId? of(int intId) => _lookUpMap[intId];

  static final Map<int, MotPacketId> _lookUpMap = Map<int, MotPacketId>.unmodifiable({
    for (final id in MotPacketSyncId.values) id.intId: id,
    for (final id in MotPacketPayloadId.values) id.intId: id,
  });
}

enum MotPacketSyncId implements PacketSyncId, MotPacketId {
  MOT_PACKET_PING(0xA0),
  // MOT_PACKET_PING_RESP(0xA1),
  MOT_PACKET_SYNC_ACK(0xA2),
  MOT_PACKET_SYNC_NACK(0xA3),
  MOT_PACKET_SYNC_ABORT(0xA4),
  // MOT_PACKET_FEED_WATCHDOG(0xA6),
  MOT_PACKET_ID_RESERVED_255(0xFF),
  ;

  const MotPacketSyncId(this.intId);

  final int intId;
  @override
  int get asInt => intId;
}

typedef VersionResponsePayload = ({int protocol, int library, int firmware, int board});
typedef VarReadRequestPayload = Iterable<int>;
typedef VarReadResponsePayload = List<int>; // values
typedef VarWriteRequestPayload = Iterable<(int id, int value)>;
typedef VarWriteResponsePayload = List<int>; // statuses

typedef DataModeRequestPayload = (int address, int size, int flags);
typedef ReadOnceRequestPayload = (int address, int size);
typedef ReadOnceResponsePayload = (int, Uint8List);
typedef WriteOnceRequestPayload = (int address, int size, Uint8List data);
typedef WriteOnceResponsePayload = int;

enum MotPacketPayloadId<T, R> implements PacketTypeId<T, R>, MotPacketId {
  /* Fixed Length */
  MOT_PACKET_STOP_ALL<void, int>(0x00, requestPayload: StopRequest.new, responsePayload: StopResponse.new),
  MOT_PACKET_VERSION<void, VersionResponsePayload>(0x01, requestPayload: VersionRequest.new, responsePayload: VersionResponse.new),
  // MOT_PACKET_REBOOT<void, int>(
  //   0xC0,
  //   requestPayload: VarReadRequest.new,
  //   responsePayload: VarReadResponse.new,
  // ),
  MOT_PACKET_CALL<(int id, int arg), int>(0xCC, requestPayload: CallRequest.new, responsePayload: CallResponse.new),
  // MOT_PACKET_CALL_ADDRESS(0xCA),
  // MOT_PACKET_FIXED_VAR_READ(0xB1),
  // MOT_PACKET_FIXED_VAR_WRITE(0xB2),
  /* Configurable Length */
  MOT_PACKET_VAR_READ<VarReadRequestPayload, VarReadResponsePayload>(0xB3, requestPayload: VarReadRequest.new, responsePayload: VarReadResponse.new),
  MOT_PACKET_VAR_WRITE<VarWriteRequestPayload, VarWriteResponsePayload>(0xB4, requestPayload: VarWriteRequest.new, responsePayload: VarWriteResponse.new),
  /* Read/Write by Address */
  // MOT_PACKET_MEM_READ(0xD1),
  // MOT_PACKET_MEM_WRITE(0xD2),
  /* Stateful Read/Write */
  MOT_PACKET_DATA_MODE_READ<DataModeRequestPayload, int>(0xDA, requestPayload: DataModeInitRequest.new, responsePayload: DataModeInitResponse.new),
  MOT_PACKET_DATA_MODE_WRITE<DataModeRequestPayload, int>(0xDB, requestPayload: DataModeInitRequest.new, responsePayload: DataModeInitResponse.new),
  MOT_PACKET_DATA_MODE_DATA<Uint8List, Uint8List>(0xDD, requestPayload: DataModeData.new, responsePayload: DataModeData.new),
  // MOT_PACKET_DATA_MODE_ABORT = MOT_PACKET_SYNC_ABORT,
  MOT_PACKET_READ_ONCE<ReadOnceRequestPayload, ReadOnceResponsePayload>(0xF1, requestPayload: OnceReadRequest.new, responsePayload: OnceReadResponse.new),
  MOT_PACKET_WRITE_ONCE<WriteOnceRequestPayload, int>(0xF2, requestPayload: OnceWriteRequest.new, responsePayload: OnceWriteResponse.new),
  /* Extended Id Modes */
  // MOT_PACKET_EXT_CMD (0xE1),             /* ExtId Batch - Predefined Sequences */
  MOT_PACKET_ID_RESERVED_255(0xFF),
  ;

  const MotPacketPayloadId(this.intId, {this.requestPayload, this.responsePayload, this.responseId});

  // static final Map<int, MotPacketId> _lookUpMap = Map<int, MotPacketId>.unmodifiable({for (final id in MotPacketId.values) id.intId: id});
  // factory MotPacketId.of(int intId) => (_lookUpMap[intId] ?? MotPacketId.MOT_PACKET_ID_RESERVED_255) as MotPacketId<T, R>;

  final int intId;
  @override
  int get asInt => intId;

  @override
  final MotPacketPayloadId? responseId;
  @override
  final PayloadHandlerConstructor<T>? requestPayload;
  @override
  final PayloadHandlerConstructor<R>? responsePayload;

  @override
  String toString() => name;
}

////////////////////////////////////////////////////////////////////////////////
/// Read Vars
/// Req     [Length, Resv, IdSum] /  [MotVarIds][16]
/// Resp    [Length, Resv, IdSum] /  [Value16][16]
////////////////////////////////////////////////////////////////////////////////
class VarReadRequest extends MotPacket implements PayloadHandler<VarReadRequestPayload> {
  VarReadRequest();

  @override
  (int idChecksum, int flags) buildPayload(VarReadRequestPayload ids) {
    if (!buildPayloadLength(ids.length * 2)) return (0, 0);

    const offset = 0;
    var idSum = 0;
    for (final (index, id) in ids.indexed) {
      payloadAsList16[offset + index] = id;
      idSum += id;
    }
    flexUpper16FieldValue = idSum;
    return (idSum, 0);
  }

  @override
  VarReadRequestPayload parsePayload([status]) => throw UnimplementedError();
}

class VarReadResponse extends MotPacket implements PayloadHandler<VarReadResponsePayload> {
  VarReadResponse();

  @override
  VarReadResponsePayload parsePayload([dynamic requestStatus]) {
    // final (int idChecksum, int flags)   = requestStatus;
    // final (idChecksum, respCode) = parseVarReadMeta();
    // return ((requestStatus == null) || (requestStatus.$1 == flexUpper16Field)) ? (0, parseVarReadValues()) : (null, null);
    return payloadAt<Uint16List>(0);
  }

  // (int? idChecksum, int? respCode) parseVarReadMeta() => (flexUpper16Field,  );

  @override
  dynamic buildPayload(VarReadResponsePayload args) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Write Vars
/// Req     [IdChecksum, Flags16]   [MotVarIds, Value16][8]
/// Resp    [IdChecksum, Status16]  [VarStatus8][8]
////////////////////////////////////////////////////////////////////////////////
class VarWriteRequest extends MotPacket implements PayloadHandler<VarWriteRequestPayload> {
  VarWriteRequest();

  @override
  (int idChecksum, int flags) buildPayload(VarWriteRequestPayload idValues) {
    if (!buildPayloadLength(idValues.length * (2 + 2))) return (0, 0);

    const offset = 0;
    var idSum = 0;
    for (final (index, (id, value)) in idValues.indexed) {
      payloadAsList16[offset + index * 2] = id; // 0,2,4..
      payloadAsList16[offset + index * 2 + 1] = value; // 1,3,5..
      idSum += id;
    }

    flexUpper16FieldValue = idSum;
    return (idSum, 0);
  }

  // (int idChecksum, int flags) buildMeta(Iterable<(int id, int value)> idValues) {
  //   final length = idValues.length * (2 + 2);
  //   const offset = 0;
  //   var idSum = 0;
  //   for (final (index, (id, value)) in idValues.indexed) {
  //     idSum += id;
  //   }
  //   flexUpper16Field = idSum;
  //   return (idSum, 0);
  // }

  @override
  VarWriteRequestPayload parsePayload([dynamic status]) => throw UnimplementedError();
}

class VarWriteResponse extends MotPacket implements PayloadHandler<VarWriteResponsePayload> {
  VarWriteResponse();

  @override
  VarWriteResponsePayload parsePayload([dynamic requestStatus]) {
    // final (idChecksum, respCode) = parseVarWriteMeta();
    // return ((requestStatus == null) || (requestStatus.$1 == idChecksum)) ? (0, parseVarWriteStatuses()) : (null, null);
    return (payloadAt<Uint8List>(0));
  }

  // (int? idChecksum, int? respCode) parseMeta() => (payloadWordAt<Uint16>(0), payloadWordAt<Uint16>(2));

  @override
  dynamic buildPayload(VarWriteResponsePayload args) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Stop
////////////////////////////////////////////////////////////////////////////////
class StopRequest extends MotPacket implements PayloadHandler<void> {
  @override
  void buildPayload(void args) => payloadLength = 0;

  @override
  void parsePayload([void status]) => throw UnimplementedError();
}

class StopResponse extends MotPacket implements PayloadHandler<int> {
  @override
  parsePayload([void status]) => payloadWordAt<Uint16>(0);

  @override
  void buildPayload(int? args) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Version
/// Request:
/// Response: [Ver_LSB, Ver1, Ver2, Ver_MSB] x4
////////////////////////////////////////////////////////////////////////////////
class VersionRequest extends MotPacket implements PayloadHandler<void> {
  @override
  void buildPayload(void args) => payloadLength = 0;

  @override
  void parsePayload([void status]) => throw UnimplementedError();
}

class VersionResponse extends MotPacket implements PayloadHandler<VersionResponsePayload> {
  @override
  VersionResponsePayload parsePayload([void status]) => (board: payloadWordAt<Uint32>(0), firmware: payloadWordAt<Uint32>(4), library: payloadWordAt<Uint32>(8), protocol: payloadWordAt<Uint32>(12));

  @override
  void buildPayload(args) => throw UnimplementedError();

  // List<int>? parseVersionAsList() => payloadAt<Uint32List>(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Call
////////////////////////////////////////////////////////////////////////////////
class CallRequest extends MotPacket implements PayloadHandler<(int id, int arg)> {
  @override
  void buildPayload(args) {
    payloadLength = 8;
    payloadAsList32[0] = args.$1;
    payloadAsList32[1] = args.$2;
  }

  @override
  parsePayload([void status]) => throw UnimplementedError();
}

class CallResponse extends MotPacket implements PayloadHandler<int> {
  @override
  parsePayload([void status]) {
    // payloadWordAt<Uint32>(0) == callId ? match id
    return payloadWordAt<Uint16>(4);
  }

  @override
  void buildPayload(args) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// MOT_PACKET_DATA_MODE_WRITE
/// MOT_PACKET_DATA_MODE_READ
////////////////////////////////////////////////////////////////////////////////
class DataModeInitRequest extends MotPacket implements PayloadHandler<DataModeRequestPayload> {
  @override
  void buildPayload(args) {
    payloadLength = 12;
    payloadAsList32[0] = args.$1;
    payloadAsList32[1] = args.$2;
    payloadAsList32[2] = args.$3;
  }

  @override
  parsePayload([void status]) => throw UnimplementedError();
}

class DataModeInitResponse extends MotPacket implements PayloadHandler<int> {
  @override
  parsePayload([void status]) {
    return payloadWordAt<Uint16>(0);
  }

  @override
  void buildPayload(args) => throw UnimplementedError();
}

class DataModeData extends MotPacket implements PayloadHandler<Uint8List> {
  @override
  void buildPayload(args) {
    if (!buildPayloadLength(args.length)) return; //return status
    payload.setAll(0, args);
  }

  @override
  parsePayload([void status]) => payload; //length already set
}

////////////////////////////////////////////////////////////////////////////////
/// Once Read
////////////////////////////////////////////////////////////////////////////////
class OnceReadRequest extends MotPacket implements PayloadHandler<(int address, int size)> {
  @override
  void buildPayload(args) {
    payloadLength = 8;
    payloadAsList32[0] = args.$1;
    payloadAsList32[1] = args.$2;
  }

  @override
  parsePayload([void status]) => throw UnimplementedError();
}

class OnceReadResponse extends MotPacket implements PayloadHandler<(int, Uint8List)> {
  @override
  parsePayload([void status]) {
    //check length
    return (0, payload);
  }

  @override
  void buildPayload(args) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Once Write
////////////////////////////////////////////////////////////////////////////////
class OnceWriteRequest extends MotPacket implements PayloadHandler<(int address, int size, Uint8List data)> {
  @override
  void buildPayload(args) {
    if (!buildPayloadLength(args.$3.length + 8)) return;
    payloadAsList32[0] = args.$1;
    payloadAsList32[1] = args.$2;
    payloadAt<Uint8List>(8).setAll(0, args.$3);
  }

  @override
  parsePayload([void status]) => throw UnimplementedError();
}

class OnceWriteResponse extends MotPacket implements PayloadHandler<int> {
  @override
  parsePayload([void status]) {
    return payloadWordAt<Uint16>(0);
  }

  @override
  void buildPayload(args) => throw UnimplementedError();
}
