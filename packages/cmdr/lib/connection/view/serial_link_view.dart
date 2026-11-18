import 'package:flutter/material.dart';
import 'package:libserialport/libserialport.dart';

import '../links/serial_link.dart';

///
/// SerialLinkView
///
class SerialLinkConfigController(final SerialLink serialLink) with ChangeNotifier {
  /// Taken when the port name changes, not per build: reading a [SerialPort] allocates a native port.
  late PortDetails? portDetails = _detailsOf(serialLink.portConfigName);

  void updatePortName(String name) {
    serialLink.portConfigName = name;
    portDetails = _detailsOf(name);
    notifyListeners();
  }

  void updateBaudRate(int baudRate) {
    serialLink.baudRate = baudRate;
    notifyListeners();
  }

  static PortDetails? _detailsOf(String? name) => (SerialPort.availablePorts.contains(name)) ? SerialPort(name!).takeDetails() : null;
}

///
/// SerialLinkView
///
abstract class const SerialLinkView._inner(final SerialLinkConfigController configController, {super.key}) extends StatelessWidget {
  const factory SerialLinkView.port(SerialLinkConfigController configController) = SerialLinkPortView;
  const factory SerialLinkView.portConfig(SerialLinkConfigController configController) = SerialLinkConfigView;
  const factory SerialLinkView.portDetails(SerialLinkConfigController configController) = SerialLinkPortDetailsView;

  SerialLink get serialLink => configController.serialLink;
}

///
/// SerialLinkView
///
class const SerialLinkPortView(super.configController, {super.key}) extends SerialLinkView {
  this : super._inner();

  List<PopupMenuEntry<String>> itemBuilder(_) => [for (final portString in SerialLink.portsAvailable) PopupMenuItem(value: portString, child: Text(portString))];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: itemBuilder,
      initialValue: serialLink.portConfigName,
      onSelected: configController.updatePortName,
      position: PopupMenuPosition.under,
      clipBehavior: Clip.hardEdge,
      tooltip: 'Serial Port Name',
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Port', isDense: false),
        child: ListenableBuilder(
          listenable: configController,
          builder: (context, child) => Text(serialLink.portConfigName ?? 'No Ports Found'),
        ),
      ),
    );
  }
}

///
/// SerialLinkView
///
class const SerialLinkConfigView(super.configController, {super.key}) extends SerialLinkView {
  this : super._inner();

  List<PopupMenuEntry<int>> itemBuilder(_) => [for (final baudRate in SerialLink.baudList) PopupMenuItem(value: baudRate, child: Text(baudRate.toString()))];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      itemBuilder: itemBuilder,
      initialValue: serialLink.baudRate,
      onSelected: configController.updateBaudRate,
      position: PopupMenuPosition.under,
      clipBehavior: Clip.hardEdge,
      tooltip: 'Baud Rate',
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Baud Rate', isDense: false),
        child: ListenableBuilder(
          listenable: configController,
          builder: (context, child) => Text(serialLink.baudRate.toString()),
        ),
      ),
    );
  }
}

class const SerialLinkPortDetailsView(super.configController, {super.key}) extends SerialLinkView {
  this : super._inner();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: configController,
      builder: (context, child) => PortDetailsView(serialLink.portConfigName, configController.portDetails),
    );
  }
}

///
/// libserialport SerialPort View
///
class const PortDetailsView(final String? serialPortName, final PortDetails? port, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Port Details'),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 0),
        prototypeItem: const _ListTile('', ''),
        shrinkWrap: true,
        children: [
          _ListTile('Port Name', serialPortName),
          if (port case final PortDetails port) ...[
            _ListTile('Description', port.description),
            _ListTile('Transport', port.transport.toTransport()),
            _ListTile('USB Bus', port.busNumber?.toPadded()),
            _ListTile('USB Device', port.deviceNumber?.toPadded()),
            _ListTile('Vendor ID', port.vendorId?.toHex()),
            _ListTile('Product ID', port.productId?.toHex()),
            _ListTile('Manufacturer', port.manufacturer),
            _ListTile('Product Name', port.productName),
            _ListTile('Serial Number', port.serialNumber),
            _ListTile('MAC Address', port.macAddress),
          ],
        ],
      ),
    );

    // if (SerialPort.availablePorts.contains(serialPortName)) {
    //   final port = SerialPort(serialPortName!);
    //   return InputDecorator(
    //     decoration: InputDecoration(labelText: serialPortName),
    //     child: ListView(
    //       padding: const EdgeInsets.symmetric(vertical: 0),
    //       prototypeItem: const _ListTile('', ''),
    //       children: [
    //         _ListTile('Description', port.description),
    //         _ListTile('Transport', port.transport.toTransport()),
    //         _ListTile('USB Bus', port.busNumber?.toPadded()),
    //         _ListTile('USB Device', port.deviceNumber?.toPadded()),
    //         _ListTile('Vendor ID', port.vendorId?.toHex()),
    //         _ListTile('Product ID', port.productId?.toHex()),
    //         _ListTile('Manufacturer', port.manufacturer),
    //         _ListTile('Product Name', port.productName),
    //         _ListTile('Serial Number', port.serialNumber),
    //         _ListTile('MAC Address', port.macAddress),
    //       ],
    //     ),
    //   );
    // } else {
    //   return const InputDecorator(decoration: InputDecoration(labelText: 'Port Details'));
    // }
  }
}

/// The [SerialPort] fields [PortDetailsView] shows, copied out so the native port is freed at once.
typedef PortDetails = ({
  String? description,
  int transport,
  int? busNumber,
  int? deviceNumber,
  int? vendorId,
  int? productId,
  String? manufacturer,
  String? productName,
  String? serialNumber,
  String? macAddress,
});

extension on SerialPort {
  PortDetails takeDetails() {
    try {
      return (
        description: description,
        transport: transport,
        busNumber: busNumber,
        deviceNumber: deviceNumber,
        vendorId: vendorId,
        productId: productId,
        manufacturer: manufacturer,
        productName: productName,
        serialNumber: serialNumber,
        macAddress: macAddress,
      );
    } finally {
      dispose();
    }
  }
}

extension SerialPortInt on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    return switch (this) {
      SerialPortTransport.usb => 'USB',
      SerialPortTransport.bluetooth => 'Bluetooth',
      SerialPortTransport.native => 'Native',
      _ => 'Unknown',
    };
  }
}

class const _ListTile(final String label, final String? value) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(title: Text(value ?? 'N/A'), subtitle: Text(label));
}
