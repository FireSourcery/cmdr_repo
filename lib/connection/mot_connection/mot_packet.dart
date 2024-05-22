// ignore_for_file: constant_identifier_names
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../../byte_struct/typed_field.dart';
import '../base/packet.dart';

mixin class MotPacketInterface implements PacketInterface {
  const MotPacketInterface();

  @override
  int get lengthMax => 40;
  @override
  int get idHeaderLength => 2;
  @override
  int get payloadHeaderLength => 8;
  @override
  int get startId => 0xA5;
  @override
  Endian get endian => Endian.little;
  @override
  MotPacketId? idOf(int intId) => MotPacketId.of(intId);
  @override
  // MotPacketHeader castHeader(TypedData typedData) => MotPacketHeader.cast(typedData);
  MotPacketHeader headerOf(TypedData typedData) => MotPacketHeader.cast(typedData);
  @override
  MotPacketHeaderSync syncHeaderOf(TypedData typedData) => MotPacketHeaderSync.cast(typedData);

  @override
  TypedOffset<Uint8> get startFieldPart => const TypedOffset<Uint8>(0);
  @override
  TypedOffset<Uint8> get idFieldPart => const TypedOffset<Uint8>(1);
  @override
  TypedOffset<Uint16> get checksumFieldPart => const TypedOffset<Uint16>(2);
  @override
  TypedOffset<Uint8> get lengthFieldPart => const TypedOffset<Uint8>(4);

  @override
  PacketIdSync get ack => MotPacketSyncId.MOT_PACKET_SYNC_ACK;
  @override
  PacketIdSync get nack => MotPacketSyncId.MOT_PACKET_SYNC_NACK;
  @override
  PacketIdSync get abort => MotPacketSyncId.MOT_PACKET_SYNC_ABORT;

  @override
  MotPacket cast(TypedData typedData) => MotPacket.cast(typedData);
}

class MotPacket extends PacketBase with MotPacketInterface {
  MotPacket.cast(super.bytes);
  // @override
  // MotPacketHeader get packetHeader => super.packetHeader as MotPacketHeader;
}

