import 'dart:typed_data';

import 'package:flutter/foundation.dart';

abstract interface class Link {
  Link();
  const factory Link.uninitialized() = _LinkUninitialized; // a dummy state, so that send and recv can be called without checking for null

  LinkStatus? lastStatus;
  Exception? lastException;

  String? get portActiveName;
  Stream<Uint8List> get streamIn;

  // LinkStatus? connect();
  // void disconnect();

  /// Protocol Interface
  bool get isConnected;
  Future<Uint8List?> recv([int? byteCount]);
  Future<void> send(Uint8List bytes);
  void flushInput();
  void flushOutput();
}

class _LinkUninitialized implements Link {
  const _LinkUninitialized();
  @override
  final LinkStatus? lastStatus = null;
  @override
  final Exception? lastException = null;

  @override
  String? get portActiveName => null;
  @override
  Stream<Uint8List> get streamIn => const Stream.empty();
  @override
  bool get isConnected => false;
  @override
  Future<Uint8List?> recv([int? byteCount]) async => null;
  @override
  Future<void> send(Uint8List bytes) async {
    if (kDebugMode) {
      print("TX ${bytes.take(4)} ${bytes.skip(4).take(4)} ${bytes.skip(8)}");
    }
  }

  @override
  void flushInput() {}
  @override
  void flushOutput() {}

  @override
  set lastException(Exception? _) {}
  @override
  set lastStatus(LinkStatus? _) {}
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
