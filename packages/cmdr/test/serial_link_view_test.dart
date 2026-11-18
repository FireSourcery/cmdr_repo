import 'package:cmdr/connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const PortDetails usb = (
  description: 'USB Serial Device',
  transport: SerialPortTransport.usb,
  busNumber: 1,
  deviceNumber: 4,
  vendorId: 0x1a86,
  productId: 0x7523,
  manufacturer: 'wch.cn',
  productName: 'USB-SERIAL CH340',
  serialNumber: '5&2B',
  macAddress: null,
);

void main() {
  // Without `LIBSERIALPORT_PATH`, the default run, a build that reached libserialport would fail to load it.
  testWidgets('the port details rebuild from the snapshot the controller holds, not from a native port', (tester) async {
    final controller = SerialLinkConfigController(SerialLink()..portConfigName = 'COM7')..portDetails = usb;
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SerialLinkView.portDetails(controller))));
    controller.updateBaudRate(9600); // notifies: the details rebuild
    await tester.pump();

    expect(find.text('COM7'), findsOneWidget);
    expect(find.text('USB Serial Device'), findsOneWidget);
    expect(find.text('USB'), findsOneWidget);
    expect(find.text('001'), findsOneWidget);
    expect(find.text('0x1a86'), findsOneWidget);
  });

  testWidgets('a port that is not available shows its name only', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PortDetailsView('COM9', null))));

    expect(find.text('COM9'), findsOneWidget);
    expect(find.text('Description'), findsNothing);
  });
}
