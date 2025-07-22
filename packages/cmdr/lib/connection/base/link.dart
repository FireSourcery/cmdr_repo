import 'dart:async';
import 'dart:typed_data';

abstract interface class Link {
  Link();
  const factory Link.uninitialized() = _LinkUninitialized; // a dummy state, so that send and recv can be called without checking for null

  String? get portActiveName;
  Stream<Uint8List> get streamIn;

  /// Protocol Interface
  bool get isConnected;
  Future<Uint8List?> recv([int? byteCount]);
  Future<void> send(Uint8List bytes);
  void flushInput();
  void flushOutput();

  FutureOr<void> dispose();

  LinkConnectionStatus? connect();
  void disconnect();

  LinkStatus? get lastStatus;
  Exception? get lastException;
}

class _LinkUninitialized implements Link {
  const _LinkUninitialized();

  @override
  LinkStatus? get lastStatus => const LinkStatus('Link Uninitialized', linkType: Link);
  @override
  Exception? get lastException => null;

  @override
  String? get portActiveName => null;
  @override
  Stream<Uint8List> get streamIn => const Stream.empty();
  @override
  bool get isConnected => false;
  @override
  Future<Uint8List?> recv([int? byteCount]) async => null;
  @override
  Future<void> send(Uint8List bytes) async {}

  @override
  void flushInput() {}
  @override
  void flushOutput() {}
  @override
  FutureOr<void> dispose() {}

  @override
  LinkConnectionStatus? connect() => null;

  @override
  void disconnect() {}
}

class LinkStatus {
  const LinkStatus(this.message, {this.linkType = Link});
  // LinkStatus.ofException(Exception e) : message = e.message;

  final String message;
  final Type linkType;
  // final Exception? exception;
}

class LinkConnectionStatus extends LinkStatus {
  const LinkConnectionStatus.error(super.message, {super.linkType}) : isConnected = false;
  const LinkConnectionStatus.success(super.message, {super.linkType}) : isConnected = true;

  final bool isConnected;
}
