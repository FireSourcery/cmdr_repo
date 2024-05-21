import 'dart:async';

import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

import 'link.dart';
import 'packet.dart';
import 'packet_transformer.dart';

class Protocol {
  Protocol(this.link, this.packetInterface) : headerParser = HeaderParser(packetInterface.cast, packetInterface.lengthMax * 4);

  final Link link;
  final PacketInterface packetInterface;
  final HeaderParser headerParser;
  final Map<PacketId, ProtocolSocket> respSocketMap = {}; // map response id to socket
  final Lock _lock = Lock();

  ProtocolException status = ProtocolException.ok;
  Stream<Packet>? packetStream; // rx complete packets, pre sockets

  /// beginSocketRx
  /// central distributor for socket streams
  /// limitations:
  ///   packet responseId matches to single most recent socket, unless it is implemented with socket id
  StreamSubscription<Packet>? begin() {
    if (!link.isConnected) return null;
    if (packetStream != null) return null; // return if already set, alternatively listen on single subscription stream terminates, todo reset function
    packetStream = link.streamIn.transform(PacketTransformer(parserBuffer: headerParser));

    status = ProtocolException.ok;

    return packetStream!.listen(
      (packet) {
        if (respSocketMap[packet.packetId] case ProtocolSocket socket) {
          socket.add(packet);
        }
        // else {
        //   throw const ProtocolException('no matching socket');
        // }
      },
      onError: onError,
    );
  }

  // alternatively build header, length must be set prior
  Future<void> trySend(Packet packet) async {
    try {
      print("TX ${packet.bytes.take(4)} ${packet.bytes.skip(4).take(4)} ${packet.bytes.skip(8)}");
      return await link.send(packet.bytes); // lock buffer, or await on blocking function
    } on TimeoutException {
      print("Link Timeout");
    } catch (e) {
      // todo fix null check
      onError(e);
    } finally {}
  }

  // maps response packet id to Socket
  // Future<void> requestResponse(PacketIdRequestResponse requestId, ProtocolSocket socket) {
  //   mapResponse(requestId.responseId ?? requestId, socket);
  //   return trySend(socket);
  // }

  void mapResponse(PacketId responseId, ProtocolSocket socket) {
    _lock.synchronized(() {
      respSocketMap.update(responseId, (_) => socket, ifAbsent: () => socket);
    });
  }

  void mapRequestResponse(PacketIdRequestResponse requestId, ProtocolSocket socket) {
    mapResponse(requestId.responseId ?? requestId, socket);
  }

  // if sync packet doest not contain socket id in then map all sync ids to socket requesting sync. 1 stateful request active max
  void mapSync(ProtocolSocket socket) {
    _lock.synchronized(() {
      respSocketMap.update(packetInterface.ack, (_) => socket, ifAbsent: () => socket);
      respSocketMap.update(packetInterface.nack, (_) => socket, ifAbsent: () => socket);
      respSocketMap.update(packetInterface.abort, (_) => socket, ifAbsent: () => socket);
    });
  }

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
  ProtocolSocket(this.protocol)
      : packetBufferIn = PacketBuffer(protocol.packetInterface),
        packetBufferOut = PacketBuffer(protocol.packetInterface);

  @protected
  final Protocol protocol;
  @protected
  final PacketBuffer packetBufferIn; // alternatively implement lock on buffers
  @protected
  final PacketBuffer packetBufferOut;

  final Lock _lock = Lock();
  Completer<void> _recved = Completer();

  int waitingOnLockCount = 0;

  // ProtocolException status = ProtocolException.ok; // todo with eventSink

  Stopwatch timer = Stopwatch()..start();

  static const Duration timeoutDefault = Duration(milliseconds: 500);
  static const Duration reqRespTimeoutDefault = Duration(milliseconds: 1000);
  static const Duration datagramDelay = Duration(milliseconds: 1);

