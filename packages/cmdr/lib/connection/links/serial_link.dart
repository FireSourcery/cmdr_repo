import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'package:libserialport/libserialport.dart';
export 'package:libserialport/libserialport.dart';

import '../base/link.dart';
export '../base/link.dart';

////////////////////////////////////////////////////////////////////////////////
/// libserialport Serial Link
////////////////////////////////////////////////////////////////////////////////
class SerialLink implements Link {
  SerialLink();
  // static const List<int> baudList = [9600, 19200, 38400, 57600, 115200, 128000, 256000];
  static const List<int> baudList = [19200];
  static List<String> get portsAvailable => SerialPort.availablePorts;

  SerialPort? _serialPort; // alternatively allocating a SerialPort with '' name is effectively port with internal nullptr
  SerialPortReader? _serialPortReader;

  // alternatively move to SerialPortConfigViewController
  SerialPortConfig portConfig = SerialPortConfig()
    ..baudRate = 19200
    ..parity = 0
    ..bits = 8
    ..stopBits = 1
    ..setFlowControl(SerialPortFlowControl.none);

  /// view hovered selection name, SerialPort(portName) changes active pointer
  String? portConfigName;

  /// returns true on success, last exception still buffered
  /// LinkStatus?
  bool connect({String? name, int? baudRate, SerialPortConfig? config}) {
    portConfigName = name ?? portConfigName;
    portConfig = config ?? portConfig;
    portConfig.baudRate = baudRate ?? portConfig.baudRate;

    if (isConnected) {
      lastStatus = LinkStatus.connect('Already Connected $portActiveName', SerialLink);
      return false;
    }

    if (portConfigName == null) {
      lastStatus = const LinkStatus.connect('No Port Selected', SerialLink);
      return false;
    }

    try {
      _serialPort = SerialPort(portConfigName!);
      if (_serialPort!.openReadWrite()) {
        _serialPort!.config = portConfig;
        _serialPortReader = SerialPortReader(_serialPort!);
        streamIn = _serialPortReader!.stream.asBroadcastStream().handleError(onStreamError);
        lastStatus = LinkStatus.connect('$portActiveName', SerialLink);
        return true;
      } else {
        lastStatus = LinkStatus.connect('Cannot Open $portConfigName', SerialLink);
        return false;
      }
    } on SerialPortError catch (e) {
      lastStatus = LinkStatus.connect('Driver $e', SerialLink, e);
      return false;
    }
  }

  void disconnect() {
    if (isConnected) {
      try {
        _serialPort!.close();
        _serialPort!.dispose();
      } on SerialPortError catch (e) {
        lastStatus = LinkStatus.connect('Driver $e', SerialLink, e);
        print(e);
      }
    }
  }

  @override
  String? get portActiveName => _serialPort?.name;

  // this way only connect() creates a new stream
  @override
  Stream<Uint8List> streamIn = const Stream.empty();

  @override
  LinkStatus? lastStatus;
  @override
  Exception? lastException;

  @override
  bool get isConnected => (_serialPort?.isOpen ?? false); // ensures null values are initialized

  @protected
  void onStreamError(Object object, StackTrace stackTrace) {
    lastStatus = LinkStatus('Link Rx Stream Error: $object', SerialLink);
    flushInput();
  }

  void dispose() {
    _serialPort?.dispose();
  }

  @override
  Future<Uint8List> recv([int? byteCount]) async {
    try {
      return await streamIn.first.timeout(const Duration(milliseconds: 1000));
    } on TimeoutException {
      flushInput();
      lastStatus = const LinkStatus('Link Rx Timeout', SerialLink);
      rethrow;
    } catch (e) {
      flushInput();
      lastStatus = LinkStatus('Link Rx: $e', SerialLink);
      rethrow;
    } finally {}
  }

  /// Caller check [isConnected]
  @override
  Future<void> send(Uint8List bytes) async {
    try {
      // implicit await blocking, allow driver to initiate timeout, block reentrant, or ignore reentrant call. ensure blocking calls do not stack
      if (_serialPort!.write(bytes, timeout: 1000) < bytes.length) throw TimeoutException('Serial Write Incomplete');
      // reentrant async calls handled in the same order they arrive?
      // if (await Future(() => serialPort!.write(bytes, timeout: 500)).timeout(const Duration(milliseconds: 1000)) < bytes.length) throw TimeoutException('SerialPort Tx Timeout');
    } on TimeoutException {
      flushOutput();
      lastStatus = const LinkStatus('Link Tx Timeout', SerialLink);
      rethrow;
    } catch (e) {
      lastStatus = LinkStatus('Link Tx: $e', SerialLink);
      flushOutput();
      rethrow;
    } finally {}
  }

  @override
  void flushInput() => _serialPort!.flush(SerialPortBuffer.input);

  @override
  void flushOutput() => _serialPort!.flush(SerialPortBuffer.output);
}
