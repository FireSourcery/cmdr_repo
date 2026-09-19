// ignore_for_file: constant_identifier_names, annotate_overrides

import 'dart:ffi';
import 'dart:typed_data';

import 'package:struct_data/packet/packet.dart';

export 'package:struct_data/packet/packet.dart';
export 'package:struct_data/packet/packet_parser.dart';

/// MotProtocol's wire format.
///
/// Two frame shapes, and they disagree about more than length: the data header is 8 bytes
/// with a 16-bit sum at offset 4, the control frame is 4 bytes with a 1-byte XOR at offset 3.
/// Each is its own [PacketFrameFormat] for that reason.
final class MotPacketCodec extends PacketCodec {
  const MotPacketCodec();

  @override
  int get lengthMax => 40;

  /// `[Start, Id, Length, Sequence, Checksum:2, Flex:2]`, then payload.
  @override
  PacketFrameFormat get dataFormat => const PacketFrameFormat(
    length: 8,
    startId: 0xA5,
    startField: ByteField<Uint8>(0),
    idField: ByteField<Uint8>(1),
    lengthField: ByteField<Uint8>(2),
    checksumField: ByteField<Uint16>(4),
    headerCaster: MotPacketHeader.cast,
  );

  @override
  PacketFrameFormat get syncFormat => const MotControlFormat();

  @override
  PacketSyncId get ack => MotPacketSyncId.MOT_PACKET_SYNC_ACK;
  @override
  PacketSyncId get nack => MotPacketSyncId.MOT_PACKET_SYNC_NACK;
  @override
  PacketSyncId get abort => MotPacketSyncId.MOT_PACKET_SYNC_ABORT;

  @override
  PacketId? idOf(int intId) => MotPacketId.of(intId);

  @override
  PacketFrameFormat formatOf(PacketId id) => (id is PacketSyncId) ? syncFormat : dataFormat;
}

/// The control shape: `[Start, SyncId, Option, Checksum]`, checked by
/// `Checksum = Start ^ SyncId ^ Option` — `MotPacket_BuildControl`, MotPacket.c:50.
///
/// The previous module wrote only the first two bytes and left the rest as it found them, so
/// this check byte went out as whatever the last frame had there. The device does not verify
/// it today (`MotPacket_IsValid`'s control branch is commented out at MotPacket.c:150), which
/// is why that was latent rather than broken.
final class MotControlFormat extends PacketFrameFormat {
  const MotControlFormat()
    : super(
        length: 4,
        startId: 0xA5,
        startField: const ByteField<Uint8>(0),
        idField: const ByteField<Uint8>(1),
        checksumField: const ByteField<Uint8>(3),
        headerCaster: MotPacketHeaderSync.cast,
      );

  @override
  int checksumOf(ByteData frame, int lengthInBytes) => frame.getUint8(0) ^ frame.getUint8(1) ^ frame.getUint8(2);
}

///
/// [PacketHeader] views — the header read and written as a struct with named fields, rather
/// than through the format's descriptors. Both directions go through these.
///

/// `[Start, Id, Length, Sequence, Checksum[2], Flex[2]]`
@Packed(1)
base class MotPacketHeader extends Struct implements PacketHeader {
  factory MotPacketHeader.cast(ByteData frame) => Struct.create<MotPacketHeader>(frame);

  @Uint8()
  external int startField;
  @Uint8()
  external int idField;
  @Uint8()
  external int lengthField;
  @Uint8()
  external int sequenceField;
  @Uint16()
  external int checksumField;
  @Uint16()
  external int flexField;

  int get flexLower8Field => (flexField & 0xFF);
  int get flexUpper8Field => (flexField >> 8);

  /// Derived: the wire's total less this header. Read-only, because writing it is the
  /// framing's job.
  @override
  int get payloadLength => lengthField - 8;
}

