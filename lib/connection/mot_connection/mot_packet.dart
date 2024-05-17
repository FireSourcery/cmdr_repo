// ignore_for_file: constant_identifier_names

import '../base/packet.dart';
import '../base/packet_handlers.dart';
import '../base/packet_transformer.dart';

class MotPacket extends Packet {
  MotPacket();

  @override
  int get configStartField => 0xA5;
  @override
  int get configLengthMax => 40;
  @override
  int get configHeaderLength => 8;
  @override
  Endian get configEndian => Endian.little;

  // @Uint8()
  // external int _startField;
  // @Uint8()
  // external int _idField;
  // @Uint16()
  // external int _checksumField;
  // @Uint8()
  // external int _lengthField;

  // int get startField => _startField;
  // int get idField => _idField;
  // int get checksumField => _checksumField;
  // int get lengthField => _lengthField;

  ////////////////////////////////////////////////////////////////////////////////
  /// Header
  /// `[Start, Id, Checksum[2], Length, Flex[3]]`
  ///  [PayLoad][32]
  ////////////////////////////////////////////////////////////////////////////////
  @override
  TypedOffset<Uint8> get startField => const TypedOffset<Uint8>(0);
  @override
  TypedOffset<Uint8> get idField => const TypedOffset<Uint8>(1);
  @override
  TypedOffset<Uint16> get checksumField => const TypedOffset<Uint16>(2);
  @override
  TypedOffset<Uint8> get lengthField => const TypedOffset<Uint8>(4);

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

//implements HeaderHandler
class MotPacketHeaderHandler extends MotPacket with HeaderParser {
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
  MOT_PACKET_ENTER_BOOT(0xBB),
  MOT_PACKET_ID_RESERVED_255(0xFF),
  ;

  const MotPacketSyncId(this.intId);

  final int intId;
  @override
  int get asInt => intId;
}

typedef VersionResponseValues = ({int protocol, int library, int firmware, int board});

typedef VarReadRequestValues = Iterable<int>;
typedef VarReadResponseValues = List<int>; // values

typedef VarWriteRequestValues = Iterable<(int id, int value)>;
typedef VarWriteResponseValues = List<int>; // statuses

typedef DataModeRequestValues = (int address, int size, int flags);

typedef MemReadRequestValues = (int address, int size, int config);
typedef MemReadResponseValues = (int, Uint8List data);
typedef MemWriteRequestValues = (int address, int size, int config, Uint8List data);
typedef MemWriteResponseValues = int;

enum MotPacketPayloadId<T, R> implements PacketTypeId<T, R>, MotPacketId {
  /* Fixed Length */
  MOT_PACKET_STOP_ALL<void, int>(0x00, requestPayload: StopRequest.new, responsePayload: StopResponse.new),
  MOT_PACKET_VERSION<void, VersionResponseValues>(0x01, requestPayload: VersionRequest.new, responsePayload: VersionResponse.new),
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
  MOT_PACKET_VAR_READ<VarReadRequestValues, VarReadResponseValues>(0xB3, requestPayload: VarReadRequest.new, responsePayload: VarReadResponse.new),
  MOT_PACKET_VAR_WRITE<VarWriteRequestValues, VarWriteResponseValues>(0xB4, requestPayload: VarWriteRequest.new, responsePayload: VarWriteResponse.new),

  /* Read/Write by Address */
  MOT_PACKET_MEM_READ<MemReadRequestValues, MemReadResponseValues>(0xD1, requestPayload: MemReadRequest.new, responsePayload: MemReadResponse.new),
  MOT_PACKET_MEM_WRITE<MemWriteRequestValues, MemWriteResponseValues>(0xD2, requestPayload: MemWriteRequest.new, responsePayload: MemWriteResponse.new),

  /* Stateful Read/Write */
  MOT_PACKET_DATA_MODE_READ<DataModeRequestValues, int>(0xDA, requestPayload: DataModeInitRequest.new, responsePayload: DataModeInitResponse.new),
  MOT_PACKET_DATA_MODE_WRITE<DataModeRequestValues, int>(0xDB, requestPayload: DataModeInitRequest.new, responsePayload: DataModeInitResponse.new),
  MOT_PACKET_DATA_MODE_DATA<Uint8List, Uint8List>(0xDD, requestPayload: DataModeData.new, responsePayload: DataModeData.new),
  // MOT_PACKET_DATA_MODE_ABORT = MOT_PACKET_SYNC_ABORT,

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
  final MotPacketPayloadId? responseId; // change to list? or use seperate id type for mutiple
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
class VarReadRequest extends MotPacket implements PayloadHandler<VarReadRequestValues> {
  VarReadRequest();

  @override
  (int idChecksum, int flags) buildPayload(VarReadRequestValues ids) {
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
  VarReadRequestValues parsePayload([status]) => throw UnimplementedError();
}

class VarReadResponse extends MotPacket implements PayloadHandler<VarReadResponseValues> {
  VarReadResponse();

