import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';
import 'package:binary_data/packet/packet.dart';
import 'package:binary_data/packet/packet_transformer.dart';

import 'link.dart';

class Protocol {
  Protocol(this.link, this.packetInterface) : headerParser = HeaderParser(packetInterface, packetInterface.lengthMax * 4);
  // Protocol(this.link, this.packetInterface) : packetTransformer = PacketTransformer(parserBuffer: HeaderParser(packetInterface, packetInterface.lengthMax * 4));
  // final PacketTransformer packetTransformer;

  final Link link; // optionally mutable for inert state
  final PacketFormat packetInterface;
  final HeaderParser headerParser; // the rx buffer
  final Map<PacketId, ProtocolSocket> respSocketMap = {}; // map response id to socket, listeners table
  final Lock _lock = Lock();

  // Stream<Packet>? packetStream; // state for is started

  /// begin Socket Rx
  StreamSubscription<Packet>? begin() {
    if (!link.isConnected) return null;
    return link.streamIn.transform(PacketTransformer(parserBuffer: headerParser)).listen(_demux, onError: _onError);
  }

  /// central distributor for socket streams
  /// limitations:
  ///     packet responseId matches to single most recent socket, unless it is implemented with socket id
  //  if sockets implements listen on the transformed stream,
  //  although the observer pattern is still implemented,
  //  the check id routine must run for each socket. but a map would not be necessary.
  //  sync ids is passed to all sockets, alternatively 2 levels of keys
  void _demux(Packet packet) {
    debugLog("RX $packet");
    if (respSocketMap[packet.packetId] case ProtocolSocket socket) {
      socket.add(packet);
    } else {
      _onError(const ProtocolException('No matching socket'));
    }
  }

  @protected
  Future<void> trySend(Packet packet) async {
    try {
      debugLog("TX $packet");
      return await link.send(packet.bytes); // lock buffer, or await on blocking function
    } on TimeoutException {
      debugLog("trySend Timeout");
    } catch (e) {
      _onError(e);
    } finally {}
  }

  // socket unique per packetId for now
  // alternatively Map<(PacketId, ProtocolSocket), ProtocolSocket>
  /// `listenResponse` - map responseId to socket
  void mapResponse(PacketId responseId, ProtocolSocket socket) {
    _lock.synchronized(() {
      respSocketMap[responseId] = socket; // update to most recent socket, for responseId, if not implemented with socket id
    });
  }

  // use the same id if responseId is not defined
  void mapRequestResponse(PacketIdRequest requestId, ProtocolSocket socket) {
    mapResponse(requestId.responseId ?? requestId, socket);
  }

  // if sync packet doest not contain socket id in then map all sync ids to socket requesting sync. 1 stateful request active max
  // alternatively send ack to all sockets
  void mapSync(ProtocolSocket socket) {
    _lock.synchronized(() {
      respSocketMap[packetInterface.ack] = socket;
      respSocketMap[packetInterface.nack] = socket;
      respSocketMap[packetInterface.abort] = socket;
    });
  }

  // Protocol level — the pending requests table
  // final Map<PacketId, Completer<Packet>> _pending = {};

  // Future<Packet> request(PacketId id, Packet outgoing, {Duration timeout}) {
  //   final completer = Completer<Packet>();
  //   _pending[id] = completer;
  //   trySend(outgoing);
  //   return completer.future.timeout(timeout).whenComplete(() => _pending.remove(id));
  // }

  // void _demux(Packet packet) {
  //   final completer = _pending.remove(packet.packetId);
  //   if (completer != null) {
  //     completer.complete(packet);  // data flows through the completer
  //   }
  // }

  void _onError(Object error) {
    switch (error) {
      case ProtocolException():
      // handleProtocolException(error);
      case PacketStatusException.checksum:
      case PacketStatusException.meta:
      // link.flushInput();
      case TimeoutException():
        debugLog("Protocol Timeout");
      case Exception():
        debugLog("Protocol Unnamed Exception");
        debugLog(error);
      // case LinkException():
      //   debugLog(error.message);
      default:
        debugLog(error);
    }
  }
}

// a thread of messaging with buffers
class ProtocolSocket implements Sink<Packet> {
  ProtocolSocket._(this.protocol, this.packetBufferIn, this.packetBufferOut);
  ProtocolSocket(this.protocol) : packetBufferIn = PacketBuffer(protocol.packetInterface), packetBufferOut = PacketBuffer(protocol.packetInterface);

