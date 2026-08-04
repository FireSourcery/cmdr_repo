// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:math';
import 'dart:typed_data';

import '../base/protocol.dart';
import 'mot_packet.dart';

class MotProtocolSocket extends ProtocolSocket {
  MotProtocolSocket(super.protocol);

  ///
  /// Base wrappers
  ///
  @override
  Future<PacketSyncId?> ping(MotPacketSyncId id, {MotPacketSyncId? respId, Duration timeout = ProtocolSocket.timeoutDefault}) async => super.ping(id, respId: respId, timeout: timeout);

  Future<PacketSyncId?> pingDefault({MotPacketSyncId id = MotPacketSyncId.MOT_PACKET_PING, MotPacketSyncId? respId, Duration timeout = ProtocolSocket.timeoutDefault}) async =>
      super.ping(id, respId: respId ?? id, timeout: timeout);

  Future<PacketSyncId?> pingBoot() async => super.ping(MotPacketSyncId.MOT_PACKET_PING_BOOT, respId: MotPacketSyncId.MOT_PACKET_PING_BOOT, timeout: const Duration(milliseconds: 500));

  Future<int?> stopMotors() async => requestResponse(MotPacketRequestId.MOT_PACKET_STOP_ALL, null);
  Future<VersionResponseValues?> version() async => await requestResponse(MotPacketRequestId.MOT_PACKET_VERSION, null);

  Future<CallResponseValues?> call(int id, int? arg, [Duration timeout = const Duration(milliseconds: 1000)]) async =>
      requestResponse(MotPacketRequestId.MOT_PACKET_CALL, (id: id, arg: arg), timeout: timeout);

  ///
  /// Vars by Key
  ///
  Future<VarReadResponseValues?> readVars(VarReadRequestValues ids) async => requestResponse(MotPacketRequestId.MOT_PACKET_VAR_READ, ids);
  Future<VarWriteResponseValues?> writeVars(VarWriteRequestValues pairs) async => requestResponse(MotPacketRequestId.MOT_PACKET_VAR_WRITE, pairs);

  ///
  /// Fixed-size Var (single id, 32-bit value)
  ///
  Future<FixedVarReadResponseValues?> readVarFixed(int id, [int flags = 0]) async => requestResponse(MotPacketRequestId.MOT_PACKET_FIXED_VAR_READ, (id: id, flags: flags));
  Future<FixedVarWriteResponseValues?> writeVarFixed(int id, int value, [int flags = 0]) async => requestResponse(MotPacketRequestId.MOT_PACKET_FIXED_VAR_WRITE, (id: id, flags: flags, value: value));

  ///
  /// 32-Bit Vars by Key (batched fixed-size vars)
  ///
  Future<Var32ReadResponseValues?> readVars32(Var32ReadRequestValues idFlags) async => requestResponse(MotPacketRequestId.MOT_PACKET_VAR32_READ, idFlags);
  Future<Var32WriteResponseValues?> writeVars32(Var32WriteRequestValues entries) async => requestResponse(MotPacketRequestId.MOT_PACKET_VAR32_WRITE, entries);

  ///
  /// Mem
  /// 8 bytes overhead on write, potentially 4, moving size and config to header
  ///
  Future<MemReadResponseValues?> readMem(int address, int size, int config) async {
    assert(size <= MemReadRequest.sizeMax);
    return await requestResponse(MotPacketRequestId.MOT_PACKET_MEM_READ, (address: address, size: size, config: config), timeout: const Duration(milliseconds: 1000));
  }

  Future<MemWriteResponseValues?> writeMem(int address, int size, int config, Uint8List data) async {
    assert(size <= MemWriteRequest.sizeMax);
    return await requestResponse(MotPacketRequestId.MOT_PACKET_MEM_WRITE, (address: address, size: size, config: config, data: data));
  }

  Stream<(MemReadRequestValues sliceArgs, MemReadResponseValues?)> readMemSlices(int address, int size, int config) {
    return iterativeRequest(MotPacketRequestId.MOT_PACKET_MEM_READ, (address: address, size: size, config: config).slices);
  }

