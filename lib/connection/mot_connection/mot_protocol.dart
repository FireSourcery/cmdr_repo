// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:math';

import 'package:cmdr/byte_struct/typed_data_ext.dart';
import 'package:collection/collection.dart';

import '../base/packet.dart';
import '../base/protocol.dart';
import 'mot_packet.dart';

class MotProtocolSocket extends ProtocolSocket {
  MotProtocolSocket(Protocol protocol) : super.generate(protocol, MotPacket.new);

  Future<int?> ping() async {
    sendSync(MotPacketSyncId.MOT_PACKET_PING);
    return (await recvSync())?.asInt;
  }

  Future<int?> pingBoot() async {
    sendSync(MotPacketSyncId.MOT_PACKET_ENTER_BOOT);
    return (await recvSync())?.asInt;
  }

  Future<int?> stopMotors() async => requestResponse(MotPacketPayloadId.MOT_PACKET_STOP_ALL, null);

  Future<int?> call((int id, int? arg) idArg, [Duration? timeout]) async => requestResponse(MotPacketPayloadId.MOT_PACKET_CALL, idArg, timeout: timeout);

  Future<VersionResponseValues> version() async => await requestResponse(MotPacketPayloadId.MOT_PACKET_VERSION, null) ?? (board: 0, firmware: 0, library: 0, protocol: 0);

  Future<(int? respCode, VarReadResponseValues)> readVars(VarReadRequestValues ids) async {
    return requestResponse(MotPacketPayloadId.MOT_PACKET_VAR_READ, ids).then((value) => ((value == null) ? null : 0, value ?? const <int>[]));
  }

  Future<(int? respCode, VarWriteResponseValues)> writeVars(VarWriteRequestValues pairs) async {
    return requestResponse(MotPacketPayloadId.MOT_PACKET_VAR_WRITE, pairs).then((value) => ((value == null) ? null : 0, value ?? const <int>[]));
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Stream
  ////////////////////////////////////////////////////////////////////////////////
  Stream<(int? respCode, VarReadResponseValues)> readVarsStream(VarReadRequestValues ids, {Duration delay = const Duration(milliseconds: 50)}) {
    assert(ids.length <= 16);
    final stream = periodicRequest(MotPacketPayloadId.MOT_PACKET_VAR_READ, ids, delay: delay);
    return stream.map((event) => ((event == null) ? null : 0 /* event.meta todo */, event ?? const <int>[]));
  }

  Stream<(Iterable<int> segmentIds, int? respCode, VarReadResponseValues)> readVarsStreamSegmented(VarReadRequestValues ids, {Duration delay = const Duration(milliseconds: 50)}) {
    final stream = periodicRequestSegmented(MotPacketPayloadId.MOT_PACKET_VAR_READ, ids.slices(16), delay: delay);
    return stream.map((event) => (event.$1, (event.$2 == null) ? null : 0, event.$2 ?? const <int>[]));
  }

  Stream<(int? respCode, VarWriteResponseValues)> writeVarsStream(VarWriteRequestValues Function() idValuesGetter, {Duration delay = const Duration(milliseconds: 10)}) {
    assert(idValuesGetter().length <= 8);
    final stream = periodicUpdate(MotPacketPayloadId.MOT_PACKET_VAR_WRITE, idValuesGetter, delay: delay);
    return stream.map((event) => ((event == null) ? null : 0, event ?? const <int>[]));
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Once
  ////////////////////////////////////////////////////////////////////////////////
  Future<(int? respCode, Uint8List data)> readMem(int address, int size, int config) async {
    return await requestResponse(MotPacketPayloadId.MOT_PACKET_MEM_READ, (address, size, config)) ?? (null, Uint8List(0));
  }

  Future<int?> writeMem(int address, int size, int config, Uint8List data) async {
    assert(size == data.lengthInBytes);
    assert(size <= 16);
    assert(data.lengthInBytes <= 16);
    return await requestResponse(MotPacketPayloadId.MOT_PACKET_MEM_WRITE, (address, size, config, data));
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// DataMode
  ////////////////////////////////////////////////////////////////////////////////
  Future<int?> initDataModeWrite((int address, int sizeBytes, int flags) req) async {
    return requestResponse(MotPacketPayloadId.MOT_PACKET_DATA_MODE_WRITE, req, syncOptions: ProtocolSyncOptions.sendAndRecv);
  }

  Future<int?> initDataModeRead((int address, int sizeBytes, int flags) req) async {
    return requestResponse(MotPacketPayloadId.MOT_PACKET_DATA_MODE_READ, req, syncOptions: ProtocolSyncOptions.sendAndRecv);
  }

  Future<void> writeDataModeData(Uint8List data) async => sendRequest(MotPacketPayloadId.MOT_PACKET_DATA_MODE_DATA, data);
  Future<Uint8List?> readDataModeData() async => recvResponse(MotPacketPayloadId.MOT_PACKET_DATA_MODE_DATA);

  //returns  status char
  Future<int?> writeDataMode(int address, int sizeBytes, Uint8List data, [void Function(int bytesComplete)? progressCallback]) async {
    assert(sizeBytes == data.length);
    if (sizeBytes != data.length) return -1;

    final initialResponse = await initDataModeWrite((address, sizeBytes, 0));
    if (initialResponse != 0) return initialResponse;

    // for (var index = 0; index < sizeBytes; index += 32) {
    try {
      for (final (index, entry) in data.slices(32).indexed) {
        await writeDataModeData(Uint8List.fromList(entry));

        if (await recvSync() != MotPacketSyncId.MOT_PACKET_SYNC_ACK) return -1;

        progressCallback?.call(index * 32 + data.length);
      }
    } finally {
      print(sizeBytes);
    }

    return recvResponse(MotPacketPayloadId.MOT_PACKET_DATA_MODE_WRITE)..then((_) => sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK));
  }

  Future<int?> readDataMode(int address, int sizeBytes, Uint8List dataBuffer, [void Function(int bytesComplete)? progressCallback]) async {
    assert(dataBuffer.length >= sizeBytes);

    protocol.mapRequestResponse(MotPacketPayloadId.MOT_PACKET_DATA_MODE_DATA, this); // map additional id

    final initialResponse = await initDataModeRead((address, sizeBytes, 0));
    if (initialResponse != 0) return initialResponse;

    for (var index = 0; index < sizeBytes; index += 32) {
      var data = await readDataModeData();
      if (data == null) return null;
      dataBuffer.setRange(index, index + data.length, data);

      await sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK);
      progressCallback?.call(index + data.length);
    }

    return recvResponse(MotPacketPayloadId.MOT_PACKET_DATA_MODE_READ)..then((_) => sendSync(MotPacketSyncId.MOT_PACKET_SYNC_ACK));
  }
}

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
