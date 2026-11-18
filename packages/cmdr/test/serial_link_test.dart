import 'dart:io';

import 'package:cmdr/connection/base/link.dart';
import 'package:cmdr/connection/links/serial_link.dart';
import 'package:flutter_test/flutter_test.dart';

/// Point `LIBSERIALPORT_PATH` at a built `serialport.dll` to run the tests that open a port.
final Object _skipWithoutSerialPort = Platform.environment.containsKey('LIBSERIALPORT_PATH') ? false : 'opening a port needs LIBSERIALPORT_PATH';

void main() {
  // The free itself has no seam: [SerialLink] creates its own ports.
  test('a session that does not open ends, holding no port', skip: _skipWithoutSerialPort, () async {
    final SerialLink link = SerialLink()..portConfigName = 'COM_ABSENT';

    expect(await link.connect(), isA<LinkError>());
    expect(link.portActiveName, isNull);
    expect(link.isConnected, isFalse);
  });
}