/// `[Start, SyncId, Option, Checksum]`
@Packed(1)
base class MotPacketHeaderSync extends Struct implements PacketHeader {
  factory MotPacketHeaderSync.cast(ByteData frame) => Struct.create<MotPacketHeaderSync>(frame);

  @Uint8()
  external int startField;
  @Uint8()
  external int idField;
  @Uint8()
  external int optionField;
  @Uint8()
  external int checksumField;

  /// No length on the wire: the shape fixes it, and there is no payload.
  @override
  int get lengthField => 4;
  @override
  set lengthField(int value) {}

  @override
  int get payloadLength => 0;
}

///
/// [PacketId] tables
///

sealed class MotPacketId implements PacketId {
  static MotPacketId? of(int intId) => _lookUpMap[intId];

  /// What an *arriving* byte means. Response ids share their request's byte, so they are not
  /// listed — [MotPacketRequestId.responseId] reaches a response codec directly.
  static final Map<int, MotPacketId> _lookUpMap = Map<int, MotPacketId>.unmodifiable({
    for (final id in MotPacketSyncId.values) id.intId: id,
    for (final id in MotPacketRequestId.values) id.intId: id,
    for (final id in MotPacketReservedId.values) id.intId: id,
  });
}

enum MotPacketSyncId implements PacketSyncId, MotPacketId {
  MOT_PACKET_PING(0xA0),
  // MOT_PACKET_PING_RESP(0xA1),
  MOT_PACKET_SYNC_ACK(0xA2),
  MOT_PACKET_SYNC_NACK(0xA3),
  MOT_PACKET_SYNC_ABORT(0xA4),
  MOT_PACKET_SYNC_RESV(0xA5),
  MOT_PACKET_PING_ALT(0xAA),
  MOT_PACKET_PING_BOOT(0xAB);

  const MotPacketSyncId(this.intId);

  @override
  final int intId;
}

enum MotPacketReservedId implements MotPacketId {
  MOT_PACKET_ID_RESERVED_255(0xFF);

  const MotPacketReservedId(this.intId);

  @override
  final int intId;
}

/// One row per exchange: the request byte, the codec that writes it, the codec that reads the
/// answer, and — only where it differs — the byte the answer arrives under.
enum MotPacketRequestId<T, R> implements PacketRequestId<T, R>, MotPacketId {
  /* Fixed Length */
  MOT_PACKET_STOP_ALL<void, int>(0x00, StopRequest.cast, StopResponse.cast),
  MOT_PACKET_VERSION<void, VersionResponseValues>(0x01, VersionRequest.cast, VersionResponse.cast),

  MOT_PACKET_CALL<CallRequestValues, CallResponseValues>(0xC0, CallRequest.cast, CallResponse.cast),

  MOT_PACKET_FIXED_VAR_READ<FixedVarReadRequestValues, FixedVarReadResponseValues>(0xB1, FixedVarReadRequest.cast, FixedVarReadResponse.cast),
  MOT_PACKET_FIXED_VAR_WRITE<FixedVarWriteRequestValues, FixedVarWriteResponseValues>(0xB2, FixedVarWriteRequest.cast, FixedVarWriteResponse.cast),

  /* Configurable Length */
  MOT_PACKET_VAR16_READ<VarReadRequestValues, VarReadResponseValues>(0xB3, VarReadRequest.cast, Var16ReadResponse.cast),
  MOT_PACKET_VAR16_WRITE<VarWriteRequestValues, VarWriteResponseValues>(0xB4, VarWriteRequest.cast, Var16WriteResponse.cast),
  MOT_PACKET_VAR32_READ<Var32ReadRequestValues, Var32ReadResponseValues>(0xB5, Var32ReadRequest.cast, Var32ReadResponse.cast),
  MOT_PACKET_VAR32_WRITE<Var32WriteRequestValues, Var32WriteResponseValues>(0xB6, Var32WriteRequest.cast, Var32WriteResponse.cast),