  @protected
  final Protocol protocol; // optionally make this mutable
  @protected
  final PacketBuffer packetBufferIn; // alternatively implement lock on buffers
  @protected
  final PacketBuffer packetBufferOut;

  PacketFormat get packetInterface => protocol.packetInterface;

  final Lock _lock = Lock();
  // Completer<Packet> _recved = Completer.sync();
  final StreamController<void> _recvedController = StreamController<void>.broadcast(sync: true);
  Stream<void> get _recved => _recvedController.stream;

  int waitingOnLockCount = 0;
  // ProtocolException status = ProtocolException.ok; // use eventSink

  final Stopwatch timer = Stopwatch()..start();

  //
  static const Duration timeoutDefault = Duration(milliseconds: 500);
  static const Duration rxTimeoutDefault = Duration(milliseconds: 500);
  static const Duration reqRespTimeoutDefault = Duration(milliseconds: 1000);
  static const Duration datagramDelay = Duration(milliseconds: 1);

  /// async function maintains state
  /// locks buffer
  /// returns null on Exception, may occur before reaching parse
  ///
  /// return results as view of packet buffer passed in => no double buffer or memory allocation
  /// receiving buffer unlocks, values returned as view of buffer. caller ensure they are processed, before calling request again.
  ///
  /// Arguments in values, or struct + meta
  /// R - Response Payload Values
  /// T - Request Payload Values
  ///
  /// Caller ensure connection is available
  Future<R?> requestResponse<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration timeout = reqRespTimeoutDefault, ProtocolSyncOptions? syncOptions}) async {
    waitingOnLockCount++;
    try {
      return await _lock.synchronized<R?>(
        () async {
          debugLog('');
          debugLog('--- New Request');
          debugLog('Socket [$hashCode] Request [$requestId] | waiting on lock [$waitingOnLockCount]');

          if (syncOptions != null) {
            return await _requestResponseOptions<T, R>(requestId, requestArgs, syncOptions: syncOptions, timeout: timeout);
          } else {
            return await _requestResponseShort<T, R>(requestId, requestArgs, timeout: timeout);
          }
        },
        timeout: timeout,
      );
    } on TimeoutException catch (e) {
      debugLog(e);
      return null;
    } catch (e) {
      debugLog(e);
      return null;
    } finally {
      debugLog("Socket [$hashCode] Time: ${timer.elapsedMilliseconds}");
      debugLog('--- End Request');
      waitingOnLockCount--;
    }
    // return null;
  }

  // Future<R?> _requestResponse<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration timeout = reqRespTimeoutDefault, ProtocolSyncOptions? syncOptions}) async {
  //    }

  /// requestResponse with options
  Future<R?> _requestResponseOptions<T, R>(
    PacketIdRequest<T, R> requestId,
    T requestArgs, {
    ProtocolSyncOptions syncOptions = ProtocolSyncOptions.none,
    Duration timeout = reqRespTimeoutDefault,
  }) async {
    if (syncOptions.recvSync) protocol.mapSync(this); // map sync before sending request

    final PayloadMeta requestMeta = await sendRequest(requestId, requestArgs); //alternatively without waiting

    if (syncOptions.recvSync) {
      if (await recvSync(timeout) != packetInterface.ack) return null;
      // todo handle case of rx nack
      // if (await recvSync() case PacketSyncId? id when id != packetInterface.ack)  return Future.error(id ?? TimeoutException());
    }

    final R? response = await recvResponse(requestId, reqStateMeta: requestMeta, timeout: timeout);

    if (response == null) return null;

    if (syncOptions.sendSync) await sendSync(packetInterface.ack);
    return response;
  }

  /// without options
  Future<R?> _requestResponseShort<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration timeout = reqRespTimeoutDefault}) async {
    return await sendRequest(requestId, requestArgs).then((value) async => await recvResponse(requestId, reqStateMeta: value));
  }

  /// handle build and send using request side of packet
  // call lock. buffers must lock, if sockets are shared, i.e not uniquely allocated per thread
  // alternatively lock out buffer only
  @protected
  Future<PayloadMeta> sendRequest<V>(PacketIdRequest<V, dynamic> packetId, V requestArgs) async {
    protocol.mapRequestResponse(packetId, this); // request always paired with response, so map here
    packetBufferIn.clear();

    final PayloadMeta requestMeta = packetBufferOut.buildRequest<V>(packetId, requestArgs);
    timer.start();
    timer.reset();
    await protocol.trySend(packetBufferOut.viewAsPacket);
    return requestMeta;
  }

  /// using response side
  @protected
  Future<V?> recvResponse<V>(PacketIdRequest<dynamic, V> packetId, {PayloadMeta? reqStateMeta, Duration timeout = rxTimeoutDefault}) async {
    return await tryRecv<V>(() => packetBufferIn.parseResponse<V>(packetId, reqStateMeta), timeout);
  }

  ///
  Future<PacketSyncId?> ping(covariant PacketSyncId id, [covariant PacketSyncId? respId, Duration timeout = timeoutDefault]) async {
    protocol.mapResponse(respId ?? id, this);
    return sendSync(id).then((_) async => await recvSync(timeout));
  }

  /// respondSync
  @protected
  Future<void> sendSync(PacketSyncId syncId) {
    packetBufferOut.buildSync(syncId);
    return protocol.trySend(packetBufferOut.viewAsPacket);
  }

  @protected
  Future<PacketSyncId?> recvSync([Duration timeout = rxTimeoutDefault]) {
    return tryRecv<PacketSyncId>(() => packetBufferIn.parseSyncId(), timeout);
  }

  // Future<void> sendBytes(Uint8List bytes, {PacketId? id, Duration timeout = timeoutDefault}) async {
  //   // protocol.mapRequestResponse(packetId, this);
  //   packetBufferOut.copy(bytes);
  //   await protocol.trySend(packetBufferOut.viewAsPacket);
  // }

  // Uint8List recvBytes(int bytes, {int timeout = -1}) {
  //   // await tryRecv<Uint8List>(() => packetBufferIn.viewAsBytes, Duration(milliseconds: timeout < 0 ? rxTimeoutDefault.inMilliseconds : timeout));
  //   // return packetBufferIn.viewAsBytes;
  // }

  // host side initiated wait
  // Future<V?> expectResponse<V>(PacketIdRequest<dynamic, V> packetId, {PayloadMeta? reqStateMeta, Duration timeout = timeoutDefault}) async {
  //   protocol.mapResponse(packetId.responseId ?? packetId, this);
  //   return recvResponse<V>(packetId, reqStateMeta: reqStateMeta, timeout: timeoutDefault);
  // }

  // Future<PacketSyncId?> expectSync([Duration timeout = timeoutDefault]) {
  //   protocol.mapSync(this);
  //   return recvSync(timeout);
  // }

  // using sync completer to execute parse immediately, although code it is not the final computation.
  @protected
  Future<R?> tryRecv<R>(R? Function() parse, [Duration timeout = rxTimeoutDefault]) async {
    try {
      return await _recved.first.timeout(timeout).then((_) => parse());
    } on TimeoutException {
      debugLog("Socket Recv Response Timeout");
      rethrow;
    } on ProtocolException catch (e) {
      //should be handled by protocol
      debugLog("Unhandled ProtocolException on Socket");
      debugLog(e.message);
    } catch (e) {
      debugLog("ProtocolSocket Exception");
      debugLog(e);
      debugLog(packetBufferIn.viewAsBytes);
      // payload parser may throw if invalid packet passes header parser as valid
    } finally {}
    return null;
  }

  // pass Packet pointer, ephemeral, full packet view of shared buffer.
  @override
  void add(Packet event) {
    timer.stop();
    packetBufferIn.copy(event.bytes); // sets buffer length to packet length, [PacketTransformer] handles max buffer length
    // socket table does not unmap. might receive packets following completion
    if (!_recvedController.isClosed) {
      // if(event.packetId != )
      _recvedController.add(null);
    } else {
      throw const ProtocolException('Unexpected Rx');
    }
  }

  @override
  void close() {
    debugLog('Socket Closed');
  }

  /// Must return as stream, so callback can run following each response. This way eliminates additional buffering.
  /// Reducing to Iterable would direct each element to the same packet buffer.
  Stream<(T segmentArgs, R? segmentResponse)> iterativeRequest<T, R>(PacketIdRequest<T, R> requestId, Iterable<T> requestSlices, {Duration delay = datagramDelay}) async* {
    for (final segmentArgs in requestSlices) {
      yield (segmentArgs, await requestResponse<T, R>(requestId, segmentArgs));
      await Future.delayed(delay);
    }
  }

  /// extension
  Stream<R?> periodicRequest<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration delay = datagramDelay}) async* {
    while (true) {
      yield await requestResponse<T, R>(requestId, requestArgs);
      await Future.delayed(delay); // todo as byte time
    }
  }

  Stream<(T segmentArgs, R? segmentResponse)> periodicIterativeRequest<T, R>(PacketIdRequest<T, R> requestId, Iterable<T> requestSlices, {Duration delay = datagramDelay}) async* {
    while (true) {
      yield* iterativeRequest<T, R>(requestId, requestSlices, delay: delay);
    }
  }

  /// periodic Response/Write
  Stream<R?> periodicUpdate<T, R>(PacketIdRequest<T, R> requestId, T Function() requestArgsGetter, {Duration delay = datagramDelay}) async* {
    while (true) {
      yield await requestResponse<T, R>(requestId, requestArgsGetter());
      await Future.delayed(delay); // todo as byte time
    }
  }
}