  PacketInterface get packetInterface => protocol.packetInterface;

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
  Future<R?> requestResponse<T, R>(
    PacketIdRequestResponse<Payload<T>, Payload<R>> requestId,
    T requestArgs, {
    Duration? timeout = reqRespTimeoutDefault,
    ProtocolSyncOptions syncOptions = ProtocolSyncOptions.none,
  }) async {
    waitingOnLockCount++;
    try {
      return await _lock.synchronized<R?>(
        () async {
          print('');
          print('--- New Request');
          print('Socket [$hashCode] Request [$requestId] | waiting on lock [$waitingOnLockCount]');
          packetBufferIn.clear();
          protocol.mapRequestResponse(requestId, this);
          if (syncOptions.recvSync) protocol.mapSync(this);
          final PayloadMeta requestMeta = await sendRequest(requestId, requestArgs);

          if (syncOptions.recvSync) {
            if (await recvSync() != packetInterface.ack) return null; // handle nack?
          }
          final R? response = await recvResponse(requestId, reqStateMeta: requestMeta);

          if (syncOptions.sendSync) await sendSync(packetInterface.ack);
          return response;
        },
        timeout: timeout,
      );
    } on TimeoutException catch (e) {
      print("Socket lock requestResponse Timeout");
      print(e);
      // return Future.error(e);
    } catch (e) {
      print("Unhandled Socket Exception");
      print(e);
    } finally {
      print('--- End Request');
      waitingOnLockCount--;
    }
    return null;
  }

  // Future<R?> requestResponse<T, R>(PacketIdRequestResponse<T, R> requestId, T requestArgs, {Duration? timeout = reqRespTimeoutDefault}) async {
  //   try {
  //     return await _lock.synchronized<R?>(
  //       () async {
  //         packetBufferIn.clear();
  //         await sendRequest(requestId, requestArgs);
  //         return await recvResponse(requestId);
  //       },
  //       timeout: timeout,
  //     );
  //   } on TimeoutException {
  //     print("Socket lock requestResponseWithSync Timeout");
  //   } catch (e) {
  //     print(e);
  //   } finally {
  //     print('---');
  //   }
  //   return null;
  // }

  Stream<R?> periodicRequest<T, R>(PacketIdRequestResponse<Payload<T>, Payload<R>> requestId, T requestArgs, {Duration delay = datagramDelay}) async* {
    while (true) {
      yield await requestResponse<T, R>(requestId, requestArgs);
      await Future.delayed(delay); //todo as byte time
    }
  }

  Stream<(T segmentArgs, R? segmentResponse)> periodicRequestSegmented<T, R>(PacketIdRequestResponse<Payload<T>, Payload<R>> requestId, Iterable<T> requestArgs,
      {Duration delay = datagramDelay}) async* {
    while (true) {
      for (final segmentArgs in requestArgs) {
        yield (segmentArgs, await requestResponse<T, R>(requestId, segmentArgs));
        await Future.delayed(delay); //todo as byte time
      }
    }
  }

  /// periodic Response/Write
  Stream<R?> periodicUpdate<T, R>(PacketIdRequestResponse<Payload<T>, Payload<R>> requestId, T Function() requestArgsGetter, {Duration delay = datagramDelay}) async* {
    while (true) {
      yield await requestResponse<T, R>(requestId, requestArgsGetter());
      await Future.delayed(delay); // todo as byte time
    }
  }

  // Future<void> sendRaw(Uint8List bytes, {Duration timeout = timeoutDefault}) async {}
  // Uint8List recvRaw(int bytes, {int timeout = -1})

  /// handle build and, send using request side of packet
  // todo add lock on component functions?
  // buffers must lock, if sockets are shared, i.g not uniquely allocated per thread
  @protected
  Future<PayloadMeta> sendRequest<V, PT extends Payload, PR extends Payload>(PacketIdRequestResponse<PT, PR> packetId, V requestArgs, {Duration timeout = timeoutDefault}) async {
    // protocol.mapRequestResponse(packetId, this);
    final PayloadMeta requestMeta = packetBufferOut.buildRequest<PT, V>(packetId, requestArgs);

    timer.reset();
    timer.start();
    await protocol.trySend(packetBufferOut.packet);
    return requestMeta;
  }

