import 'dart:async';

import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';
import 'package:binary_data/models/packet.dart';

import 'link.dart';
import 'packet_transformer.dart';

class Protocol {
  Protocol(this.link, this.packetInterface) : headerParser = HeaderParser(packetInterface, packetInterface.lengthMax * 4);

  final Link link; // optionally mutable for inert state
  final PacketClass packetInterface;
  final HeaderParser headerParser;
  final Map<PacketId, ProtocolSocket> respSocketMap = {}; // map response id to socket, listeners
  final Lock _lock = Lock();

  ProtocolException status = ProtocolException.ok;
  Stream<Packet>? packetStream; // rx complete packets, pre sockets

  /// begin Socket Rx

  StreamSubscription<Packet>? begin() {
    if (!link.isConnected) return null;
    if (packetStream != null) return null; // return if already set, alternatively listen on single subscription stream terminates, todo reset function

    packetStream = link.streamIn.transform(PacketTransformer(parserBuffer: headerParser)); // creates a new stream, if streamIn is a getter
    return packetStream!.listen(_demux, onError: onError);
    // status = ProtocolException.ok;
  }

  /// central distributor for socket streams
  /// limitations:
  ///     packet responseId matches to single most recent socket, unless it is implemented with socket id
  //  if sockets implements listen on the transformed stream,
  //  although the observer pattern is still implemented,
  //  the check id routine must run for each socket. but a map would not be necessary.
  //  sync ids is passed to all sockets, alternatively 2 levels of keys
  void _demux(Packet packet) {
    print("RX ${packet.bytes.take(4)} ${packet.bytes.skip(4).take(4)} ${packet.bytes.skip(8)}");
    if (respSocketMap[packet.packetId] case ProtocolSocket socket) {
      socket.add(packet);
      print("Socket [${socket.hashCode}] Time: ${socket.timer.elapsedMilliseconds}");
    } else {
      handleProtocolException(const ProtocolException('No matching socket'));
    }
  }

  Future<void> trySend(Packet packet) async {
    try {
      print("TX ${packet.bytes.take(4)} ${packet.bytes.skip(4).take(4)} ${packet.bytes.skip(8)}");
      return await link.send(packet.bytes); // lock buffer, or await on blocking function
    } on TimeoutException {
      print("Link Tx Timeout");
    } catch (e) {
      // todo fix null check
      onError(e);
    } finally {}
  }

  // socket unique per packetId for now
  // alternatively Map<(PacketId, ProtocolSocket), ProtocolSocket>
  void mapResponse(PacketId responseId, ProtocolSocket socket) {
    _lock.synchronized(() {
      respSocketMap.putIfAbsent(responseId, () => socket);
    });
  }

  // if sync packet doest not contain socket id in then map all sync ids to socket requesting sync. 1 stateful request active max
  // alternatively send ack to all sockets
  void mapSync(ProtocolSocket socket) {
    _lock.synchronized(() {
      respSocketMap.putIfAbsent(packetInterface.ack, () => socket);
      respSocketMap.putIfAbsent(packetInterface.nack, () => socket);
      respSocketMap.putIfAbsent(packetInterface.abort, () => socket);
    });
  }

  void mapRequestResponse(PacketIdRequest requestId, ProtocolSocket socket) {
    mapResponse(requestId.responseId ?? requestId, socket);
  }

  // couple map then send?
  // Future<void> requestResponse(PacketIdRequest requestId, ProtocolSocket socket) {
  //   mapResponse(requestId.responseId ?? requestId, socket);
  //   return trySend(socket.packetBufferOut.viewAsPacket);
  // }

  @protected
  void handleProtocolException(ProtocolException exception) {
    status = exception;
    print(exception.message);
    switch (exception) {
      case ProtocolException.meta || ProtocolException.id:
      // link.flushInput();
      case ProtocolException.checksum:
      default:
    }
  }

  @protected
  void onError(Object error) {
    switch (error) {
      case ProtocolException():
        handleProtocolException(error);
      case TimeoutException():
        print("Protocol Timeout");
      case Exception():
        print("Protocol Unnamed Exception");
        print(error);
      // case LinkException():
      //   print(error.message);
      default:
        print(error);
    }
  }
}

