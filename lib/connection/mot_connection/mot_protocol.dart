// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:math';
import 'dart:typed_data';

import 'package:cmdr/common/defined_types.dart';
import 'package:collection/collection.dart';

import '../base/protocol.dart';
import 'mot_packet.dart';

class MotProtocolSocket extends ProtocolSocket {
  MotProtocolSocket(super.protocol);

  ////////////////////////////////////////////////////////////////////////////////
  /// Base wrappers
  ////////////////////////////////////////////////////////////////////////////////
  Future<int?> ping() async {
    sendSync(MotPacketSyncId.MOT_PACKET_PING);
    return (await recvSync())?.intId;
    // return (await recvSync()) as MotPacketSyncId;
  }

  Future<int?> pingBoot() async {
    sendSync(MotPacketSyncId.MOT_PACKET_ENTER_BOOT);
    return (await recvSync())?.intId;
  }

  Future<int?> stopMotors() async => requestResponse(MotPacketRequestId.MOT_PACKET_STOP_ALL, null);
  Future<VersionResponseValues?> version() async => await requestResponse(MotPacketRequestId.MOT_PACKET_VERSION, null);

  Future<CallResponseValues?> call(int id, int? arg, [Duration? timeout]) async => requestResponse(MotPacketRequestId.MOT_PACKET_CALL, (id, arg), timeout: timeout);

  Future<VarReadResponseValues?> readVars(VarReadRequestValues ids) async => requestResponse(MotPacketRequestId.MOT_PACKET_VAR_READ, ids);
  Future<VarWriteResponseValues?> writeVars(VarWriteRequestValues pairs) async => requestResponse(MotPacketRequestId.MOT_PACKET_VAR_WRITE, pairs);

  ////////////////////////////////////////////////////////////////////////////////
  /// Slices
  ////////////////////////////////////////////////////////////////////////////////
  /// same input signature, but is not the content sent to the packet
  Stream<(VarReadRequestValues segmentIds, VarReadResponseValues?)> readVarsSlices(Iterable<int> ids) => iterativeRequest(MotPacketRequestId.MOT_PACKET_VAR_READ, ids.slices(16));
  Stream<(VarWriteRequestValues segmentPairs, VarWriteResponseValues?)> writeVarsSlices(Iterable<(int id, int value)> ids) => iterativeRequest(MotPacketRequestId.MOT_PACKET_VAR_WRITE, ids.slices(8));

  ////////////////////////////////////////////////////////////////////////////////
  /// Stream
  ////////////////////////////////////////////////////////////////////////////////
  Stream<VarReadResponseValues?> readVarsStream(VarReadRequestValues ids, {Duration delay = const Duration(milliseconds: 50)}) {
    assert(ids.length <= VarReadRequest.idCountMax);
    return periodicRequest(MotPacketRequestId.MOT_PACKET_VAR_READ, ids, delay: delay);
  }

  Stream<(VarReadRequestValues segmentIds, VarReadResponseValues?)> readVarsSlicesStream(Iterable<int> ids, {Duration delay = const Duration(milliseconds: 50)}) {
    return periodicIterativeRequest(MotPacketRequestId.MOT_PACKET_VAR_READ, ids.slices(VarReadRequest.idCountMax), delay: delay);
  }

  Stream<VarWriteResponseValues?> writeVarsStream(VarWriteRequestValues Function() idValuesGetter, {Duration delay = const Duration(milliseconds: 10)}) {
    assert(idValuesGetter().length <= VarWriteRequest.pairCountMax);
    return periodicUpdate(MotPacketRequestId.MOT_PACKET_VAR_WRITE, idValuesGetter, delay: delay);
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Mem
  /// 8 bytes overhead on write, potentially 4 if moving size and config to header
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
    if (size < 0) return successCode;
    final sliceSize = min(MemReadRequest.sizeMax, data.lengthInBytes);
    if (await writeMem(address, sliceSize, config, data) case int statusCode when statusCode != successCode) return statusCode;

    final nextAddress = address + sliceSize;
    final nextSize = size - sliceSize;
    final nextData = Uint8List.sublistView(data, sliceSize);
    return await writeMemSlicesRecursive(nextAddress, nextSize, config, nextData, successCode);
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// DataMode
  ////////////////////////////////////////////////////////////////////////////////
  Future<int?> initDataModeWrite(int address, int sizeBytes, int flags) async {
    return requestResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_WRITE, (address, sizeBytes, flags), syncOptions: ProtocolSyncOptions.sendAndRecv);
  }

