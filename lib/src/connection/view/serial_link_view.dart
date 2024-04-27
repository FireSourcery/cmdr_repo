import 'package:flutter/material.dart';

import '../protocol/serial_link.dart';

export '../protocol/serial_link.dart';

////////////////////////////////////////////////////////////////////////////////
/// SerialLinkView
////////////////////////////////////////////////////////////////////////////////
class SerialLinkConfigController with ChangeNotifier {
  SerialLinkConfigController(this.serialLink);
  final SerialLink serialLink;

  void updatePortName(String name) {
    serialLink.portConfigName = name;
    notifyListeners();
  }

  void updateBaudRate(int baudRate) {
    serialLink.portConfig.baudRate = baudRate;
    notifyListeners();
  }
}

////////////////////////////////////////////////////////////////////////////////
/// SerialLinkView
////////////////////////////////////////////////////////////////////////////////
abstract class SerialLinkView extends StatelessWidget {
  const SerialLinkView._inner(this.configController, {super.key});

  const factory SerialLinkView.port(SerialLinkConfigController configController) = SerialLinkPortView;
  const factory SerialLinkView.portConfig(SerialLinkConfigController configController) = SerialLinkConfigView;
  const factory SerialLinkView.portDetails(SerialLinkConfigController configController) = SerialLinkPortDetailsView;

  final SerialLinkConfigController configController;
  SerialLink get serialLink => configController.serialLink;
}

////////////////////////////////////////////////////////////////////////////////
/// SerialLinkView
////////////////////////////////////////////////////////////////////////////////
class SerialLinkPortView extends SerialLinkView {
  const SerialLinkPortView(super.configController, {super.key}) : super._inner();

  @override
  Widget build(BuildContext context) {
    List<PopupMenuEntry<String>> itemBuilder(_) => [for (final portString in SerialLink.portsAvailable) PopupMenuItem(value: portString, child: Text(portString))];
    return PopupMenuButton<String>(
      itemBuilder: itemBuilder,
      initialValue: serialLink.portConfigName,
      onSelected: configController.updatePortName,
      position: PopupMenuPosition.under,
      clipBehavior: Clip.hardEdge,
      tooltip: 'Serial Port Name',
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Port'),
        child: ListenableBuilder(
          listenable: configController,
          builder: (context, child) => Text(serialLink.portConfigName ?? 'No Ports Found'),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
/// SerialLinkView
////////////////////////////////////////////////////////////////////////////////
class SerialLinkConfigView extends SerialLinkView {
  const SerialLinkConfigView(super.configController, {super.key}) : super._inner();

  @override
  Widget build(BuildContext context) {
    List<PopupMenuEntry<int>> itemBuilder(_) => [for (final baudRate in SerialLink.baudList) PopupMenuItem(value: baudRate, child: Text(baudRate.toString()))];
    return PopupMenuButton<int>(
      itemBuilder: itemBuilder,
      initialValue: serialLink.portConfig.baudRate,
      onSelected: configController.updateBaudRate,
      position: PopupMenuPosition.under,
      clipBehavior: Clip.hardEdge,
      tooltip: 'Baud Rate',
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Baud Rate'),
        child: ListenableBuilder(
          listenable: configController,
          builder: (context, child) => Text(serialLink.portConfig.baudRate.toString()),
        ),
      ),
    );
  }
}

class SerialLinkPortDetailsView extends SerialLinkView {
  const SerialLinkPortDetailsView(super.configController, {super.key}) : super._inner();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: configController,
      builder: (context, child) => PortDetailsView(serialLink.portConfigName),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
/// libserialport SerialPort View
////////////////////////////////////////////////////////////////////////////////
class PortDetailsView extends StatelessWidget {
  const PortDetailsView(this.serialPortName, {super.key});

  final String? serialPortName;

  @override
  Widget build(BuildContext context) {
    if (SerialPort.availablePorts.contains(serialPortName)) {
      final port = SerialPort(serialPortName!);
      return InputDecorator(
        decoration: InputDecoration(labelText: serialPortName),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 0),
          prototypeItem: _ListTile('Description', port.description),
          children: [
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
        ),
      );
    } else {
      return const InputDecorator(decoration: InputDecoration(labelText: 'Port Details'));
    }
  }
}

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    return switch (this) { SerialPortTransport.usb => 'USB', SerialPortTransport.bluetooth => 'Bluetooth', SerialPortTransport.native => 'Native', _ => 'Unknown' };
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile(this.label, this.value);
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => ListTile(title: Text(value ?? 'N/A'), subtitle: Text(label));
}
