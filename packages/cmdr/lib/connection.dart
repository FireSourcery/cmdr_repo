/// Connection management library for the CMDR package.
///
/// This library provides abstractions and implementations for communicating
/// with motor controllers through various connection types (serial, network, etc.).
///
/// ```dart
/// import 'package:cmdr/connection.dart';
///
/// // A protocol puts a wire format over a link
/// final protocol = Protocol(SerialLink(), codec); // codec: a PacketCodec
/// ```
library;

export 'package:libserialport/libserialport.dart';

// Base connection classes
export 'connection/base/link.dart';
export 'connection/base/protocol.dart';
export 'connection/links/serial_link.dart';

// Connection view widgets
export 'connection/view/serial_link_view.dart';