// a thread of messaging with buffers
class ProtocolSocket implements Sink<Packet> {
  ProtocolSocket._(this.protocol, this.packetBufferIn, this.packetBufferOut);
  ProtocolSocket(this.protocol) : packetBufferIn = PacketBuffer(protocol.packetInterface), packetBufferOut = PacketBuffer(protocol.packetInterface);

  @protected
  final Protocol protocol;
  @protected
  final PacketBuffer packetBufferIn; // alternatively implement lock on buffers
  @protected
  final PacketBuffer packetBufferOut;

  final Lock _lock = Lock();
  Completer<void> _recved = Completer.sync();

  int waitingOnLockCount = 0;

  // ProtocolException status = ProtocolException.ok; // todo with eventSink

  final Stopwatch timer = Stopwatch()..start();

  static const Duration timeoutDefault = Duration(milliseconds: 500);
  static const Duration rxTimeoutDefault = Duration(milliseconds: 500);
  static const Duration reqRespTimeoutDefault = Duration(milliseconds: 1000);
  static const Duration datagramDelay = Duration(milliseconds: 1);

  PacketClass get packetInterface => protocol.packetInterface;

  /// async function maintains state
  /// locks buffer, packet buildPayload function must be defined with override to include during lock
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
  Future<R?> requestResponse<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration timeout = reqRespTimeoutDefault, ProtocolSyncOptions syncOptions = ProtocolSyncOptions.none}) async {
    waitingOnLockCount++;
    try {
      return await _lock.synchronized<R?>(() async {
        print('');
        print('--- New Request');
        print('Socket [$hashCode] Request [$requestId] | waiting on lock [$waitingOnLockCount]');
        packetBufferIn.clear();

        _recved = Completer.sync();
        if (syncOptions.recvSync) protocol.mapSync(this); // map sync before sending request
        protocol.mapRequestResponse(requestId, this); //move to send request?

        final PayloadMeta requestMeta = await sendRequest(requestId, requestArgs); //alternatively without waiting

        if (syncOptions.recvSync) {
          if (await recvSync(timeout) != packetInterface.ack) return null; // handle nack?
          // if (await recvSync() case PacketSyncId? id when id != packetInterface.ack) {
          //   return Future.error(id ?? TimeoutException());
          // }
        }
        final R? response = await recvResponse(requestId, reqStateMeta: requestMeta, timeout: timeout);

        if (response == null) return null;

        if (syncOptions.sendSync) await sendSync(packetInterface.ack);
        return response;
      }, timeout: timeout);
    } on TimeoutException catch (e) {
      print("Socket lock requestResponse Timeout");
      print(e);
      // return Future.error(e);
      return null;
    } catch (e) {
      print("Unhandled Socket Exception");
      print(e);
      return null;
    } finally {
      print('--- End Request');
      waitingOnLockCount--;
    }
    // return null;
  }

  // without options
  Future<R?> requestResponseShort<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration? timeout = reqRespTimeoutDefault}) async {
    try {
      return await _lock.synchronized<R?>(() async {
        packetBufferIn.clear();
        protocol.mapRequestResponse(requestId, this); //move to send request?
        return await sendRequest(requestId, requestArgs).then((value) async => await recvResponse(requestId, reqStateMeta: value));
      }, timeout: timeout);
    } on TimeoutException {
    } catch (e) {
    } finally {}
    return null;
  }

  Future<PacketSyncId?> ping(covariant PacketSyncId id, [covariant PacketSyncId? respId, Duration timeout = timeoutDefault]) async {
    protocol.mapResponse(respId ?? id, this);
    return sendSync(id).then((_) async => await recvSync(timeout));
  }

  // Future<void> sendRaw(Uint8List bytes, {Duration timeout = timeoutDefault}) async {}
  // Uint8List recvRaw(int bytes, {int timeout = -1})

  /// handle build and, send using request side of packet, response maybe of a different Id, e.g. Sync
  // todo add lock on component functions?
  // buffers must lock, if sockets are shared, i.g not uniquely allocated per thread
  @protected
  Future<PayloadMeta> sendRequest<V>(PacketIdRequest<V, dynamic> packetId, V requestArgs) async {
    final PayloadMeta requestMeta = packetBufferOut.buildRequest<V>(packetId, requestArgs);
    timer.reset();
    timer.start();
    // protocol.mapRequestResponse(packetId, this);
    await protocol.trySend(packetBufferOut.viewAsPacket);
    return requestMeta;
  }

  // @protected
  // Future<PayloadMeta> send<V>(PacketPayloadId<V> packetId, V requestArgs) async {
  //   final PayloadMeta requestMeta = packetBufferOut.buildRequest<V>(packetId, requestArgs);
  //   timer.reset();
  //   timer.start();
  //   await protocol.trySend(packetBufferOut.viewAsPacket);
  //   return requestMeta;
  // }

  /// using response side
  @protected
  Future<V?> recvResponse<V>(PacketIdRequest<dynamic, V> packetId, {PayloadMeta? reqStateMeta, Duration timeout = rxTimeoutDefault}) async {
    //todo handle case of rx nack
    return await tryRecv<V>(() => packetBufferIn.parseResponse<V>(packetId, reqStateMeta), timeout);
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

  // host side initiated wait
  // @protected
  // Future<V?> expectResponse<V>(PacketIdRequest<dynamic, V> packetId, {PayloadMeta? reqStateMeta, Duration timeout = timeoutDefault}) async {
  //   protocol.mapResponse(packetId.responseId ?? packetId, this);
  //   return recvResponse<V>(packetId, reqStateMeta: reqStateMeta, timeout: timeoutDefault);
  // }

  // @protected
  // Future<PacketIdSync?> expectSync([Duration timeout = timeoutDefault]) {
  //   protocol.mapSync(this);
  //   return recvSync(timeout);
  // }

  // using sync completer to execute parse immediately, although code it is not the final computation.
  // lock receiving side only?
  @protected
  Future<R?> tryRecv<R>(R? Function() parse, [Duration timeout = rxTimeoutDefault]) async {
    try {
      // await stream.first.timeout(timeout);
      return await _recved.future.timeout(timeout).then((_) => parse());
    } on TimeoutException {
      print("Socket Recv Response Timeout");
      // } on ProtocolException catch (e) {
      //   //should be handled by protocol
      //   print("Unhandled ProtocolException on Socket");
      //   print(e.message);
      // } on LinkStatus catch (e) {
      //   print(e.message);
      // } on Exception catch (e) {
      //   print("Protocol Unnamed Exception");
      //   print(e);
      // } on RangeError catch (e) {
      //   print(packetBufferIn.viewAsBytes);
      //   print("Protocol Parser Failed");
      //   print(e);
      //   return parse();
      /// todo
    } catch (e) {
      print(e);
      // payload parser may throw if invalid packet passes header parser as valid
    } finally {
      // mark input as empty
      _recved = Completer.sync(); // sync completer call parse as soon as complete is called
    }
    return null;
  }

  // pass Packet pointer, ephemeral, full packet view of shared buffer.
  @override
  void add(Packet event) {
    timer.stop();

    packetBufferIn.copy(event.bytes); // sets buffer length to packet length, [PacketTransformer] handles max buffer length
    // socket table does not unmap. might receive packets following completion
    if (!_recved.isCompleted) {
      _recved.complete();
    } else {
      throw const ProtocolException('Unexpected Rx');
    }
  }

  @override
  void close() {
    print('Socket closed');
  }

  /// Must return as stream, so callback can run following each response. This way eliminates additional buffering. Reducing to Iterable would direct each element to the same packet buffer.
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

  // @visibleForTesting
  // Stream<(Iterable<int> segmentIds, int? respCode, List<int> values)> streamDebug(Iterable<int> segmentIds) {
  //   Stopwatch debugStopwatch = Stopwatch()..start();
  //   final stream = periodicRequest(id, segmentIds, delay: const Duration(milliseconds: 5));
  //   return stream.map((event) => (event.$1, 0, <int>[for (var i = 0; i < event.$1.length; i++) ((debugStopwatch.elapsedMilliseconds / 1000) * 32767).toInt()]));
  //   //  (cos(debugStopwatch.elapsedMilliseconds / 1000) * 32767).toInt(),
  // }
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
  static const ProtocolException meta = ProtocolException('Error Response Meta');
  static const ProtocolException id = ProtocolException('Error Response Id Invalid');
  static const ProtocolException checksum = ProtocolException('Error Response Checksum');
  static const ProtocolException noConnect = ProtocolException('No Connect');
  static const ProtocolException errorInit = ProtocolException('Init Fail');
  static const ProtocolException ok = ProtocolException('Ok');
  static const ProtocolException link = ProtocolException(' ');
}