  @override
  VarReadResponseValues parsePayload([dynamic requestStatus]) {
    // final (int idChecksum, int flags)   = requestStatus;
    // final (idChecksum, respCode) = parseVarReadMeta();
    // return ((requestStatus == null) || (requestStatus.$1 == flexUpper16Field)) ? (0, parseVarReadValues()) : (null, null);
    return payloadAt<Uint16List>(0);
  }

  // (int? idChecksum, int? respCode) parseVarReadMeta() => (flexUpper16Field,  );

  @override
  dynamic buildPayload(VarReadResponseValues args) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Write Vars
/// Req     [IdChecksum, Flags16]   [MotVarIds, Value16][8]
/// Resp    [IdChecksum, Status16]  [VarStatus8][8]
////////////////////////////////////////////////////////////////////////////////
class VarWriteRequest extends MotPacket implements PayloadHandler<VarWriteRequestValues> {
  VarWriteRequest();

  @override
  (int idChecksum, int flags) buildPayload(VarWriteRequestValues idValues) {
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
  VarWriteRequestValues parsePayload([dynamic status]) => throw UnimplementedError();
}

class VarWriteResponse extends MotPacket implements PayloadHandler<VarWriteResponseValues> {
  VarWriteResponse();

  @override
  VarWriteResponseValues parsePayload([dynamic requestStatus]) {
    // final (idChecksum, respCode) = parseVarWriteMeta();
    // return ((requestStatus == null) || (requestStatus.$1 == idChecksum)) ? (0, parseVarWriteStatuses()) : (null, null);
    return (payloadAt<Uint8List>(0));
  }

  // (int? idChecksum, int? respCode) parseMeta() => (payloadWordAt<Uint16>(0), payloadWordAt<Uint16>(2));

  @override
  dynamic buildPayload(VarWriteResponseValues args) => throw UnimplementedError();
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

class VersionResponse extends MotPacket implements PayloadHandler<VersionResponseValues> {
  @override
  VersionResponseValues parsePayload([void status]) => (
        protocol: payloadWordAt<Uint32>(0),
        library: payloadWordAt<Uint32>(4),
        firmware: payloadWordAt<Uint32>(8),
        board: payloadWordAt<Uint32>(12),
      );

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
class DataModeInitRequest extends MotPacket implements PayloadHandler<DataModeRequestValues> {
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
    if (!buildPayloadLength(args.length)) return; // return status
    payload.setAll(0, args);
  }

  @override
  parsePayload([void status]) => payload; //length already set
}

////////////////////////////////////////////////////////////////////////////////
/// Mem Read
////////////////////////////////////////////////////////////////////////////////
class MemReadRequest extends MotPacket implements PayloadHandler<MemReadRequestValues> {
  @override
  void buildPayload(MemReadRequestValues args) {
    final (address, size, config) = args;
    payloadLength = 12;
    payloadAsList32[0] = address;
    payloadAsList32[1] = size;
    payloadAsList32[2] = config;
  }

  @override
  parsePayload([void status]) => throw UnimplementedError();
}

class MemReadResponse extends MotPacket implements PayloadHandler<MemReadResponseValues> {
  @override
  parsePayload([void status]) {
    //check length
    return (0, payload);
  }

  @override
  void buildPayload(args) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Mem Write
////////////////////////////////////////////////////////////////////////////////
class MemWriteRequest extends MotPacket implements PayloadHandler<MemWriteRequestValues> {
  @override
  void buildPayload(MemWriteRequestValues args) {
    final (address, size, config, data) = args;
    if (!buildPayloadLength(data.length + 12)) return;
    payloadAsList32[0] = address;
    payloadAsList32[1] = size;
    payloadAsList32[2] = config;
    payloadAt<Uint8List>(12).setAll(0, data);
  }

  @override
  parsePayload([void status]) => throw UnimplementedError();
}

class MemWriteResponse extends MotPacket implements PayloadHandler<MemWriteResponseValues> {
  @override
  parsePayload([void status]) {
    return payloadWordAt<Uint16>(0);
  }

  @override
  void buildPayload(args) => throw UnimplementedError();
}

// final class VersionResponse1 extends Struct with Payload<VersionResponse1, VersionResponseValues> {
//   factory VersionResponse1({int board = 0, int firmware = 0, int library = 0, int protocol = 0}) {
//     return Struct.create<VersionResponse1>()
//       ..protocol = protocol
//       ..firmware = firmware
//       ..library = library;
//   }

//   @Uint32()
//   external int protocol;
//   @Uint32()
//   external int library;
//   @Uint32()
//   external int firmware;

//   // @Array(4)
//   // external Array<Uint32> versions;

//   // @override
//   // VersionResponse1 cast(TypedData target) => Struct.create<VersionResponse1>(target);

//   @override
//   dynamic build(VersionResponseValues args) {
//     protocol = args.protocol;
//     firmware = args.firmware;
//     library = args.library;
//   }

//   @override
//   VersionResponseValues parse([meta]) {
//     return (board: 0, firmware: 0, library: 0, protocol: 0);
//   }

//   // @override
//   // int get length => sizeOf<VersionResponse1>();
//   //
// }
