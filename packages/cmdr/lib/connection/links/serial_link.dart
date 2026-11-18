import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:libserialport/libserialport.dart';

import '../base/link.dart';

///
/// libserialport Serial Link
///
class SerialLink() implements Link {
  // static const List<int> baudList = [9600, 19200, 38400, 57600, 115200, 128000, 256000];
  static const List<int> baudList = [19200];
  static List<String> get portsAvailable => SerialPort.availablePorts;

  SerialPort? _serialPort; // alternatively allocating a SerialPort('') name is effectively port with internal nullptr
  SerialPortReader? _serialPortReader;

  /// The reader isolate's wait on the port, between its checks of it.
  static const Duration _readerWait = Duration(milliseconds: 500);

  int baudRate = 19200;

  /// Built per session: [SerialPort.dispose] frees the config set on the port.
  SerialPortConfig _portConfig() => SerialPortConfig()
    ..baudRate = baudRate
    ..parity = 0
    ..bits = 8
    ..stopBits = 1
    ..setFlowControl(SerialPortFlowControl.none);

  /// View/selection buffer — the port name chosen by the user before connecting.
  String? portConfigName;

  @override
  String? get portActiveName => _serialPort?.name;

  @override
  Stream<Uint8List>? get streamIn => _serialPortReader?.stream;

  @override
  bool get isConnected => _serialPort?.isOpen ?? false;

  @override
  final ValueNotifier<LinkStatus> status = ValueNotifier(const LinkDisconnected());

  @override
  Future<LinkStatus> connect() async {
    if (portConfigName == null) return status.value = const LinkError('No Port Selected');
    _close(); // each connect is a new session. Windows opens a port exclusively, so the held one must go first

    try {
      _serialPort = SerialPort(portConfigName!);
      if (_serialPort!.openReadWrite()) {
        _serialPort!.config = _portConfig(); // libserialport configures an open port only
        _serialPortReader = SerialPortReader(_serialPort!, timeout: _readerWait.inMilliseconds);
        return status.value = LinkConnected('$portActiveName');
      } else {
        return status.value = LinkError('Cannot Open $portConfigName ${SerialPort.lastError}');
      }
    } on SerialPortError catch (e) {
      _close(); // the port may be open: [isConnected] reads false before the status is published
      return status.value = LinkError('Driver ${e.message}');
    } finally {
      if (!status.value.isConnected) _close(); // a session that did not open frees its port
    }
  }

  @override
  LinkStatus disconnect() {
    if (!isConnected) return const LinkDisconnected('Not Connected');

    try {
      final String? name = portActiveName; // the session frees its port
      _close();
      return status.value = LinkDisconnected('$name');
    } on SerialPortError catch (e) {
      return LinkError('Driver ${e.message}');
    }
  }

  /// Ends the session. [SerialPort.dispose] frees the port and the config [connect] set on it two [_readerWait]s after the close:
  /// the reader's isolate stops only by reading the closed port, within one of its waits, and closing the reader does not stop it.
  void _close() {
    _serialPortReader?.close();
    _serialPortReader = null;
    _serialPort?.close();
    if (_serialPort case final SerialPort port) Future<void>.delayed(_readerWait * 2, port.dispose);
    _serialPort = null;
  }

  @override
  void dispose() => _close();

  @override
  Future<Uint8List> recv([int? byteCount]) async {
    return _serialPort!.read(byteCount ?? _serialPort!.bytesAvailable, timeout: 1000);
  }

  @override
  Future<void> send(Uint8List bytes) async {
    // implicit await blocking, allow driver to initiate timeout, block reentrant, or ignore reentrant call.
    if (_serialPort!.write(bytes, timeout: 1000) < bytes.length) throw TimeoutException('Serial Write Incomplete');
  }

  @override
  void flushInput() => _serialPort!.flush(SerialPortBuffer.input);

  @override
  void flushOutput() => _serialPort!.flush(SerialPortBuffer.output);
}
