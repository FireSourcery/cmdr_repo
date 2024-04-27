import 'package:flutter/material.dart'; 
 

// InputDecorator packetTime = InputDecorator(
//   decoration: const InputDecoration(labelText: 'Packet Response Time'),
//   child: ListenableBuilder(
//     listenable: Protocol.timer.elapsedNotifier,
//     builder: (context, child) => Text(Protocol.timer.elapsedNotifier.value.toString()),
//   ),
// );

// InputDecorator lastPacketIn = InputDecorator(
//   decoration: const InputDecoration(labelText: 'Rx Packet: '),
//   child: ListenableBuilder(
//     listenable: ConnectionController.lastPacketIn,
//     builder: (context, child) => Text(ConnectionController.lastPacketIn.toString()),
//   ),
// );

// InputDecorator packetIn(int socket) => InputDecorator(
//   decoration: const InputDecoration(labelText: 'Rx Packet: '),
//   child: ListenableBuilder(
//     listenable: ConnectionController.packetIn(),
//     builder: (context, child) => Text(ConnectionController.lastPacketIn.toString()),
//   ),
// );

// DecoratedValue viewPacketTime = DecoratedValue<int>(label: 'Packet Response Time', valueListenable: Protocol.timer.elapsedNotifier);
