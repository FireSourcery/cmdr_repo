import 'dart:typed_data';

abstract interface class Link {
  Link();

  LinkException? lastException;
  Stream<Uint8List> get streamIn;

  /// Protocol Interface
  bool get isConnected;
  Future<Uint8List?> recv([int? byteCount]);
  Future<void> send(Uint8List bytes);
  void flushInput();
  void flushOutput();
}

class LinkException implements Exception {
  const LinkException(this.message, [this.linkType = Link, this.subset = '', this.driverException]);
  const LinkException.connect(this.message, [this.linkType = Link, this.driverException]) : subset = "Connect";
  final String message;
  final String subset;
  final Type linkType;
  final Exception? driverException;
}