////////////////////////////////////////////////////////////////////////////////
/// Header
/// `[Start, Id, Checksum[2], Length, Flex[3]]`
///  [PayLoad][32]
////////////////////////////////////////////////////////////////////////////////
@Packed(1)
base class MotPacketHeader extends Struct implements PacketHeader {
  factory MotPacketHeader.cast(TypedData typedData) => Struct.create<MotPacketHeader>(typedData);

  @Uint8()
  external int startField;
  @Uint8()
  external int idField;
  @Uint16()
  external int checksumField;
  @Uint8()
  external int lengthField;
  @Uint8()
  external int flex0Field;
  @Uint8()
  external int flex1Field;
  @Uint8()
  external int flex2Field;

  @override
  int get startFieldValue => startField;
  @override
  int get idFieldValue => idField;
  @override
  int get checksumFieldValue => checksumField;
  @override
  int get lengthFieldValue => lengthField;
  @override
  set startFieldValue(int value) => startField = value;
  @override
  set idFieldValue(int value) => idField = value;
  @override
  set checksumFieldValue(int value) => checksumField = value;
  @override
  set lengthFieldValue(int value) => lengthField = value;

  int get flex0FieldValue => flex0Field;
  int get flex1FieldValue => flex1Field;
  int get flex2FieldValue => flex2Field;

  set flex0FieldValue(int value) => flex0Field = value;
  set flex1FieldValue(int value) => flex1Field = value;
  set flex2FieldValue(int value) => flex2Field = value;

  int get flexUpper16FieldValue => (flex2FieldValue << 8) | flex1FieldValue;
  set flexUpper16FieldValue(int value) => this
    ..flex2FieldValue = (value >> 8)
    ..flex1FieldValue = (value & 0xFF);

  @override
  void build(PacketId packetId, Packet? packet) => UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// SyncHeader
/// `[Start, Id]`
////////////////////////////////////////////////////////////////////////////////
@Packed(1)
base class MotPacketHeaderSync extends Struct implements PacketHeaderSync {
  factory MotPacketHeaderSync.cast(TypedData typedData) => Struct.create<MotPacketHeaderSync>(typedData);

  @Uint8()
  external int startField;
  @Uint8()
  external int idField;

  @override
  int get startFieldValue => startField;
  @override
  int get idFieldValue => idField;
  @override
  set startFieldValue(int value) => startField = value;
  @override
  set idFieldValue(int value) => idField = value;
}

sealed class MotPacketId implements PacketId {
  static MotPacketId? of(int intId) => _lookUpMap[intId];

  static final Map<int, MotPacketId> _lookUpMap = Map<int, MotPacketId>.unmodifiable({
    for (final id in MotPacketSyncId.values) id.intId: id,
    for (final id in MotPacketPayloadId.values) id.intId: id,
  });
}

enum MotPacketSyncId implements PacketIdSync, MotPacketId {
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

  @override
  final int intId;
}

enum MotPacketPayloadId<T, R> implements PacketIdRequestResponse<T, R>, MotPacketId {
  /* Fixed Length */
  MOT_PACKET_STOP_ALL(0x00, requestCaster: StopRequest.cast, responseCaster: StopResponse.cast),
  MOT_PACKET_VERSION(0x01, requestCaster: VersionRequest.cast, responseCaster: VersionResponse.cast),

  MOT_PACKET_CALL(0xCC, requestCaster: CallRequest.cast, responseCaster: CallResponse.cast),
  // MOT_PACKET_CALL_ADDRESS(0xCA),
  // MOT_PACKET_FIXED_VAR_READ(0xB1),
  // MOT_PACKET_FIXED_VAR_WRITE(0xB2),

  /* Configurable Length */
  MOT_PACKET_VAR_READ(0xB3, requestCaster: VarReadRequest.cast, responseCaster: VarReadResponse.cast),
  MOT_PACKET_VAR_WRITE(0xB4, requestCaster: VarWriteRequest.cast, responseCaster: VarWriteResponse.cast),

  /* Read/Write by Address */
  MOT_PACKET_MEM_READ(0xD1, requestCaster: MemReadRequest.cast, responseCaster: MemReadResponse.cast),
  MOT_PACKET_MEM_WRITE(0xD2, requestCaster: MemWriteRequest.cast, responseCaster: MemWriteResponse.cast),

  /* Stateful Read/Write */
  MOT_PACKET_DATA_MODE_READ(0xDA, requestCaster: DataModeInitRequest.cast, responseCaster: DataModeInitResponse.cast),
  MOT_PACKET_DATA_MODE_WRITE(0xDB, requestCaster: DataModeInitRequest.cast, responseCaster: DataModeInitResponse.cast),
  MOT_PACKET_DATA_MODE_DATA(0xDD, requestCaster: DataModeData.cast, responseCaster: DataModeData.cast),
  // MOT_PACKET_DATA_MODE_ABORT = MOT_PACKET_SYNC_ABORT,

  MOT_PACKET_ID_RESERVED_255(0xFF),
  ;

  const MotPacketPayloadId(this.intId, {this.requestCaster, this.responseCaster, this.responseId});

  @override
  final int intId;
  @override
  final MotPacketPayloadId? responseId;
  @override
  final PayloadCaster<Payload<T>, T>? requestCaster;
  @override
  final PayloadCaster<Payload<R>, R>? responseCaster;

  @override
  String toString() => name;
}

////////////////////////////////////////////////////////////////////////////////
/// Read Vars
/// Req     [Length, Resv, IdSum] /  [MotVarIds][16]
/// Resp    [Length, Resv, IdSum] /  [Value16][16]
////////////////////////////////////////////////////////////////////////////////
typedef VarReadRequestValues = Iterable<int>;
typedef VarReadResponseValues = List<int>; // values

@Packed(1)
final class VarReadRequest extends Struct implements Payload<VarReadRequestValues> {
  @Array(16)
  external Array<Uint16> ids;

  // factory VarReadRequest({required Iterable<int> ids}) => Struct.create<VarReadRequest>()..build(ids);
  factory VarReadRequest.cast(TypedData typedData) => Struct.create<VarReadRequest>(typedData);

  static int get idCountMax => 16;

  @override
  PayloadMeta build(VarReadRequestValues args, [MotPacket? header]) {
    if (args.length > idCountMax) throw ArgumentError('Max Ids: $idCountMax');
    var idSum = 0;
    for (final (index, id) in args.indexed) {
      ids[index] = id;
      idSum += id;
    }
    //   flexUpper16FieldValue = idSum;
    return PayloadMeta(args.length * 2, (idSum, 0));
  }

  @override
  VarReadRequestValues parse(MotPacket header, void stateMeta) {
    // return Iterable.generate(packet.length ~/ 2, (index) => ids[index]);
    return header.payloadAt<Uint16List>(0);
  }
}

@Packed(1)
final class VarReadResponse extends Struct implements Payload<VarReadResponseValues> {
  @Array(16)
  external Array<Uint16> values;

  factory VarReadResponse.cast(TypedData typedData) => Struct.create<VarReadResponse>(typedData);

  @override
  VarReadResponseValues parse(MotPacket header, PayloadMeta? stateMeta) {
    // final (int idChecksum, int flags)   = requestStatus;
    // final (idChecksum, respCode) = parseVarReadMeta();
    // return ((requestStatus == null) || (requestStatus.$1 == flexUpper16Field)) ? (0, parseVarReadValues()) : (null, null);
    return header.payloadAt<Uint16List>(0);
  }

  @override
  PayloadMeta build(VarReadResponseValues args, [MotPacket? header]) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Write Vars
/// Req     [IdChecksum, Flags16]   [MotVarIds, Value16][8]
/// Resp    [IdChecksum, Status16]  [VarStatus8][8]
////////////////////////////////////////////////////////////////////////////////
typedef VarWriteRequestValues = Iterable<(int id, int value)>;
typedef VarWriteResponseValues = List<int>; // statuses

@Packed(1)
base class VarWriteRequest extends Struct implements Payload<VarWriteRequestValues> {
  @Array(16)
  external Array<Uint16> idValuePairs;

  factory VarWriteRequest.cast(TypedData typedData) => Struct.create<VarWriteRequest>(typedData);

  static int get pairCountMax => 8;

  @override
  PayloadMeta build(VarWriteRequestValues args, [MotPacket? header]) {
    if (args.length > pairCountMax) throw ArgumentError('Max Ids: $pairCountMax');
    var idSum = 0;
    for (final (index, (id, value)) in args.indexed) {
      idValuePairs[index * 2] = id; // 0,2,4..
      idValuePairs[index * 2 + 1] = value; // 1,3,5..
      idSum += id;
    }
    // flexUpper16FieldValue = idSum;
    return PayloadMeta(args.length * (2 + 2), (idSum, 0));
  }

  @override
  VarWriteRequestValues parse(MotPacket header, void stateMeta) {
    throw UnimplementedError();
  }
}

@Packed(1)
base class VarWriteResponse extends Struct implements Payload<VarWriteResponseValues> {
  @Array(8)
  external Array<Uint8> statuses;

  factory VarWriteResponse.cast(TypedData typedData) => Struct.create<VarWriteResponse>(typedData);

  @override
  VarWriteResponseValues parse(MotPacket header, void stateMeta) {
    // final (idChecksum, respCode) = parseVarWriteMeta();
    // return ((requestStatus == null) || (requestStatus.$1 == idChecksum)) ? (0, parseVarWriteStatuses()) : (null, null);
    return (header.payloadAt<Uint8List>(0));
  }

  // (int? idChecksum, int? respCode) parseMeta(MotPacket header) => (payloadWordAt<Uint16>(0), payloadWordAt<Uint16>(2));

  @override
  PayloadMeta build(VarWriteResponseValues args, [MotPacket? header]) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Stop
////////////////////////////////////////////////////////////////////////////////
class StopRequest implements Payload<void> {
  StopRequest();
  factory StopRequest.cast(TypedData typedData) => StopRequest();

  @override
  PayloadMeta build(void args, [MotPacket? header]) => const PayloadMeta(0);

  @override
  void parse(MotPacket header, void stateMeta) => throw UnimplementedError();
}

@Packed(1)
base class StopResponse extends Struct implements Payload<int> {
  @Uint16()
  external int status;

  factory StopResponse.cast(TypedData typedData) => Struct.create<StopResponse>(typedData);

  @override
  int parse(MotPacket header, void stateMeta) => status;

  @override
  PayloadMeta build(int args, [MotPacket? header]) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Version
/// Request:
/// Response: [Ver_LSB, Ver1, Ver2, Ver_MSB][4]
////////////////////////////////////////////////////////////////////////////////
typedef VersionResponseValues = ({int protocol, int library, int firmware, int board});

class VersionRequest implements Payload<void> {
  VersionRequest();

  factory VersionRequest.cast(TypedData typedData) => VersionRequest();

  @override
  PayloadMeta build(void args, [MotPacket? header]) => const PayloadMeta(0);

  @override
  void parse(MotPacket header, void stateMeta) => throw UnimplementedError();
}

@Packed(1)
base class VersionResponse extends Struct implements Payload<VersionResponseValues> {
  @Uint32()
  external int protocol;
  @Uint32()
  external int library;
  @Uint32()
  external int firmware;
  @Uint32()
  external int board; //deprecated

  // factory VersionResponse({int board = 0, int firmware = 0, int library = 0, int protocol = 0}) {
  //   return Struct.create<VersionResponse>()..build((board: board, firmware: firmware, library: library, protocol: protocol));
  // }

  factory VersionResponse.cast(TypedData target) => Struct.create<VersionResponse>(target);

  @override
  VersionResponseValues parse(MotPacket header, void stateMeta) {
    return (protocol: protocol, library: library, firmware: firmware, board: board);
  }

  @override
  PayloadMeta build(VersionResponseValues args, [MotPacket? header]) {
    protocol = args.protocol;
    firmware = args.firmware;
    library = args.library;
    return const PayloadMeta(16);
  }

  // @Array(4)
  // external Array<Uint32> versions;
  // List<int>? parseVersionAsList() => payloadAt<Uint32List>(0);
}

////////////////////////////////////////////////////////////////////////////////
/// Call
////////////////////////////////////////////////////////////////////////////////
typedef CallRequestValues = (int id, int? arg);
typedef CallResponseValues = (int? id, int? status);

@Packed(1)
base class CallRequest extends Struct implements Payload<CallRequestValues> {
  @Uint32()
  external int id;
  @Uint32()
  external int arg;

  factory CallRequest.cast(TypedData target) => Struct.create<CallRequest>(target);

  @override
  PayloadMeta build(CallRequestValues args, [MotPacket? header]) {
    final (id, arg) = args;
    this.id = id;
    this.arg = arg ?? 0;
    return const PayloadMeta(8);
  }

  @override
  CallRequestValues parse(MotPacket header, void stateMeta) => (id, arg);
}

@Packed(1)
base class CallResponse extends Struct implements Payload<CallResponseValues> {
  @Uint32()
  external int id;
  @Uint16()
  external int status;

  factory CallResponse.cast(TypedData target) => Struct.create<CallResponse>(target);

  @override
  CallResponseValues parse(MotPacket header, void stateMeta) => (id, status);

  @override
  PayloadMeta build(CallResponseValues args, [MotPacket? header]) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Mem Read
////////////////////////////////////////////////////////////////////////////////
typedef MemReadRequestValues = (int address, int size, int config);
typedef MemReadResponseValues = (int headerStatus, Uint8List data);

@Packed(1)
base class MemReadRequest extends Struct implements Payload<MemReadRequestValues> {
  @Uint32()
  external int address;
  @Uint8()
  external int size;
  @Uint8()
  external int resv;
  @Uint16()
  external int config;

  factory MemReadRequest.cast(TypedData target) => Struct.create<MemReadRequest>(target);

  @override
  PayloadMeta build(MemReadRequestValues args, [MotPacket? header]) {
    final (address, size, config) = args;
    this.address = address;
    this.size = size;
    this.config = config;
    return const PayloadMeta(12);
  }

  @override
  MemReadRequestValues parse(MotPacket header, void stateMeta) => throw UnimplementedError();
}

@Packed(1)
base class MemReadResponse extends Struct implements Payload<MemReadResponseValues> {
  @Array(32)
  external Array<Uint8> data;

  factory MemReadResponse.cast(TypedData target) => Struct.create<MemReadResponse>(target);

  @override
  MemReadResponseValues parse(MotPacket header, void stateMeta) {
    // return (header.packetHeader.flexUpper16FieldValue, header.payload);
    return (0, header.payload);
  }

  @override
  PayloadMeta build(MemReadResponseValues args, [MotPacket? header]) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// Mem Write
////////////////////////////////////////////////////////////////////////////////
typedef MemWriteRequestValues = (int address, int size, int config, Uint8List data);
typedef MemWriteResponseValues = int;

@Packed(1)
base class MemWriteRequest extends Struct implements Payload<MemWriteRequestValues> {
  @Uint32()
  external int address;
  @Uint8()
  external int size;
  @Uint8()
  external int resv;
  @Uint16()
  external int config;
  @Array(16)
  external Array<Uint8> data;

  factory MemWriteRequest.cast(TypedData target) => Struct.create<MemWriteRequest>(target);

  static get dataMax => 16;

  @override
  PayloadMeta build(MemWriteRequestValues args, [MotPacket? header]) {
    final (address, size, config, data) = args;
    if (data.length > dataMax) throw ArgumentError('Max Length: ${data.length + 12}');
    this.address = address;
    this.size = size;
    this.config = config;
    for (final (index, value) in data.indexed) {
      this.data[index] = value;
    }
    return PayloadMeta(data.length + 12);
  }

  @override
  MemWriteRequestValues parse(MotPacket header, void stateMeta) => throw UnimplementedError();
}

@Packed(1)
base class MemWriteResponse extends Struct implements Payload<MemWriteResponseValues> {
  @Uint16()
  external int status;

  factory MemWriteResponse.cast(TypedData target) => Struct.create<MemWriteResponse>(target);

  @override
  MemWriteResponseValues parse(MotPacket header, void stateMeta) => status;

  @override
  PayloadMeta build(MemWriteResponseValues args, [MotPacket? header]) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
/// MOT_PACKET_DATA_MODE_WRITE
/// MOT_PACKET_DATA_MODE_READ
/// typedef struct MotPacket_DataModeReq_Payload { uint32_t AddressStart; uint32_t SizeBytes; uint32_t ConfigFlags; }       MotPacket_DataModeReq_Payload_T;
////////////////////////////////////////////////////////////////////////////////
typedef DataModeRequestValues = (int address, int size, int flags);

@Packed(1)
base class DataModeInitRequest extends Struct implements Payload<DataModeRequestValues> {
  @Uint32()
  external int address;
  @Uint32()
  external int size;
  @Uint32()
  external int configFlags;

  factory DataModeInitRequest.cast(TypedData target) => Struct.create<DataModeInitRequest>(target);

  @override
  PayloadMeta build(DataModeRequestValues args, [MotPacket? header]) {
    final (address, size, configFlags) = args;
    this.address = address;
    this.size = size;
    this.configFlags = configFlags;
    return const PayloadMeta(12);
  }

  @override
  DataModeRequestValues parse(MotPacket header, void stateMeta) => throw UnimplementedError();
}

@Packed(1)
base class DataModeInitResponse extends Struct implements Payload<int> {
  @Uint16()
  external int status;

  factory DataModeInitResponse.cast(TypedData target) => Struct.create<DataModeInitResponse>(target);

  @override
  int parse(MotPacket header, void stateMeta) => status;

  @override
  PayloadMeta build(int args, [MotPacket? header]) => throw UnimplementedError();
}

@Packed(1)
base class DataModeData extends Struct implements Payload<Uint8List> {
  @Array(32)
  external Array<Uint8> data;

  static get dataMax => 32;

  factory DataModeData.cast(TypedData target) => Struct.create<DataModeData>(target);

  @override
  PayloadMeta build(Uint8List args, [MotPacket? header]) {
    if (args.length > dataMax) throw ArgumentError('Max Length: 32');
    for (final (index, value) in args.indexed) {
      data[index] = value;
    }
    return PayloadMeta(args.length);
  }

  @override
  Uint8List parse(MotPacket header, void stateMeta) => header.payload;
}