enum ProtocolSyncOptions {
  none,
  sendOnly,
  recvOnly,
  sendAndRecv;

  bool get sendSync => switch (this) {
    none => false,
    sendOnly => true,
    recvOnly => false,
    sendAndRecv => true,
  };
  bool get recvSync => switch (this) {
    none => false,
    sendOnly => false,
    recvOnly => true,
    sendAndRecv => true,
  };
}

class ProtocolException implements Exception {
  const ProtocolException([this.message = "Undefined Protocol Exception", this.socketId]);
  final String message;
  final int? socketId;
  // static const ProtocolException meta = ProtocolException('Error Response Meta');
  // static const ProtocolException id = ProtocolException('Error Response Id Invalid');
  // static const ProtocolException checksum = ProtocolException('Error Response Checksum');
  static const ProtocolException noConnect = ProtocolException('No Connect');
  static const ProtocolException errorInit = ProtocolException('Init Fail');
  static const ProtocolException ok = ProtocolException('Ok');
  static const ProtocolException link = ProtocolException(' ');
}

// alternatively
// request formats, match in this layer, provides more than one pairing than packet id
// abstract interface class ProtocolRequestPair<T, R> {
//   PacketIdPayload<T>? get requestId;
//   PacketIdPayload<R>? get responseId;
// }
void debugLog(Object? message) {
  assert(() {
    print(message);
    return true;
  }());
}

