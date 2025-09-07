import 'dart:async';

import '../base/link.dart';
import '../base/protocol.dart';
import '../links/serial_link.dart';
import 'mot_packet.dart';
import 'mot_protocol.dart';

export '../base/link.dart';
export '../base/protocol.dart';
export '../links/serial_link.dart';
export 'mot_packet.dart';
export 'mot_protocol.dart';

// Baud Rate | Byte Time | 24 byte time | 40 byte time
// 19200 bauds | 520.833 µs | 12.499992 ms | 20.83332 ms
// 115200 bauds | 86.806 µs | 2.083344 ms | 3.47224 ms

class MotConnection {
  MotConnection._();
  static final MotConnection _singleton = MotConnection._();
  factory MotConnection() => _singleton;
  // static MotConnection get main => _singleton;

  final SerialLink serialLink = SerialLink();
  // final BluetoothLink bluetoothLink = BluetoothLink();

  static final Protocol _uninitialized = Protocol(const Link.uninitialized(), const MotPacketInterface());
  late final Protocol _serial = Protocol(serialLink, const MotPacketInterface());

  // late final Protocol protocol = Protocol(serialLink, const MotPacketInterface());
  // late final MotProtocolSocket general = MotProtocolSocket(protocol);
  // late final MotProtocolSocket stop = MotProtocolSocket(protocol);
  // late final MotProtocolSocket varRead = MotProtocolSocket(protocol);
  // late final MotProtocolSocket varWrite = MotProtocolSocket(protocol);
  //   final MotProtocolSocket events = MotProtocolSocket(protocol);
  // Link activeLink = const Link.uninitialized();
  Link get activeLink => activeProtocol.link;

  Protocol activeProtocol = _uninitialized;
  MotProtocolSocket general = MotProtocolSocket(_uninitialized);
  MotProtocolSocket stop = MotProtocolSocket(_uninitialized);
  MotProtocolSocket varRead = MotProtocolSocket(_uninitialized);
  MotProtocolSocket varWrite = MotProtocolSocket(_uninitialized);

  StreamSubscription<Packet>? packetSubscription;

  bool get isConnected => activeProtocol.link.isConnected;

  bool begin({Enum? linkType, String? name, int? baudRate}) {
    //  switch on link type

    if (serialLink.connect(name: name, baudRate: baudRate).isConnected) {
      packetSubscription?.cancel(); // begin central demux
      packetSubscription = _serial.begin();

      activeProtocol = _serial;
      general = MotProtocolSocket(_serial);
      stop = MotProtocolSocket(_serial);
      varRead = MotProtocolSocket(_serial);
      varWrite = MotProtocolSocket(_serial);
    }

    return isConnected;
  }
}