  Future<int?> initDataModeRead(int address, int sizeBytes, int flags) async {
    return requestResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_READ, (address, sizeBytes, flags), syncOptions: ProtocolSyncOptions.sendAndRecv);
  }

  Future<void> writeDataModeData(Uint8List data) async => sendRequest(MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA, data);
  Future<Uint8List?> readDataModeData() async => recvResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA);

  ////////////////////////////////////////////////////////////////////////////////
  /// DataMode Proc Async function maintains state
  /// write without overhead
  ////////////////////////////////////////////////////////////////////////////////
  // returns status char
  // add success code match
  Future<int?> writeDataMode(int address, int sizeBytes, Uint8List data, [void Function(int bytesComplete)? progressCallback]) async {
    assert(sizeBytes == data.length);
    if (sizeBytes != data.length) return -1; // alternatively remove

    if (await initDataModeWrite(address, sizeBytes, 0) case int? response when response != 0) return response;

    // alternatively return a stream of statuses prompt for input
    try {
      for (var index = 0; index < sizeBytes; index += DataModeData.sizeMax) {
        await writeDataModeData(Uint8List.sublistView(data, index, min(DataModeData.sizeMax, sizeBytes - index))); // todo host side handle align?

        if (await recvSync() != MotPacketSyncId.MOT_PACKET_SYNC_ACK) return -1;
        progressCallback?.call(index * DataModeData.sizeMax + data.length);
      }
    } finally {
      print(sizeBytes);
    }

    // MOT_PACKET_DATA_MODE_WRITE should still be mapped
    return recvResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_WRITE)..then((_) => sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK));
  }

  Future<int?> readDataMode(int address, int sizeBytes, Uint8List dataBuffer, [void Function(int bytesComplete)? progressCallback]) async {
    assert(dataBuffer.length >= sizeBytes);

    protocol.mapRequestResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA, this); // map additional id

    if (await initDataModeRead(address, sizeBytes, 0) case int? response when response != 0) return response;

    // return a stream? from iteratively stream and yield
    for (var index = 0; index < sizeBytes; index += DataModeData.sizeMax) {
      if (await readDataModeData() case Uint8List data) {
        dataBuffer.setRange(index, index + data.length, data);
        await sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK);
        progressCallback?.call(index + data.length);
      } else {
        return -1;
      }
    }

    return recvResponse(MotPacketRequestId.MOT_PACKET_DATA_MODE_READ)..then((_) => sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK));
  }

  List<R> callStatusType<R extends Enum>() {
    return switch (R) {
      const (MotProtocol_GenericStatus) => MotProtocol_GenericStatus.values,
      const (NvMemory_Status) => NvMemory_Status.values,
      Type() => throw UnsupportedError('MotStatus.values: $R'),
    } as List<R>;
  }

  Future<R?> callTyped<R extends Enum>(MotProtocol_CallId id, [Enum? arg, Duration? timeout]) async {
    return call(id.index, arg?.index, timeout).then((value) => callStatusType<R>().elementAtOrNull.calln(value?.$2));
  }
}

enum NvMemory_Status {
  NV_MEMORY_STATUS_SUCCESS,
  NV_MEMORY_STATUS_PROCESSING,

  NV_MEMORY_STATUS_ERROR_BUSY,
  NV_MEMORY_STATUS_ERROR_CMD,
  NV_MEMORY_STATUS_ERROR_PROTECTION,

  NV_MEMORY_STATUS_ERROR_BOUNDARY,
  NV_MEMORY_STATUS_ERROR_ALIGNMENT,
  NV_MEMORY_STATUS_ERROR_BUFFER,
  NV_MEMORY_STATUS_ERROR_INVALID_OP,

  NV_MEMORY_STATUS_ERROR_VERIFY,
  NV_MEMORY_STATUS_ERROR_CHECKSUM,
  NV_MEMORY_STATUS_ERROR_NOT_IMPLEMENTED,
  NV_MEMORY_STATUS_ERROR_OTHER,
}

// todo handle wrapping types?

// Future<int> requestReadVar(int id) => procRequestResponse(MotPacketPayloadId.MOT_PACKET_READ_VAR);
// Future<int> requestWriteVar(int id, int value) => procRequestResponse(MotPacketPayloadId.MOT_PACKET_WRITE_VAR, {id: value});

enum MotProtocol_CallId {
  MOT_CALL_BLOCKING,
}

enum MotProtocol_GenericStatus {
  MOT_STATUS_OK,
  MOT_STATUS_ERROR,
  // MOT_STATUS_RESERVED,
}

enum MotProtocol_MemConfig {
  MOT_MEM_CONFIG_RAM,
  MOT_MEM_CONFIG_FLASH,
  MOT_MEM_CONFIG_EEPROM,
  MOT_MEM_CONFIG_ONCE,
  MOT_MEM_CONFIG_RESERVED,
}

// Stream<(Iterable<int> segmentIds, int? respCode, List<int> values)> readVarsStreamDebug(VarReadRequestPayload ids) {
//   Stopwatch debugStopwatch = Stopwatch()..start();
//   final stream = periodicRequestSegmented(MotPacketPayloadId.MOT_PACKET_VAR_READ, ids.slices(16), delay: const Duration(milliseconds: 5));
//   return stream.map((event) => (event.$1, 0, <int>[for (var i = 0; i < event.$1.length; i++) (sin(debugStopwatch.elapsedMilliseconds / 1000) * 32767).toInt()]));
//   //  (cos(debugStopwatch.elapsedMilliseconds / 1000) * 32767).toInt(),
// }