  /* Read/Write by Address */
  MOT_PACKET_MEM_READ<MemReadRequestValues, MemReadResponseValues>(0xD1, MemReadRequest.cast, MemReadResponse.cast),
  MOT_PACKET_MEM_WRITE<MemWriteRequestValues, MemWriteResponseValues>(0xD2, MemWriteRequest.cast, MemWriteResponse.cast),

  /* Stateful Read/Write */
  MOT_PACKET_DATA_MODE_READ<DataModeRequestValues, int>(0xDA, DataModeInitRequest.cast, DataModeInitResponse.cast),
  MOT_PACKET_DATA_MODE_WRITE<DataModeRequestValues, int>(0xDB, DataModeInitRequest.cast, DataModeInitResponse.cast),
  MOT_PACKET_DATA_MODE_ERASE<DataModeRequestValues, int>(0xDC, DataModeInitRequest.cast, DataModeInitResponse.cast),
  MOT_PACKET_DATA_MODE_DATA<Uint8List, Uint8List>(0xDD, DataModeData.cast, DataModeData.cast);

  /// [responseId] defaults to the request's own byte, which is every row above. An exchange
  /// answered under a different byte passes it as the fourth argument.
  const MotPacketRequestId(this.intId, this.caster, this.responseCaster, [int? responseId]) : responseId = responseId ?? intId;

  @override
  final int intId;
  @override
  final PayloadCaster<T> caster;
  @override
  final int responseId;
  @override
  final PayloadCaster<R> responseCaster;

  @override
  String toString() => name;
}

///
/// Struct for defining a region of memory, giving a name to each field.
///

///
/// 16-Bit Var
///
// typedef struct MOT_PACKET_PACKED MotPacket_VarReadReq { uint16_t MotVarIds[16U]; } MotPacket_VarReadReq_T;
// typedef struct MOT_PACKET_PACKED MotPacket_VarReadResp { uint16_t Value16[16U]; } MotPacket_VarReadResp_T;

// typedef struct MOT_PACKET_PACKED MotPacket_VarWriteReq { struct { uint16_t MotVarId; uint16_t Value16; } Pairs[8U]; }  MotPacket_VarWriteReq_T;
// typedef struct MOT_PACKET_PACKED MotPacket_VarWriteResp { uint8_t VarStatus[8U]; }                                     MotPacket_VarWriteResp_T;

///
/// Read Vars
///
typedef VarReadRequestValues = Iterable<int>;
typedef VarReadResponseValues = List<int>;

@Packed(1)
final class VarReadRequest extends Struct implements Payload<VarReadRequestValues> {
  @Array(16)
  external Array<Uint16> ids;

  factory VarReadRequest.cast(TypedData typedData) => Struct.create<VarReadRequest>(typedData);

  static int get idCountMax => 16;

  @override
  PayloadMeta build(VarReadRequestValues args) {
    if (args.length > idCountMax) throw ArgumentError('Max Ids: $idCountMax');
    for (final (index, id) in args.indexed) {
      ids[index] = id;
    }
    return PayloadMeta(args.length * 2);
  }

  @override
  VarReadRequestValues parse(PacketHeader header) => throw UnimplementedError();
}

@Packed(1)
final class Var16ReadResponse extends Struct implements Payload<VarReadResponseValues> {
  @Array(16)
  external Array<Uint16> values;

  factory Var16ReadResponse.cast(TypedData typedData) => Struct.create<Var16ReadResponse>(typedData);

  /// The struct is 32 bytes and the frame's body is usually shorter, so the cast is over the
  /// whole payload span — `Struct.create` throws on anything shorter than the struct. The
  /// header's declared length is what bounds the result.
  ///
  /// `Array.elements` aliases the struct's own bytes, so this is a view of the frame, not a
  /// copy of it. This is the workaround the previous version described here and never applied.
  @override
  VarReadResponseValues parse(PacketHeader header) => Uint16List.sublistView(values.elements, 0, header.payloadLength ~/ 2);

  @override
  PayloadMeta build(VarReadResponseValues args) => throw UnimplementedError();
}

