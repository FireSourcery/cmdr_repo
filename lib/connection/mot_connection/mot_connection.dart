import '../base/protocol.dart';
import 'mot_packet.dart';
import 'mot_protocol.dart';
import '../links/serial_link.dart';

// Baud Rate | Byte Time | 24 byte time | 40 byte time
// 19200 bauds | 520.833 µs | 12.499992 ms | 20.83332 ms
// 115200 bauds | 86.806 µs | 2.083344 ms | 3.47224 ms

class MotConnection {
  static final SerialLink serialLink = SerialLink();
  // final BluetoothLink bluetoothLink = BluetoothLink();

  static final Protocol protocol = Protocol(serialLink, const MotPacketInterface());

  static final MotProtocolSocket general = MotProtocolSocket(protocol);
  static final MotProtocolSocket stop = MotProtocolSocket(protocol);
  static final MotProtocolSocket varRead = MotProtocolSocket(protocol);
  static final MotProtocolSocket varWrite = MotProtocolSocket(protocol);
  // static final MotProtocolSocket events = MotProtocolSocket(protocol);

  static bool get isConnected => protocol.link.isConnected;

  static bool begin({dynamic linkType, String? name, int? baudRate}) {
    //todo connect and begin
    if (isConnected) protocol.begin();
    return isConnected;
  }
}
