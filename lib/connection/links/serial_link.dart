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

  SerialPortConfig portConfig = SerialPortConfig()
    ..baudRate = 19200
    ..parity = 0
    ..bits = 8
    ..stopBits = 1
    ..setFlowControl(SerialPortFlowControl.none);

  /// view hovered selection name, SerialPort(portName) changes active pointer
  String? portConfigName = SerialPort.availablePorts.firstOrNull;

  String? get portActiveName => _serialPort?.name;

  /// returns true on success, last exception still buffered
  bool connect({String? name, int? baudRate, SerialPortConfig? config}) {
    if (name != null) portConfigName = name;
    if (config != null) portConfig = config;
    if (baudRate != null) portConfig.baudRate = baudRate;

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
      lastException = LinkException.connect('Driver', SerialLink, e);
      return false;
    }
  }

  void disconnect() {
    if (isConnected) {
      try {
        _serialPort!.close();
        _serialPort!.dispose();
      } on SerialPortError catch (e) {
        lastException = LinkException.connect('Driver', SerialLink, e);
        print(e);
      }
    }
  }

  @protected
  void onStreamError(Object object, StackTrace stackTrace) {
    lastException = const LinkException('Link Rx Stream Error', SerialLink);
    flushInput();
  }

  // void dispose() {
  //   serialPort?.dispose();
  //   serialPortConfig.dispose();
  // }

  // this way only connect() creates a new stream
  @override
  Stream<Uint8List> streamIn = const Stream.empty();
  // Stream<Uint8List> get streamIn => _readerStream ?? const Stream.empty();

  @override
  LinkException? lastException;

  @override
  bool get isConnected => (_serialPort?.isOpen ?? false); // ensures null values are initialized

  @override
  Future<Uint8List?> recv([int? byteCount]) async {
    try {
      return await streamIn.first.timeout(const Duration(milliseconds: 1000));
    } on TimeoutException {
      flushInput();
      lastException = const LinkException('Link Rx Timeout', SerialLink);
      rethrow;
    } catch (e) {
      flushInput();
      // print('Link Rx Unnamed Exception');
      rethrow;
    } finally {}
  }

  // catch only effective if called with await
  @override
  Future<void> send(Uint8List bytes) async {
    try {
      // if (!isConnected) return;
      //implicit await blocking, todo as write, await full buffer transmit?
      if (_serialPort!.write(bytes, timeout: 1000) < bytes.length) throw TimeoutException('Serial Write Timeout');
      // if (await Future(() => serialPort!.write(bytes, timeout: 0)).timeout(const Duration(milliseconds: 1000)) < bytes.length) throw TimeoutException('SerialPort Tx Timeout');
    } on TimeoutException {
      flushOutput();
      lastException = const LinkException('Link Tx Timeout', SerialLink);
      rethrow;
    } catch (e) {
      flushOutput();
      // print('Link Tx Unnamed Exception');
      rethrow;
    } finally {}
  }

  @override
  void flushInput() => _serialPort!.flush(SerialPortBuffer.input);

  @override
  void flushOutput() => _serialPort!.flush(SerialPortBuffer.output);
}
