import 'dart:async';
import 'dart:typed_data';

import 'package:libserialport/libserialport.dart';
import 'package:meta/meta.dart';
import '../base/link.dart';

export 'package:libserialport/libserialport.dart';

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
  bool connect({String? name, int? baudRate, SerialPortConfig? config}) {
    portConfigName = name ?? portConfigName;
    portConfig = config ?? portConfig;
    portConfig.baudRate = baudRate ?? portConfig.baudRate;

    if (isConnected) {
      lastException = LinkException.connect('Already Connected $portActiveName', SerialLink);
      return false;
    }

    if (portConfigName == null) {
      lastException = const LinkException.connect('No Port Selected', SerialLink);
      return false;
    }

    try {
      _serialPort = SerialPort(portConfigName!);
      if (_serialPort!.openReadWrite()) {
        _serialPort!.config = portConfig;
        _serialPortReader = SerialPortReader(_serialPort!);
        streamIn = _serialPortReader!.stream.asBroadcastStream().handleError(onStreamError);
        return true;
      } else {
        lastException = LinkException.connect('Cannot Open $portConfigName', SerialLink);
        return false;
      }
    } on SerialPortError catch (e) {
      lastException = LinkException.connect('Driver $e', SerialLink, e);
      return false;
    }
  }

  void disconnect() {
    if (isConnected) {
      try {
        _serialPort!.close();
        _serialPort!.dispose();
      } on SerialPortError catch (e) {
        lastException = LinkException.connect('Driver $e', SerialLink, e);
        print(e);
      }
    }
  }

  @protected
  void onStreamError(Object object, StackTrace stackTrace) {
    lastException = LinkException('Link Rx Stream Error: $object', SerialLink);
    flushInput();
  }

  // void dispose() {
  //   serialPort?.dispose();
  //   serialPortConfig.dispose();
  // }

  @override
  String? get portActiveName => _serialPort?.name;

  // this way only connect() creates a new stream
  @override
  Stream<Uint8List> streamIn = const Stream.empty();

  @override
  LinkException? lastException;

  @override
  bool get isConnected => (_serialPort?.isOpen ?? false); // ensures null values are initialized

  @override
  Future<Uint8List> recv([int? byteCount]) async {
    try {
      return await streamIn.first.timeout(const Duration(milliseconds: 1000));
    } on TimeoutException {
      flushInput();
      lastException = const LinkException('Link Rx Timeout', SerialLink);
      rethrow;
    } catch (e) {
      flushInput();
      lastException = LinkException('Link Rx: $e', SerialLink);
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
      lastException = const LinkException('Link Tx Timeout', SerialLink);
      rethrow;
    } catch (e) {
      lastException = LinkException('Link Tx: $e', SerialLink);
      flushOutput();
      rethrow;
    } finally {}
  }

  @override
  void flushInput() => _serialPort!.flush(SerialPortBuffer.input);

  @override
  void flushOutput() => _serialPort!.flush(SerialPortBuffer.output);
}
