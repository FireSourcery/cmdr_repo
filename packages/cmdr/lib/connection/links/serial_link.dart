import 'dart:async';
import 'dart:typed_data';

import 'package:libserialport/libserialport.dart';
export 'package:libserialport/libserialport.dart';

import '../base/link.dart';
export '../base/link.dart';

///
/// libserialport Serial Link
///
class SerialLink implements Link {
  SerialLink();
  // static const List<int> baudList = [9600, 19200, 38400, 57600, 115200, 128000, 256000];
  static const List<int> baudList = [19200];
  static List<String> get portsAvailable => SerialPort.availablePorts;

  SerialPort? _serialPort; // alternatively allocating a SerialPort('') name is effectively port with internal nullptr
  SerialPortReader? _serialPortReader;

  SerialPortConfig portConfig = SerialPortConfig()
    ..baudRate = 19200
    ..parity = 0
    ..bits = 8
    ..stopBits = 1
    ..setFlowControl(SerialPortFlowControl.none);

  /// View/selection buffer — the port name chosen by the user before connecting.
  String? portConfigName;

  @override
  String? get portActiveName => _serialPort?.name;

  @override
  Stream<Uint8List>? get streamIn => _serialPortReader?.stream.handleError(_onStreamError);

  @override
  bool get isConnected => _serialPort?.isOpen ?? false;

  @override
  LinkStatus connect({String? name, int? baudRate, SerialPortConfig? config}) {
    portConfigName = name ?? portConfigName;
    portConfig = config ?? portConfig;
    portConfig.baudRate = baudRate ?? portConfig.baudRate;

    if (portConfigName == null) return const LinkError('No Port Selected');
    _serialPort = SerialPort(portConfigName!);

    if (isConnected) return LinkConnected('Already Connected $portActiveName');
    _serialPort!.config = portConfig;

    try {
      if (_serialPort!.openReadWrite()) {
        _serialPortReader = SerialPortReader(_serialPort!);
        return LinkConnected('$portActiveName');
      } else {
        // _serialPort!.dispose();
        return LinkError('Cannot Open $portConfigName ${SerialPort.lastError}');
      }
    } on SerialPortError catch (e) {
      return LinkError('Driver ${e.message}');
    }
  }

  @override
  LinkStatus disconnect() {
    if (!isConnected) return const LinkDisconnected('Not Connected');

    try {
      dispose();
      // portConfig.dispose();
      return LinkDisconnected('$portActiveName');
    } on SerialPortError catch (e) {
      return LinkError('Driver ${e.message}');
    }
  }

  void _onStreamError(Object object, StackTrace stackTrace) {
    // lastStatus = LinkStatus('Link Rx Stream Error: $object' );
    flushInput();
  }

  @override
  void dispose() {
    _serialPortReader?.close();
    _serialPort?.close();
    _serialPort?.dispose();
  }

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
