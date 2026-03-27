import 'dart:async';
import 'dart:typed_data';

/// Bidirectional data link interface.
///
/// Implementations manage a persistent connection to a physical or virtual port.
/// Connection lifecycle is managed via [connect]/[disconnect], which return a
/// [LinkStatus] result suitable for direct display in UI.
abstract interface class Link {
  const factory Link.uninitialized() = _LinkUninitialized;

  String? get portActiveName;
  Stream<Uint8List>? get streamIn;

  /// Whether the underlying transport is currently open.
  bool get isConnected;

  /// Establish a connection. Returns a [LinkStatus] describing the outcome.
  LinkStatus connect();

  /// Tear down the connection. Returns a [LinkStatus] describing the outcome.
  LinkStatus disconnect();

  Future<Uint8List?> recv([int? byteCount]);
  Future<void> send(Uint8List bytes);
  void flushInput();
  void flushOutput();

  FutureOr<void> dispose();
}

/// Inert placeholder — safe to call any method without null checks.
class _LinkUninitialized implements Link {
  const _LinkUninitialized();

  @override
  String? get portActiveName => null;
  @override
  Stream<Uint8List> get streamIn => const Stream.empty();
  @override
  bool get isConnected => false;
  // ValueListenable<LinkStatus> get status;

  @override
  LinkStatus connect() => const LinkError('Link Uninitialized');
  @override
  LinkStatus disconnect() => const LinkDisconnected();

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
}

///
/// Link operation result — sealed type for pattern matching.
///
/// Every variant carries a [message] suitable for direct display in UI.
///
sealed class LinkStatus {
  const LinkStatus(this.message);
  final String message;

  bool get isConnected => switch (this) {
    LinkConnected() => true,
    _ => false,
  };
}

/// Connection established successfully.
class LinkConnected extends LinkStatus {
  const LinkConnected([super.message = '']);
}

/// Connection is closed (either was never open, or cleanly disconnected).
class LinkDisconnected extends LinkStatus {
  const LinkDisconnected([super.message = '']);
}

/// An error prevented the operation from completing.
class LinkError extends LinkStatus {
  const LinkError(super.message);
}