  Stream<(MemWriteRequestValues sliceArgs, MemWriteResponseValues?)> writeMemSlices(int address, int size, int config, Uint8List data) {
    return iterativeRequest(MotPacketRequestId.MOT_PACKET_MEM_WRITE, (address: address, size: size, config: config, data: data).slices);
  }

  Future<MemWriteResponseValues?> writeMemSlicesRecursive(int address, int size, int config, Uint8List data, [int successCode = 0]) async {
    if (size <= 0 || data.lengthInBytes <= 0) return successCode;
    final sliceSize = min(MemReadRequest.sizeMax, data.lengthInBytes);
    if (await writeMem(address, sliceSize, config, data) case int statusCode when statusCode != successCode) return statusCode;
    return await writeMemSlicesRecursive(address + sliceSize, size - sliceSize, config, Uint8List.sublistView(data, sliceSize), successCode);
  }

  ///
  /// DataMode
  ///
  Future<int?> eraseMemRegion(int address, int sizeBytes, int flags) async {
    return requestResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_ERASE, (address: address, size: sizeBytes, flags: flags), timeout: const Duration(milliseconds: 5000));
  }

  Future<int?> initDataModeWrite(int address, int sizeBytes, int flags) async {
    return requestResponse(
      MotPacketRequestId.MOT_PACKET_DATA_MODE_WRITE,
      (address: address, size: sizeBytes, flags: flags),
      syncOptions: ProtocolSyncOptions.sendAndRecv,
      timeout: const Duration(milliseconds: 5000), // includes the flash erase time
    );
  }

  Future<int?> initDataModeRead(int address, int sizeBytes, int flags) async {
    protocol.mapRequestResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA, this); // map additional id
    return requestResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_READ, (address: address, size: sizeBytes, flags: flags), syncOptions: ProtocolSyncOptions.sendAndRecv);
  }

  Future<int?> endDataModeWrite() async => recvResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_WRITE)..then((_) => sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK));

  Future<int?> endDataModeRead() async => recvResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_READ)..then((_) => sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK));

  Future<void> writeDataModeData(Uint8List data) async => sendRequest(MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA, data);
  Future<Uint8List?> readDataModeData() async => recvResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA);

  // return length written
  Stream<int> writeDataModeStream(Uint8List data) async* {
    for (final slice in data.typedSlices(DataModeData.sizeMax)) {
      await writeDataModeData(slice);
      // sync alreadyy mapped
      yield await recvSync().then((value) => (value == MotPacketSyncId.MOT_PACKET_SYNC_ACK) ? slice.length : 0);
      await Future.delayed(ProtocolSocket.datagramDelay);
    }
    // caller should call endDataModeWrite() to get final status
  }

  Stream<Uint8List?> readDataModeStream(int sizeBytes) async* {
    for (var index = 0; index < sizeBytes; index += DataModeData.sizeMax) {
      yield await (readDataModeData()..then<void>((data) => sendSync(data != null ? MotPacketSyncId.MOT_PACKET_SYNC_ACK : MotPacketSyncId.MOT_PACKET_SYNC_NACK)));
    }
  }
}

extension MemReadRequestMethods on MemReadRequestValues {
  // List should be relatively small, so a new list is likely more efficient than a generator
  Iterable<MemReadRequestValues> get slices {
    return [
      for (var offset = 0; offset < size; offset += MemReadRequest.sizeMax) //
        (address: address + offset, size: min((size - offset), MemReadRequest.sizeMax), config: config),
    ];
  }
}

extension MemWriteRequestMethods on MemWriteRequestValues {
  Iterable<MemWriteRequestValues> get slices {
    return [
      for (var offset = 0; offset < size; offset += MemWriteRequest.sizeMax)
        (address: address + offset, size: min((size - offset), MemWriteRequest.sizeMax), config: config, data: Uint8List.sublistView(data, offset)),
      // not strictly necessary to clamp sublistView end, if build packet loops on size parameter
    ];
  }
}
