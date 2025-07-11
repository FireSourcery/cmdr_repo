// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../base/protocol.dart';
import 'mot_packet.dart';

class MotProtocolSocket extends ProtocolSocket {
  MotProtocolSocket(super.protocol);

  ////////////////////////////////////////////////////////////////////////////////
  /// Base wrappers
  ////////////////////////////////////////////////////////////////////////////////
  @override
  Future<PacketSyncId?> ping([MotPacketSyncId id = MotPacketSyncId.MOT_PACKET_PING, MotPacketSyncId? respId, Duration timeout = ProtocolSocket.timeoutDefault]) async => super.ping(id, respId);

  Future<int?> stopMotors() async => requestResponse(MotPacketRequestId.MOT_PACKET_STOP_ALL, null);
  Future<VersionResponseValues?> version() async => await requestResponse(MotPacketRequestId.MOT_PACKET_VERSION, null);

  Future<CallResponseValues?> call(int id, int? arg, [Duration timeout = const Duration(milliseconds: 500)]) async => requestResponse(MotPacketRequestId.MOT_PACKET_CALL, (id, arg), timeout: timeout);

  ////////////////////////////////////////////////////////////////////////////////
  /// Vars by Key
  ////////////////////////////////////////////////////////////////////////////////
  Future<VarReadResponseValues?> readVars(VarReadRequestValues ids) async => requestResponse(MotPacketRequestId.MOT_PACKET_VAR_READ, ids);
  Future<VarWriteResponseValues?> writeVars(VarWriteRequestValues pairs) async => requestResponse(MotPacketRequestId.MOT_PACKET_VAR_WRITE, pairs);

  ////////////////////////////////////////////////////////////////////////////////
  /// Mem
  /// 8 bytes overhead on write, potentially 4, moving size and config to header
  ////////////////////////////////////////////////////////////////////////////////
  Future<MemReadResponseValues?> readMem(int address, int size, int config) async {
    assert(size <= MemReadRequest.sizeMax);
    return await requestResponse(MotPacketRequestId.MOT_PACKET_MEM_READ, (address, size, config));
  }

  Future<MemWriteResponseValues?> writeMem(int address, int size, int config, Uint8List data) async {
    assert(size <= MemWriteRequest.sizeMax);
    return await requestResponse(MotPacketRequestId.MOT_PACKET_MEM_WRITE, (address, size, config, data));
  }

  Stream<(MemReadRequestValues sliceArgs, MemReadResponseValues?)> readMemSlices(int address, int size, int config) {
    return iterativeRequest(MotPacketRequestId.MOT_PACKET_MEM_READ, (address, size, config).slices);
  }

  Stream<(MemWriteRequestValues sliceArgs, MemWriteResponseValues?)> writeMemSlices(int address, int size, int config, Uint8List data) {
    return iterativeRequest(MotPacketRequestId.MOT_PACKET_MEM_WRITE, (address, size, config, data).slices);
  }

  Future<MemWriteResponseValues?> writeMemSlicesRecursive(int address, int size, int config, Uint8List data, [int successCode = 0]) async {
    if (size <= 0 || data.lengthInBytes <= 0) return successCode;
    final sliceSize = min(MemReadRequest.sizeMax, data.lengthInBytes);
    if (await writeMem(address, sliceSize, config, data) case int statusCode when statusCode != successCode) return statusCode;
    return await writeMemSlicesRecursive(address + sliceSize, size - sliceSize, config, Uint8List.sublistView(data, sliceSize), successCode);
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// DataMode
  ////////////////////////////////////////////////////////////////////////////////
  Future<int?> initDataModeWrite(int address, int sizeBytes, int flags) async {
    return requestResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_WRITE, (address, sizeBytes, flags), syncOptions: ProtocolSyncOptions.sendAndRecv, timeout: const Duration(milliseconds: 2000));
  }

  Future<int?> initDataModeRead(int address, int sizeBytes, int flags) async {
    protocol.mapRequestResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA, this); // map additional id
    return requestResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_READ, (address, sizeBytes, flags), syncOptions: ProtocolSyncOptions.sendAndRecv);
  }

  Future<int?> endDataModeWrite() async => recvResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_WRITE)..then((_) => sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK));
  Future<int?> endDataModeRead() async => recvResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_READ)..then((_) => sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK));

  Future<void> writeDataModeData(Uint8List data) async => sendRequest(MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA, data);
  Future<Uint8List?> readDataModeData() async => recvResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA);

// return length written
  Stream<int> writeDataModeStream(Uint8List data) async* {
    for (final slice in data.typedSlices<Uint8List>(DataModeData.sizeMax)) {
      await writeDataModeData(slice);
      yield await recvSync().then((value) => (value == MotPacketSyncId.MOT_PACKET_SYNC_ACK) ? slice.length : 0);
      await Future.delayed(ProtocolSocket.datagramDelay);
    }
  }

  Stream<Uint8List?> readDataModeStream(int sizeBytes) async* {
    for (var index = 0; index < sizeBytes; index += DataModeData.sizeMax) {
      yield await (readDataModeData()..then<void>((data) => sendSync(data != null ? MotPacketSyncId.MOT_PACKET_SYNC_ACK : MotPacketSyncId.MOT_PACKET_SYNC_NACK)));
    }
  }
}

// Future<int> requestReadVar(int id) => procRequestResponse(MotPacketPayloadId.MOT_PACKET_READ_VAR);
// Future<int> requestWriteVar(int id, int value) => procRequestResponse(MotPacketPayloadId.MOT_PACKET_WRITE_VAR, {id: value});



  /// Slices
  /// same input signature, but is not the content sent to the packet
  // Stream<(VarReadRequestValues sliceIds, VarReadResponseValues?)> readVarsSlices(Iterable<int> ids) => iterativeRequest(MotPacketRequestId.MOT_PACKET_VAR_READ, ids.slices(16));
  // Stream<(VarWriteRequestValues slicePairs, VarWriteResponseValues?)> writeVarsSlices(Iterable<(int id, int value)> ids) => iterativeRequest(MotPacketRequestId.MOT_PACKET_VAR_WRITE, ids.slices(8));

  // /// Periodic Stream
  // Stream<VarReadResponseValues?> readVarsStream(VarReadRequestValues ids, {Duration delay = const Duration(milliseconds: 50)}) {
  //   assert(ids.length <= VarReadRequest.idCountMax);
  //   return periodicRequest(MotPacketRequestId.MOT_PACKET_VAR_READ, ids, delay: delay);
  // }

  // Stream<(VarReadRequestValues sliceIds, VarReadResponseValues?)> readVarsSlicesStream(Iterable<int> ids, {Duration delay = const Duration(milliseconds: 50)}) {
  //   return periodicIterativeRequest(MotPacketRequestId.MOT_PACKET_VAR_READ, ids.slices(VarReadRequest.idCountMax), delay: delay);
  // }

  // Stream<VarWriteResponseValues?> writeVarsStream(VarWriteRequestValues Function() idValuesGetter, {Duration delay = const Duration(milliseconds: 10)}) {
  //   assert(idValuesGetter().length <= VarWriteRequest.pairCountMax);
  //   return periodicUpdate(MotPacketRequestId.MOT_PACKET_VAR_WRITE, idValuesGetter, delay: delay);
  // }