///
/// Write Vars
///
typedef VarWriteRequestValues = Iterable<(int id, int value)>;
typedef VarWriteResponseValues = List<int>; // statuses

@Packed(1)
base class VarWriteRequest extends Struct implements Payload<VarWriteRequestValues> {
  @Array(16)
  external Array<Uint16> idValuePairs;

  factory VarWriteRequest.cast(TypedData typedData) => Struct.create<VarWriteRequest>(typedData);

  static int get pairCountMax => 8;

  @override
  PayloadMeta build(VarWriteRequestValues args) {
    if (args.length > pairCountMax) throw ArgumentError('Max Ids: $pairCountMax');
    for (final (index, (id, value)) in args.indexed) {
      idValuePairs[index * 2] = id; // 0,2,4..
      idValuePairs[index * 2 + 1] = value; // 1,3,5..
    }
    return PayloadMeta(args.length * (2 + 2));
  }

  @override
  VarWriteRequestValues parse(PacketHeader header) {
    throw UnimplementedError();
  }
}

@Packed(1)
base class Var16WriteResponse extends Struct implements Payload<VarWriteResponseValues> {
  @Array(8)
  external Array<Uint8> statuses;

  factory Var16WriteResponse.cast(TypedData typedData) => Struct.create<Var16WriteResponse>(typedData);

  @override
  VarWriteResponseValues parse(PacketHeader header) {
    return Uint8List.sublistView(statuses.elements, 0, header.payloadLength);
  }

  @override
  PayloadMeta build(VarWriteResponseValues args) => throw UnimplementedError();
}

///
/// Fixed-size [Var] Read/Write
/// A single id/value pair, value widened to 32-bit. These structs also serve as the
/// per-entry element of the batched [Var32] structs below (mirroring the C `Read[]`/`Write[]` arrays).
///
// typedef struct MOT_PACKET_PACKED MotPacket_VarReadFixedReq { uint16_t MotVarId; uint16_t Flags; }   MotPacket_VarReadFixedReq_T;
// typedef struct MOT_PACKET_PACKED MotPacket_VarReadFixedResp { uint32_t Value; }                     MotPacket_VarReadFixedResp_T;

// typedef struct MOT_PACKET_PACKED MotPacket_VarWriteFixedReq { uint16_t MotVarId; uint16_t Flags; uint32_t Value; }    MotPacket_VarWriteFixedReq_T;
// typedef struct MOT_PACKET_PACKED MotPacket_VarWriteFixedResp { uint8_t Status; }                                      MotPacket_VarWriteFixedResp_T;

typedef FixedVarReadRequestValues = ({int id, int flags});
typedef FixedVarReadResponseValues = int; // value
typedef FixedVarWriteRequestValues = ({int id, int flags, int value});
typedef FixedVarWriteResponseValues = int; // status

@Packed(1)
base class FixedVarReadRequest extends Struct implements Payload<FixedVarReadRequestValues> {
  @Uint16()
  external int id;
  @Uint16()
  external int flags;

  factory FixedVarReadRequest.cast(TypedData typedData) => Struct.create<FixedVarReadRequest>(typedData);

  @override
  PayloadMeta build(FixedVarReadRequestValues args) {
    id = args.id;
    flags = args.flags;
    return const PayloadMeta(4);
  }

  @override
  FixedVarReadRequestValues parse(PacketHeader header) => (id: id, flags: flags);
}

@Packed(1)
base class FixedVarReadResponse extends Struct implements Payload<FixedVarReadResponseValues> {
  @Uint32()
  external int value;

  factory FixedVarReadResponse.cast(TypedData typedData) => Struct.create<FixedVarReadResponse>(typedData);

  @override
  FixedVarReadResponseValues parse(PacketHeader header) => value;

  @override
  PayloadMeta build(FixedVarReadResponseValues args) => throw UnimplementedError();
}