// ////////////////////////////////////////////////////////////////////////////////
// /// Conventional Transaction-Based Protocol (Modbus-style)
// ///
// /// Key differences from [Protocol]/[ProtocolSocket]:
// ///   - Data flows through async mechanism (mailbox queue), not shared mutable buffer
// ///   - No recv buffer overwrite race — each packet is copied and queued
// ///   - No lock needed for recv serialization — queue provides ordering
// ///   - Lock only serializes send-side (packetBufferOut) when concurrent callers share a socket
// ///   - Handles repeated recv (data mode streams) naturally via sequential queue consumption
// ////////////////////////////////////////////////////////////////////////////////

// /// Async packet queue — buffers received packets for sequential consumption.
// ///
// /// Replaces both the broadcast StreamController notification and the shared
// /// packetBufferIn. Each delivered packet is an owned copy, not a view of a
// /// shared buffer.
// class PacketMailbox {
//   final Queue<Uint8List> _queue = Queue<Uint8List>();
//   Completer<void>? _signal;

//   /// Producer side — called by protocol dispatcher.
//   /// Copies bytes so the mailbox owns the data.
//   void deliver(Uint8List bytes) {
//     _queue.add(Uint8List.fromList(bytes));
//     if (_signal case Completer<void> signal when !signal.isCompleted) {
//       signal.complete();
//     }
//     _signal = null;
//   }

//   /// Consumer side — blocks until a packet is available or timeout.
//   /// Returns owned bytes, safe to hold across await boundaries.
//   Future<Uint8List> recv([Duration timeout = const Duration(milliseconds: 500)]) async {
//     if (_queue.isNotEmpty) return _queue.removeFirst();
//     _signal = Completer<void>();
//     await _signal!.future.timeout(timeout);
//     return _queue.removeFirst();
//   }

//   /// Non-blocking check
//   bool get hasPending => _queue.isNotEmpty;

//   void clear() {
//     _queue.clear();
//     if (_signal case Completer<void> signal when !signal.isCompleted) {
//       signal.completeError(const ProtocolException('Mailbox cleared'));
//     }
//     _signal = null;
//   }
// }

// /// Transaction-based protocol dispatcher.
// ///
// /// Routes incoming packets to registered [PacketMailbox] instances by packet ID.
// /// Multiple IDs can map to the same mailbox (e.g., sync IDs for a single socket).
// class TransactionProtocol {
//   TransactionProtocol(this.link, this.packetInterface)
//       : headerParser = HeaderParser(packetInterface, packetInterface.lengthMax * 4);

