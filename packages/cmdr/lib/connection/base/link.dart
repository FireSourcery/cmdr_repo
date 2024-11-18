import 'dart:typed_data';

abstract interface class Link {
  Link();

  LinkStatus? lastStatus;
  Exception? lastException;

  String? get portActiveName;
  Stream<Uint8List> get streamIn;

  // bool connect();
  // void disconnect();

  /// Protocol Interface
  bool get isConnected;
  Future<Uint8List?> recv([int? byteCount]);
  Future<void> send(Uint8List bytes);
  void flushInput();
  void flushOutput();
}

class LinkStatus implements Exception {
  const LinkStatus(this.message, [this.linkType = Link, this.subset = '', this.driverException]);
  const LinkStatus.connect(this.message, [this.linkType = Link, this.driverException]) : subset = "Connect";
  final String message;
  final String subset;
  final Type linkType;
  final Exception? driverException;

  static const LinkStatus ok = LinkStatus('Ok');
}
