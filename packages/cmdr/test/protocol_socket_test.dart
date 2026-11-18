import 'dart:typed_data';

import 'package:cmdr/connection/base/link.dart';
import 'package:cmdr/connection/base/protocol.dart';
import 'package:cmdr/connection/mot_connection/mot_packet.dart';
import 'package:cmdr/connection/mot_connection/mot_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_link.dart';

const MotPacketCodec _codec = MotPacketCodec();
const Duration _timeout = Duration(milliseconds: 50);
final Matcher _unexpectedRx = isA<ProtocolException>().having((e) => e.message, 'message', 'Unexpected Rx');

/// A [Protocol] that keeps what reaches its error path.
class _RecordingProtocol(super.link, super.codec) extends Protocol {
  final List<Object> errors = [];

  @override
  void onError(Object error) => errors.add(error);
}

VersionResponseValues _version(int protocol) => (protocol: protocol, library: 0, firmware: 0);

Uint8List _versionFrame(int protocol) {
  final PacketBuffer frame = PacketBuffer(_codec);
  frame.buildHeader(MotPacketRequestId.MOT_PACKET_VERSION, VersionResponse.cast(Uint8List.sublistView(frame.storage, _codec.dataFormat.headerLength)).build(_version(protocol)));
  return Uint8List.fromList(frame.bytes);
}

Uint8List _controlFrame(PacketControlId id) => Uint8List.fromList((PacketBuffer(_codec)..buildControl(id)).bytes);

int _idOf(Uint8List frame) => frame[1];

void main() {
  late FakeLink link;
  late _RecordingProtocol protocol;
  late MotProtocolSocket socket;

  setUp(() {
    link = FakeLink();
    protocol = _RecordingProtocol(link, _codec)..begin();
    socket = MotProtocolSocket(protocol);
  });
  tearDown(() => link.dispose());

  test('a response arriving after its request timed out does not complete the next request', () async {
    link.onSend = (_) => link.unread.add(_versionFrame(1)); // answered, but still in the port when the request gives up
    expect(await socket.requestResponse(MotPacketRequestId.MOT_PACKET_VERSION, null, timeout: _timeout), isNull);

    link.onSend = (_) => link.receive(_versionFrame(2));
    expect(await socket.version(), _version(2));
  });

  test('a stray packet while idle reaches the error callback and does not throw', () async {
    protocol.mapRequestResponse(MotPacketRequestId.MOT_PACKET_VERSION, socket);

    link
      ..receive(_versionFrame(1))
      ..receive(_versionFrame(2));
    await pumpEventQueue();

    expect(protocol.errors, [_unexpectedRx, _unexpectedRx]);
  });

  test('a data mode step with no response sends no ACK', () async {
    protocol.mapSync(socket);
    link.onSend = (_) => link.receive(_controlFrame(MotPacketControlId.MOT_PACKET_SYNC_ACK));
    expect(await socket.writeDataModeStream(Uint8List(4)).toList(), [4]);

    link.onSend = null;
    expect(await socket.endDataModeWrite(), isNull);
    await pumpEventQueue();

    expect(link.sent.map(_idOf), [MotPacketRequestId.MOT_PACKET_DATA_MODE_DATA.intId]);
  });

  test('ping and a concurrent request do not share the latch', () async {
    link.onSend = (bytes) => link.receive(_idOf(bytes) == MotPacketControlId.MOT_PACKET_PING.intId ? _controlFrame(MotPacketControlId.MOT_PACKET_PING) : _versionFrame(3));

    final Future<VersionResponseValues?> version = socket.version();
    final Future<PacketControlId?> ping = socket.pingDefault();

    expect(await version, _version(3));
    expect(await ping, MotPacketControlId.MOT_PACKET_PING);
    expect(protocol.errors, isEmpty);
  });

  group('the link status', () {
    late List<LinkStatus> statuses;
    setUp(() {
      statuses = [];
      link.status.addListener(() => statuses.add(link.status.value));
    });

    test('a read error is reported, disconnects the link, and notifies once', () async {
      link.receiveError(Exception('unplugged'));
      await pumpEventQueue();

      expect(protocol.errors, [isA<Exception>()]);
      expect(statuses, [isA<LinkDisconnected>()]);
      expect(link.isConnected, isFalse);
    });

    test('a failed write is reported, and disconnects the link', () async {
      link.onSend = (_) => throw Exception('write failed');
      expect(await socket.requestResponse(MotPacketRequestId.MOT_PACKET_VERSION, null, timeout: _timeout), isNull);

      expect(protocol.errors, [isA<Exception>()]);
      expect(statuses, [isA<LinkDisconnected>()]);
    });

    test('the end of the link stream disconnects the link', () async {
      await link.dispose();
      await pumpEventQueue();

      expect(statuses, [isA<LinkDisconnected>()]);
    });

    test('after end, the end of the link stream leaves the link connected', () async {
      protocol.end();
      await link.dispose();
      await pumpEventQueue();

      expect(statuses, isEmpty);
    });

    test('a corrupt frame is reported, and the link stays connected', () async {
      link.receive(_versionFrame(1)..[4] ^= 0xFF);
      await pumpEventQueue();

      expect(protocol.errors, [PacketStatusException.checksum]);
      expect(statuses, isEmpty);
    });

    test('connect completes with the status it publishes', () async {
      link.disconnect();

      await expectLater(link.connect(), completion(isA<LinkConnected>()));
      expect(statuses, [isA<LinkDisconnected>(), isA<LinkConnected>()]);
    });

    test('a reconnect moves the status back, and the next session is watched', () async {
      link.receiveError(Exception('unplugged'));
      await pumpEventQueue();
      await link.connect();
      protocol.begin();
      link.receiveError(Exception('unplugged'));
      await pumpEventQueue();

      expect(statuses, [isA<LinkDisconnected>(), isA<LinkConnected>(), isA<LinkDisconnected>()]);
    });
  });
}