// request formats, match in this layer, provides more than one pairing than packet id
// alternatively
// abstract interface class ProtocolRequest<T, R> {
//   PacketIdPayload<T>? get requestId;
//   PacketIdPayload<R>? get responseId;
// }
// pre connected
// class ProtocolSocketInert implements ProtocolSocket {
//   ProtocolSocketInert(this.protocol) : packetBufferIn = PacketBuffer(protocol.packetInterface), packetBufferOut = PacketBuffer(protocol.packetInterface);

//   @override
//   final Protocol protocol;
//   @override
//   final PacketBuffer packetBufferIn;
//   @override
//   final PacketBuffer packetBufferOut;

//   @override
//   void add(Packet event) {
//     // do nothing, inert socket
//   }

//   @override
//   void close() {
//     // do nothing, inert socket
//   }

//   @override
//   Stopwatch timer;

//   @override
//   int waitingOnLockCount;

//   @override
//   Stream  iterativeRequest<T, R>(PacketIdRequest<T, R> requestId, Iterable<T> requestSlices, {Duration delay = datagramDelay}) {

//   }

//   @override
//   PacketClass<Packet> get packetInterface => throw UnimplementedError();

//   @override
//   Stream<(, )> periodicIterativeRequest<T, R>(PacketIdRequest<T, R> requestId, Iterable<T> requestSlices, {Duration delay = datagramDelay}) {
//     // TODO: implement periodicIterativeRequest
//     throw UnimplementedError();
//   }