@Packed(1)
base class FixedVarWriteRequest extends Struct implements Payload<FixedVarWriteRequestValues> {
  @Uint16()
  external int id;
  @Uint16()
  external int flags;
  @Uint32()
  external int value;

  factory FixedVarWriteRequest.cast(TypedData typedData) => Struct.create<FixedVarWriteRequest>(typedData);

  @override
  PayloadMeta build(FixedVarWriteRequestValues args) {
    id = args.id;
    flags = args.flags;
    value = args.value;
    return const PayloadMeta(8);
  }

  @override
  FixedVarWriteRequestValues parse(PacketHeader header) => (id: id, flags: flags, value: value);
}

@Packed(1)
base class FixedVarWriteResponse extends Struct implements Payload<FixedVarWriteResponseValues> {
  @Uint8()
  external int status;

  factory FixedVarWriteResponse.cast(TypedData typedData) => Struct.create<FixedVarWriteResponse>(typedData);

  @override
  FixedVarWriteResponseValues parse(PacketHeader header) => status;

  @override
  PayloadMeta build(FixedVarWriteResponseValues args) => throw UnimplementedError();
}

///
/// 32-Bit [Var] Read/Write
/// Batched fixed-var operations. Each entry reuses the [FixedVar] structs as its element type.
///
// typedef struct MOT_PACKET_PACKED MotPacket_Var32ReadReq { MotPacket_VarReadFixedReq_T Read[8U]; } MotPacket_Var32ReadReq_T;
// typedef struct MOT_PACKET_PACKED MotPacket_Var32ReadResp { uint32_t Values[8U]; } MotPacket_Var32ReadResp_T;

// typedef struct MOT_PACKET_PACKED MotPacket_Var32WriteReq { MotPacket_VarWriteFixedReq_T Write[4U]; }    MotPacket_Var32WriteReq_T;
// typedef struct MOT_PACKET_PACKED MotPacket_Var32WriteResp { uint8_t VarStatus[4U]; }                    MotPacket_Var32WriteResp_T;

///
/// Read Var32s
///
typedef Var32ReadRequestValues = Iterable<(int id, int flags)>;
typedef Var32ReadResponseValues = List<int>; // values

@Packed(1)
base class Var32ReadRequest extends Struct implements Payload<Var32ReadRequestValues> {
  @Array(8)
  external Array<FixedVarReadRequest> reads;

  factory Var32ReadRequest.cast(TypedData typedData) => Struct.create<Var32ReadRequest>(typedData);

  static int get idCountMax => 8;

  @override
  PayloadMeta build(Var32ReadRequestValues args) {
    if (args.length > idCountMax) throw ArgumentError('Max Ids: $idCountMax');
    for (final (index, (id, flags)) in args.indexed) {
      reads[index]
        ..id = id
        ..flags = flags;
    }
    return PayloadMeta(args.length * 4);
  }

  @override
  Var32ReadRequestValues parse(PacketHeader header) => throw UnimplementedError();
}

@Packed(1)
base class Var32ReadResponse extends Struct implements Payload<Var32ReadResponseValues> {
  @Array(8)
  external Array<Uint32> values;

  factory Var32ReadResponse.cast(TypedData typedData) => Struct.create<Var32ReadResponse>(typedData);

  @override
  Var32ReadResponseValues parse(PacketHeader header) {
    // under length packet will be reject at parser
    return Uint32List.sublistView(values.elements, 0, header.payloadLength ~/ 4);
  }

  @override
  PayloadMeta build(Var32ReadResponseValues args) => throw UnimplementedError();
}

///
/// Write Var32s
///
typedef Var32WriteRequestValues = Iterable<(int id, int flags, int value)>;
typedef Var32WriteResponseValues = List<int>; // statuses

