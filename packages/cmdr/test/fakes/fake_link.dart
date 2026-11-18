import 'dart:async';
import 'dart:collection';

import 'package:cmdr/connection/base/link.dart';
import 'package:flutter/foundation.dart';

/// A [Link] without a port, for a test that plays the device.
///
/// [receive] delivers bytes to [streamIn] and [receiveError] a read error, [sent] keeps every write, and [onSend] answers one.
/// [unread] holds bytes that reached the port but not the reader: the next [send] reads them out, and [flushInput] drops them.
class FakeLink() implements Link {
  final StreamController<Uint8List> _rx = StreamController.broadcast();
  final List<Uint8List> sent = [];
  final Queue<Uint8List> unread = Queue();
  void Function(Uint8List bytes)? onSend;

  void receive(Uint8List bytes) => _rx.add(bytes);
  void receiveError(Object error) => _rx.addError(error);

  @override
  String? get portActiveName => 'fake';
  @override
  Stream<Uint8List> get streamIn => _rx.stream;
  @override
  bool get isConnected => status.value.isConnected;
  @override
  final ValueNotifier<LinkStatus> status = ValueNotifier(const LinkConnected('fake'));

  @override
  LinkStatus connect() => status.value = const LinkConnected('fake');
  @override
  LinkStatus disconnect() => status.value = const LinkDisconnected('fake');

  @override
  Future<Uint8List?> recv([int? byteCount]) async => null;
  @override
  Future<void> send(Uint8List bytes) async {
    sent.add(Uint8List.fromList(bytes));
    while (unread.isNotEmpty) {
      receive(unread.removeFirst());
    }
    onSend?.call(sent.last);
  }

  @override
  void flushInput() => unread.clear();
  @override
  void flushOutput() {}

  @override
  Future<void> dispose() => _rx.close();
}
