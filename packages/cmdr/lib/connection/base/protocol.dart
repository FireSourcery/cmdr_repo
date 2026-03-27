import 'dart:async';

import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';
import 'package:struct_data/packet/packet_transformer.dart';

import 'link.dart';

/// Hold Link, Format, and common state
class Protocol {
  Protocol(this.link, this.packetInterface) : _packetTransformer = packetInterface.transformer;

  final Link link;
  final PacketFormat packetInterface;
  final PacketTransformer _packetTransformer;

  final Map<PacketId, ProtocolSocket> respSocketMap = {}; // map response id to socket, listeners table
  final Lock _lock = Lock();

  StreamSubscription<Packet>? _packetSubscription; // state for is started
  /// begin Socket Rx
  void begin() => _packetSubscription ??= link.streamIn?.transform(_packetTransformer).listen(_demux, onError: _onError);
  void end() => _packetSubscription?.cancel().whenComplete(() => _packetSubscription = null);

  /// central distributor for socket streams
  /// limitations:
  ///     packet responseId matches to single most recent socket, unless it is implemented with socket id
  //      sync ids is passed to all sockets, alternatively 2 levels of keys
  //  if sockets implements listen on the transformed stream,
  //  although the observer pattern is still implemented, the check id routine must run for each socket. but a map would not be necessary.
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
    assert(link.isConnected);
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

  // Future<R?> requestResponse <T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration timeout = reqRespTimeoutDefault}) async {
  //   return await sendRequest(requestId, requestArgs).then((value) async => await recvResponse(requestId, reqStateMeta: value));
  // }

  // Protocol level — the pending requests table
  // final Map<PacketId, Completer<Packet>> _pending = {};

  // Future<Packet> request(Packet outgoing, PacketId responseId) {
  //   final completer = Completer<Packet>();
  //   _pending[responseId /* ??outgoing.packetId.responseId */] = completer;
  //   trySend(outgoing);
  //   return completer.future;
  // }

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
  //   completer = protocol.mapResponse(packetId.responseId ?? packetId, this);
  //   return await completer.timeout(timeout).then((_) => packetBufferIn.parseResponse<V>(packetId, reqStateMeta));
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
      //     if (_queue.isNotEmpty) return _queue.removeFirst();
      //     _signal = Completer<void>();
      //     await _signal!.future.timeout(timeout);
      //     return _queue.removeFirst();
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
      _recvedController.add(null);
    } else {
      throw const ProtocolException('Unexpected Rx');
    }
    //     _queue.add(Uint8List.fromList(bytes));
    //     if (_signal case Completer<void> signal when !signal.isCompleted) {
    //       signal.complete();
    //     }
    //     _signal = null;
  }

  @override
  void close() {
    debugLog('Socket Closed');
  }
  //   final Queue<Uint8List> _queue = Queue<Uint8List>();
  //   Completer<void>? _signal;

  //   bool get hasPending => _queue.isNotEmpty;

  //   void clear() {
  //     _queue.clear();
  //     if (_signal case Completer<void> signal when !signal.isCompleted) {
  //       signal.completeError(const ProtocolException('Mailbox cleared'));
  //     }
  //     _signal = null;
  //   }

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
}

void debugLog(Object? message) {
  assert(() {
    print(message);
    return true;
  }());
}