@Packed(1)
base class Var32WriteRequest extends Struct implements Payload<Var32WriteRequestValues> {
  @Array(4)
  external Array<FixedVarWriteRequest> writes;

  factory Var32WriteRequest.cast(TypedData typedData) => Struct.create<Var32WriteRequest>(typedData);

  static int get pairCountMax => 4;

  @override
  PayloadMeta build(Var32WriteRequestValues args) {
    if (args.length > pairCountMax) throw ArgumentError('Max Ids: $pairCountMax');
    for (final (index, (id, flags, value)) in args.indexed) {
      writes[index]
        ..id = id
        ..flags = flags
        ..value = value;
    }
    return PayloadMeta(args.length * 8);
  }

  @override
  Var32WriteRequestValues parse(PacketHeader header) => throw UnimplementedError();
}

@Packed(1)
base class Var32WriteResponse extends Struct implements Payload<Var32WriteResponseValues> {
  @Array(4)
  external Array<Uint8> statuses;

  factory Var32WriteResponse.cast(TypedData typedData) => Struct.create<Var32WriteResponse>(typedData);

  @override
  Var32WriteResponseValues parse(PacketHeader header) {
    return Uint8List.sublistView(statuses.elements, 0, header.payloadLength);
  }

  @override
  PayloadMeta build(Var32WriteResponseValues args) => throw UnimplementedError();
}

///
/// Stop
///
class StopRequest implements Payload<void> {
  StopRequest();
  factory StopRequest.cast(TypedData typedData) => StopRequest();

  @override
  PayloadMeta build(void args) => const PayloadMeta(0);

  @override
  void parse(PacketHeader header) => throw UnimplementedError();
}

@Packed(1)
base class StopResponse extends Struct implements Payload<int> {
  @Uint16()
  external int status;

  factory StopResponse.cast(TypedData typedData) => Struct.create<StopResponse>(typedData);

  @override
  int parse(PacketHeader header) => status;

  @override
  PayloadMeta build(int args) => throw UnimplementedError();
}

///
/// Version
/// Request:
/// Response: [Ver_LSB, Ver1, Ver2, Ver_MSB][4]
///
typedef VersionResponseValues = ({int protocol, int library, int firmware});

class VersionRequest implements Payload<void> {
  VersionRequest();

  factory VersionRequest.cast(TypedData typedData) => VersionRequest();

  @override
  PayloadMeta build(void args) => const PayloadMeta(0);

  @override
  void parse(PacketHeader header) => throw UnimplementedError();
}

@Packed(1)
base class VersionResponse extends Struct implements Payload<VersionResponseValues> {
  @Uint32()
  external int protocol;
  @Uint32()
  external int library;
  @Uint32()
  external int firmware;

  factory VersionResponse.cast(TypedData target) => Struct.create<VersionResponse>(target);

  @override
  VersionResponseValues parse(PacketHeader header) {
    return (protocol: protocol, library: library, firmware: firmware);
  }

  @override
  PayloadMeta build(VersionResponseValues args) {
    protocol = args.protocol;
    firmware = args.firmware;
    library = args.library;
    return const PayloadMeta(12);
  }

  // @Array(4)
  // external Array<Uint32> versions;
  // List<int>? parseVersionAsList() => payloadAt<Uint32List>(0);
}

///
/// Call
///
typedef CallRequestValues = ({int id, int? arg});
typedef CallResponseValues = ({int id, int status});

@Packed(1)
base class CallRequest extends Struct implements Payload<CallRequestValues> {
  @Uint32()
  external int id;
  @Uint32()
  external int arg;

  factory CallRequest.cast(TypedData target) => Struct.create<CallRequest>(target);

  @override
  PayloadMeta build(CallRequestValues args) {
    id = args.id;
    arg = args.arg ?? 0;
    return const PayloadMeta(8);
  }

  @override
  CallRequestValues parse(PacketHeader header) => (id: id, arg: arg);
}

@Packed(1)
base class CallResponse extends Struct implements Payload<CallResponseValues> {
  @Uint32()
  external int id;
  @Uint16()
  external int status;

  factory CallResponse.cast(TypedData target) => Struct.create<CallResponse>(target);

  @override
  CallResponseValues parse(PacketHeader header) => (id: id, status: status);

  @override
  PayloadMeta build(CallResponseValues args) => throw UnimplementedError();
}