//   final Link link;
//   final PacketFormat packetInterface;
//   final HeaderParser headerParser;

//   /// ID → mailbox routing table. Multiple IDs may share one mailbox.
//   final Map<PacketId, PacketMailbox> _routes = {};

//   StreamSubscription<Packet>? begin() {
//     if (!link.isConnected) return null;
//     return link.streamIn.transform(PacketTransformer(parserBuffer: headerParser)).listen(_dispatch, onError: _onError);
//   }

//   /// Route received packet to the registered mailbox.
//   void _dispatch(Packet packet) {
//     debugLog("RX $packet");
//     if (_routes[packet.packetId] case PacketMailbox mailbox) {
//       mailbox.deliver(packet.bytes);
//     } else {
//       _onError(const ProtocolException('No matching mailbox'));
//     }
//   }

//   Future<void> trySend(Packet packet) async {
//     try {
//       debugLog("TX $packet");
//       return await link.send(packet.bytes);
//     } on TimeoutException {
//       debugLog("trySend Timeout");
//     } catch (e) {
//       _onError(e);
//     }
//   }

//   /// Register a mailbox to receive packets for [id].
//   void route(PacketId id, PacketMailbox mailbox) => _routes[id] = mailbox;

//   /// Route request ID and its response ID to the same mailbox.
//   void routeRequestResponse(PacketIdRequest requestId, PacketMailbox mailbox) {
//     _routes[requestId.responseId ?? requestId] = mailbox;
//   }

//   /// Route all sync IDs (ack/nack/abort) to a mailbox.
//   void routeSync(PacketMailbox mailbox) {
//     _routes[packetInterface.ack] = mailbox;
//     _routes[packetInterface.nack] = mailbox;
//     _routes[packetInterface.abort] = mailbox;
//   }

//   void unroute(PacketId id) => _routes.remove(id);

//   void _onError(Object error) {
//     switch (error) {
//       case ProtocolException():
//       case TimeoutException():
//         debugLog("TransactionProtocol: $error");
//       default:
//         debugLog(error);
//     }
//   }
// }

// /// Transaction socket — conventional Modbus-style request/response handler.
// ///
// /// Each recv returns data from the mailbox queue, not a shared buffer.
// /// No lock needed for recv ordering. Send-side lock serializes transactions
// /// that share this socket's [packetBufferOut].
// class TransactionSocket {
//   TransactionSocket(this.protocol)
//       : packetBufferOut = PacketBuffer(protocol.packetInterface);

//   @protected
//   final TransactionProtocol protocol;
//   @protected
//   final PacketBuffer packetBufferOut;

//   /// Per-socket mailbox — all responses routed here are queued for sequential consumption.
//   final PacketMailbox mailbox = PacketMailbox();

//   PacketFormat get packetInterface => protocol.packetInterface;

//   final Lock _sendLock = Lock();
//   final Stopwatch timer = Stopwatch()..start();

//   static const Duration timeoutDefault = Duration(milliseconds: 500);
//   static const Duration reqRespTimeoutDefault = Duration(milliseconds: 1000);
//   static const Duration datagramDelay = Duration(milliseconds: 1);

//   /// Core request/response — serializes entire transaction.
//   ///
//   /// Lock protects packetBufferOut and ensures transaction ordering.
//   /// Recv side needs no lock — mailbox queue provides ordering.
//   Future<R?> requestResponse<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration timeout = reqRespTimeoutDefault, ProtocolSyncOptions? syncOptions}) async {
//     try {
//       return await _sendLock.synchronized<R?>(
//         () async {
//           debugLog('');
//           debugLog('--- New Transaction');

//           if (syncOptions != null) {
//             return await _requestResponseSync<T, R>(requestId, requestArgs, syncOptions: syncOptions, timeout: timeout);
//           } else {
//             return await _requestResponseSimple<T, R>(requestId, requestArgs, timeout: timeout);
//           }
//         },
//         timeout: timeout,
//       );
//     } on TimeoutException {
//       return null;
//     } catch (e) {
//       debugLog(e);
//       return null;
//     } finally {
//       debugLog('--- End Transaction');
//     }
//   }

//   /// Simple request/response — send, then recv one packet.
//   Future<R?> _requestResponseSimple<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration timeout = reqRespTimeoutDefault}) async {
//     final PayloadMeta requestMeta = _sendRequest(requestId, requestArgs);
//     await protocol.trySend(packetBufferOut.viewAsPacket);
//     return await _recvResponse<R>(requestId, reqStateMeta: requestMeta, timeout: timeout);
//   }

