/// Connection management library for the CMDR package.
///
/// This library provides abstractions and implementations for communicating
/// with motor controllers through various connection types (serial, network, etc.).
///
/// ## Features
///
/// - Abstract connection interfaces
/// - Protocol definitions and packet transformers
/// - Serial link implementations
/// - Connection management widgets
///
/// ## Usage
///
/// ```dart
/// import 'package:cmdr/connection.dart';
///
/// // Create a serial link
/// final link = SerialLink();
/// final protocol = MotProtocol(link);
/// ```
library cmdr.connection;

// Base connection classes
export 'connection/base/link.dart';
export 'connection/base/packet_transformer.dart';
export 'connection/base/protocol.dart';

// Connection view widgets
export 'connection/view/serial_link_view.dart';
