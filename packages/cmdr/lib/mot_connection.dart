/// Embedded device connection library for the CMDR package.
///
/// This library provides specialized connection implementations for
/// embedded devices, including protocol definitions and packet handling.
///
/// ## Features
///
/// - Embedded device specific protocols
/// - Packet serialization/deserialization
/// - Connection management for embedded devices
///
/// ## Usage
///
/// ```dart
/// import 'package:cmdr/mot_connection.dart';
///
/// // Use embedded device connection
/// final connection = MotConnection();
/// final protocol = MotProtocol();
/// ```
library cmdr.mot_connection;

export 'connection/mot_connection/mot_connection.dart';
export 'connection/mot_connection/mot_packet.dart';
export 'connection/mot_connection/mot_protocol.dart';
