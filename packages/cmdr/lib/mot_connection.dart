/// Embedded device connection library for the CMDR package.
///
/// This library provides specialized connection implementations for
/// embedded devices, including protocol definitions and packet handling.
///
/// ```dart
/// import 'package:cmdr/mot_connection.dart';
///
/// // The Mot wire format over a serial link, one socket per request stream
/// final protocol = Protocol(SerialLink(), const MotPacketCodec());
/// final socket = MotProtocolSocket(protocol);
/// ```
library;

export 'package:libserialport/libserialport.dart';

export 'connection/base/link.dart';
export 'connection/base/protocol.dart';
export 'connection/links/serial_link.dart';
export 'connection/mot_connection/mot_packet.dart';
export 'connection/mot_connection/mot_protocol.dart';