//   /// Request/response with sync handshake.
//   Future<R?> _requestResponseSync<T, R>(
//     PacketIdRequest<T, R> requestId,
//     T requestArgs, {
//     ProtocolSyncOptions syncOptions = ProtocolSyncOptions.none,
//     Duration timeout = reqRespTimeoutDefault,
//   }) async {
//     if (syncOptions.recvSync) protocol.routeSync(mailbox);

//     final PayloadMeta requestMeta = _sendRequest(requestId, requestArgs);
//     timer
//       ..start()
//       ..reset();
//     await protocol.trySend(packetBufferOut.viewAsPacket);

//     if (syncOptions.recvSync) {
//       if (await _recvSync(timeout) != packetInterface.ack) return null;
//     }

//     final R? response = await _recvResponse(requestId, reqStateMeta: requestMeta, timeout: timeout);

//     if (response == null) return null;

//     if (syncOptions.sendSync) await _sendSync(packetInterface.ack);
//     return response;
//   }

//   /// Build request into packetBufferOut and register response routing.
//   PayloadMeta _sendRequest<V>(PacketIdRequest<V, dynamic> packetId, V requestArgs) {
//     protocol.routeRequestResponse(packetId, mailbox);
//     mailbox.clear(); // clear stale packets before new transaction
//     return packetBufferOut.buildRequest<V>(packetId, requestArgs);
//   }

//   /// Recv a response packet from the mailbox, parse as response type.
//   /// Data is owned by the mailbox entry — no shared buffer.
//   @protected
//   Future<V?> _recvResponse<V>(PacketIdRequest<dynamic, V> packetId, {PayloadMeta? reqStateMeta, Duration timeout = timeoutDefault}) async {
//     return _tryRecv<V>((packet) => packet.parseResponse<V>(packetId, reqStateMeta), timeout);
//   }

//   /// Recv a sync packet from the mailbox.
//   @protected
//   Future<PacketSyncId?> _recvSync([Duration timeout = timeoutDefault]) {
//     return _tryRecv<PacketSyncId>((packet) => packet.parseSyncId(), timeout);
//   }

//   /// Build and send a sync packet.
//   @protected
//   Future<void> _sendSync(PacketSyncId syncId) {
//     packetBufferOut.buildSync(syncId);
//     return protocol.trySend(packetBufferOut.viewAsPacket);
//   }

//   /// Receive next packet from mailbox, cast, and parse.
//   ///
//   /// [parse] receives an owned [Packet] — not a shared buffer view.
//   /// Safe across await boundaries and repeated calls.
//   @protected
//   Future<R?> _tryRecv<R>(R? Function(Packet packet) parse, [Duration timeout = timeoutDefault]) async {
//     try {
//       final bytes = await mailbox.recv(timeout);
//       final packet = packetInterface.cast(bytes);
//       debugLog('Mailbox recv: $packet');
//       return parse(packet);
//     } on TimeoutException {
//       debugLog("Mailbox recv timeout");
//       rethrow;
//     } on ProtocolException catch (e) {
//       debugLog("ProtocolException: ${e.message}");
//     } catch (e) {
//       debugLog("TransactionSocket Exception: $e");
//     }
//     return null;
//   }

//   /// Ping — send sync, recv sync response.
//   Future<PacketSyncId?> ping(covariant PacketSyncId id, [covariant PacketSyncId? respId, Duration timeout = timeoutDefault]) async {
//     protocol.route(respId ?? id, mailbox);
//     await _sendSync(id);
//     return _recvSync(timeout);
//   }

//   /// Iterative request stream — sequential request/response for each slice.
//   /// Each iteration through the mailbox queue, no buffer overwrite between iterations.
//   Stream<(T segmentArgs, R? segmentResponse)> iterativeRequest<T, R>(PacketIdRequest<T, R> requestId, Iterable<T> requestSlices, {Duration delay = datagramDelay}) async* {
//     for (final segmentArgs in requestSlices) {
//       yield (segmentArgs, await requestResponse<T, R>(requestId, segmentArgs));
//       await Future.delayed(delay);
//     }
//   }

//   Stream<R?> periodicRequest<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration delay = datagramDelay}) async* {
//     while (true) {
//       yield await requestResponse<T, R>(requestId, requestArgs);
//       await Future.delayed(delay);
//     }
//   }
// }