///
/// Mem Read
///
typedef MemReadRequestValues = ({int address, int size, int config}); // should probably user named parameters for extension

typedef MemReadResponseValues = ({int status, Uint8List data});

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

  static int get sizeMax => 32;

  factory MemReadRequest.cast(TypedData target) => Struct.create<MemReadRequest>(target);

  @override
  PayloadMeta build(MemReadRequestValues args) {
    address = args.address;
    size = args.size;
    config = args.config;
    return const PayloadMeta(12);
  }

  @override
  MemReadRequestValues parse(PacketHeader header) => throw UnimplementedError();
}

@Packed(1)
base class MemReadResponse extends Struct implements Payload<MemReadResponseValues> {
  @Array(32)
  external Array<Uint8> data;

  factory MemReadResponse.cast(TypedData target) => Struct.create<MemReadResponse>(target);

  @override
  MemReadResponseValues parse(PacketHeader header) {
    // return (header.packetHeader.flexUpper16FieldValue, header.payload);
    return (status: 0, data: Uint8List.sublistView(data.elements, 0, header.payloadLength));
  }

  @override
  PayloadMeta build(MemReadResponseValues args) => throw UnimplementedError();
}

///
/// Mem Write
///
typedef MemWriteRequestValues = ({int address, int size, int config, Uint8List data}); // change to List<int>?

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

  static int get sizeMax => 16;

  @override
  PayloadMeta build(MemWriteRequestValues args) {
    if (size > sizeMax) throw ArgumentError('Max Length $sizeMax: $size');
    address = args.address;
    size = args.size;
    config = args.config;
    // loops on size. args.data.length may be greater
    for (var index = 0; index < size; index++) {
      data[index] = args.data[index];
    }
    return PayloadMeta(size + 8);
  }

  @override
  MemWriteRequestValues parse(PacketHeader header) => throw UnimplementedError();
}

@Packed(1)
base class MemWriteResponse extends Struct implements Payload<MemWriteResponseValues> {
  @Uint16()
  external int status;

  factory MemWriteResponse.cast(TypedData target) => Struct.create<MemWriteResponse>(target);

  @override
  MemWriteResponseValues parse(PacketHeader header) => status;

  @override
  PayloadMeta build(MemWriteResponseValues args) => throw UnimplementedError();
}

///
/// MOT_PACKET_DATA_MODE_WRITE
/// MOT_PACKET_DATA_MODE_READ
///
typedef DataModeRequestValues = ({int address, int size, int flags});

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
  PayloadMeta build(DataModeRequestValues args) {
    address = args.address;
    size = args.size;
    configFlags = args.flags;
    return const PayloadMeta(12);
  }

  @override
  DataModeRequestValues parse(PacketHeader header) => throw UnimplementedError();
}

@Packed(1)
base class DataModeInitResponse extends Struct implements Payload<int> {
  @Uint16()
  external int status;

  factory DataModeInitResponse.cast(TypedData target) => Struct.create<DataModeInitResponse>(target);

  @override
  int parse(PacketHeader header) => status;

  @override
  PayloadMeta build(int args) => throw UnimplementedError();
}

@Packed(1)
base class DataModeData extends Struct implements Payload<Uint8List> {
  @Array(32)
  external Array<Uint8> data;

  static int get sizeMax => 32;

  factory DataModeData.cast(TypedData target) => Struct.create<DataModeData>(target);

  @override
  PayloadMeta build(Uint8List args) {
    if (args.length > sizeMax) throw ArgumentError('Max Length: 32');
    for (final (index, value) in args.indexed) {
      data[index] = value;
    }
    return PayloadMeta(args.length);
  }

  @override
  Uint8List parse(PacketHeader header) => Uint8List.sublistView(data.elements, 0, header.payloadLength);
}
