import 'package:cmdr/connection/base/link.dart';
import 'package:cmdr/connection/mot_connection/mot_connection.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs without `LIBSERIALPORT_PATH`: [MotConnection] reaches the native serial port library only to open a selected port.
void main() {
  test('MotConnection constructs without the serial port library, disconnected', () {
    expect(MotConnection().status.value.isConnected, isFalse);
    expect(MotConnection().isConnected, isFalse);
  });

  test('begin with no port selected completes with the error it publishes on status', () async {
    final LinkStatus result = await MotConnection().begin();

    expect(result, isA<LinkError>().having((status) => status.message, 'message', 'No Port Selected'));
    expect(MotConnection().status.value, same(result));
    expect(MotConnection().isConnected, isFalse);
  });
}
