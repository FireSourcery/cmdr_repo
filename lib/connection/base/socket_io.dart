import 'dart:io';

import 'package:collection/collection.dart';

import 'packet.dart';
import 'protocol.dart';

// service sockets interfaces
// Alternatively ServiceSockets

// typedef VarReadRequestValues = Iterable<int>;
// typedef VarReadResponseValues = (int respCode, List<int> values);
// // typedef VarReadResponseValues = ({int respCode, List<int> values}); // pref name for typedef?

// typedef VarWriteRequestValues = Iterable<(int id, int value)>;
// typedef VarWriteResponseValues = List<int>; // statuses

// abstract mixin class VarSocketIO implements ProtocolSocket {
// // verbose name to avoid naming collision as a socket can implement many IO mixins
//   PacketIdRequest<VarReadRequestValues, VarReadResponseValues> get readVarsId;
//   PacketIdRequest<VarWriteRequestValues, VarWriteResponseValues> get writeVarsId;

//   Future<VarReadResponseValues?> readVarsBatch(Iterable<int> ids) async => requestResponse(readVarsId, ids);
//   Future<VarWriteResponseValues?> writeVarsBatch(Iterable<(int id, int value)> pairs) async => requestResponse(writeVarsId, pairs);

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Slices
//   ////////////////////////////////////////////////////////////////////////////////
//   /// same input signature, but is not the content sent to the packet
//   Stream<(VarReadRequestValues sliceIds, VarReadResponseValues?)> readVarsSlices(Iterable<int> ids) => iterativeRequest(readVarsId, ids.slices(16));
//   Stream<(VarWriteRequestValues slicePairs, VarWriteResponseValues?)> writeVarsSlices(Iterable<(int id, int value)> ids) => iterativeRequest(writeVarsId, ids.slices(8));

//   // Future<(VarReadRequestValues sliceIds, VarReadResponseValues?)> readVarsSlices1(Iterable<int> ids) => iterativeRequest(readVarsId, ids.slices(16)).reduce(combine);
//   // Future<(VarWriteRequestValues slicePairs, VarWriteResponseValues?)> writeVarsSlices1(Iterable<(int id, int value)> ids) => iterativeRequest(writeVarsId, ids.slices(8));

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Stream
//   ////////////////////////////////////////////////////////////////////////////////
// //   Stream<VarReadResponseValues?> readVarsStream(VarReadRequestValues ids, {Duration delay = const Duration(milliseconds: 50)}) {
// //     assert(ids.length <= VarReadRequest.idCountMax);
// //     return periodicRequest(readVarsId, ids, delay: delay);
// //   }

// //   Stream<(VarReadRequestValues sliceIds, VarReadResponseValues?)> readVarsSlicesStream(Iterable<int> ids, {Duration delay = const Duration(milliseconds: 50)}) {
// //     return periodicIterativeRequest(readVarsId, ids.slices(VarReadRequest.idCountMax), delay: delay);
// //   }

// //   Stream<VarWriteResponseValues?> writeVarsStream(VarWriteRequestValues Function() idValuesGetter, {Duration delay = const Duration(milliseconds: 10)}) {
// //     assert(idValuesGetter().length <= VarWriteRequest.pairCountMax);
// //     return periodicUpdate(writeVarsId, idValuesGetter, delay: delay);
// //   }
// }

// using library interface
// abstract mixin class StringSocketIO implements ProtocolSocket, IOSink {}

// // mixin on id
// abstract mixin class PacketIdRequestCall<T, R> implements PacketIdRequest<T, R> {
//   ProtocolSocket get socket;

//   // Function get _call => socket.requestResponse;

//   Future<R?> call(T request, {Duration? timeout = ProtocolSocket.reqRespTimeoutDefault, ProtocolSyncOptions syncOptions = ProtocolSyncOptions.none}) async {
//     return await socket.requestResponse<T, R>(this, request);
//   }
// }