  // get from buffer
  // Future<PayloadMeta?> responseMeta(PacketIdRequestResponse packetId, {PayloadMeta? reqStateMeta, Duration timeout = timeoutDefault}) async {
  //   packetBufferIn.parseResponseMeta<PR, V>(packetId, reqStateMeta);
  // }

  // todo response code as meta
  // Future<(M, R?)?> recvResponseWithMeta<T, R, M>(PacketIdRequestResponse<T, R> packetId, {dynamic requestMeta, Duration timeout = timeoutDefault}) async {
  //   return await tryRecv<(M, R?)>(() {
  //     final R? payload = packetBufferIn.parseResponsePayload(packetId, requestMeta);
  //     final M meta = packetBufferIn.parseResponseMeta(packetId, requestMeta);
  //     return (meta, payload);
  //   });
  // }

  /// using response side
  @protected
  Future<V?> recvResponse<V, PT extends Payload, PR extends Payload>(PacketIdRequestResponse<PT, PR> packetId, {PayloadMeta? reqStateMeta, Duration timeout = timeoutDefault}) async {
    // protocol.mapResponse(packetId.responseId ?? packetId, this);
    return await tryRecv<V>(() => packetBufferIn.parseResponse<PR, V>(packetId, reqStateMeta));
  }

  /// respondSync
  @protected
  Future<void> sendSync(PacketIdSync syncId) {
    packetBufferOut.buildSync(syncId);
    return protocol.trySend(packetBufferOut.packet);
  }

  @protected
  Future<PacketIdSync?> recvSync([Duration timeout = timeoutDefault]) {
    // protocol.mapSync(this);
    return tryRecv<PacketIdSync>(() => packetBufferIn.parseSyncId(), timeout);
  }

  // lock receiving side only?
  @protected
  Future<R?> tryRecv<R>(R? Function() parse, [Duration timeout = timeoutDefault]) async {
    try {
      // await stream.first.timeout(timeout);
      _recved = Completer.sync();
      return await _recved.future.timeout(timeout).then((_) => parse());
    } on TimeoutException {
      print("Socket Recv Response Timeout");
    } on ProtocolException catch (e) {
      //should be handled by protocol
      print("Unhandled ProtocolException on Socket");
      print(e.message);
    } on LinkException catch (e) {
      print(e.message);
    } on Exception catch (e) {
      print("Protocol Unnamed Exception");
      print(e);
    } on RangeError catch (e) {
      print("Protocol Parser Failed");
      print(e);
    } catch (e) {
      print(e);
      //payload parser may throw if invalid packet passes header parser as valid
    } finally {}
    return null;
  }

  // pass pointer, emphemeral
  @override
  void add(Packet event) {
    timer.stop();
    packetBufferIn.copyBytes(event.bytes); // sets buffer in length, exceeding length max handled by PacketReceiver

    print("Socket [${hashCode}] RX ${packetBufferIn.bytes.take(4)} ${packetBufferIn.bytes.skip(4).take(4)} ${packetBufferIn.bytes.skip(8)}");
    print("Socket [${hashCode}] Time: ${timer.elapsedMilliseconds}");

    // socket table does not unmap. might recieve packets following completion
    if (!_recved.isCompleted) _recved.complete();
  }

  @override
  void close() {
    print('Socket closed');
  }

  // @override
  // void addError(Object error, [StackTrace? stackTrace]) {
  //   print(error);
  // }

  // Future<void> procDatagram(Enum requestId, {Packet? packetBufferOut, int? socketId, bool isSync = false}) async {}

  // @protected
  // // final StreamController<Packet> streamController = StreamController.broadcast();
  // @protected
  // // StreamSink<Packet> get sink => streamController.sink;
  /// Rx Stream, event stream, protocol copies to packet out
  // Stream<Packet> get stream => streamController.stream;
  // bool get isClosed => streamController.isClosed;
}

enum ProtocolSyncOptions {
  none,
  sendOnly,
  recvOnly,
  sendAndRecv,
  ;

  bool get sendSync => switch (this) { none => false, sendOnly => true, recvOnly => false, sendAndRecv => true };
  bool get recvSync => switch (this) { none => false, sendOnly => false, recvOnly => true, sendAndRecv => true };
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