//   @override
//   Stream<R?> periodicRequest<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration delay = datagramDelay}) {
//     // TODO: implement periodicRequest
//     throw UnimplementedError();
//   }

//   @override
//   Stream<R?> periodicUpdate<T, R>(PacketIdRequest<T, R> requestId, T Function() requestArgsGetter, {Duration delay = datagramDelay}) {
//     // TODO: implement periodicUpdate
//     throw UnimplementedError();
//   }

//   @override
//   Future<PacketSyncId?> ping(covariant PacketSyncId id, [covariant PacketSyncId? respId, Duration timeout = timeoutDefault]) {
//     // TODO: implement ping
//     throw UnimplementedError();
//   }

//   @override
//   Future<V?> recvResponse<V>(PacketIdRequest<dynamic, V> packetId, {PayloadMeta? reqStateMeta, Duration timeout = rxTimeoutDefault}) {
//     // TODO: implement recvResponse
//     throw UnimplementedError();
//   }

//   @override
//   Future<PacketSyncId?> recvSync([Duration timeout = rxTimeoutDefault]) {
//     // TODO: implement recvSync
//     throw UnimplementedError();
//   }

//   @override
//   Future<R?> requestResponse<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration timeout = reqRespTimeoutDefault, ProtocolSyncOptions syncOptions = ProtocolSyncOptions.none}) {
//     // TODO: implement requestResponse
//     throw UnimplementedError();
//   }

//   @override
//   Future<R?> requestResponseShort<T, R>(PacketIdRequest<T, R> requestId, T requestArgs, {Duration? timeout = reqRespTimeoutDefault}) {
//     // TODO: implement requestResponseShort
//     throw UnimplementedError();
//   }

//   @override
//   Future<PayloadMeta> sendRequest<V>(PacketIdRequest<V, dynamic> packetId, V requestArgs) {
//     // TODO: implement sendRequest
//     throw UnimplementedError();
//   }

//   @override
//   Future<void> sendSync(PacketSyncId syncId) {
//     // TODO: implement sendSync
//     throw UnimplementedError();
//   }

//   @override
//   Future<R?> tryRecv<R>(R? Function() parse, [Duration timeout = rxTimeoutDefault]) {
//     // TODO: implement tryRecv
//     throw UnimplementedError();
//   }
// }
