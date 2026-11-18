import 'package:flutter/foundation.dart';

import '../base/link.dart';
import '../base/protocol.dart';
import '../links/serial_link.dart';
import 'mot_packet.dart';
import 'mot_protocol.dart';

// Baud Rate | Byte Time | 24 byte time | 40 byte time
// 19200 bauds | 520.833 µs | 12.499992 ms | 20.83332 ms
// 115200 bauds | 86.806 µs | 2.083344 ms | 3.47224 ms

class MotConnection._() {
  static final MotConnection _singleton = MotConnection._();
  factory MotConnection() => _singleton;

  late final SerialLink serialLink = SerialLink();

  static final Protocol _uninitialized = Protocol(const Link.uninitialized(), const MotPacketCodec());
  late final Protocol _serial = Protocol(serialLink, const MotPacketCodec());

  // connection callbacks
  ValueListenable<LinkStatus> get status => serialLink.status;

  Link get activeLink => activeProtocol.link;

  Protocol activeProtocol = _uninitialized;
  MotProtocolSocket general = MotProtocolSocket(_uninitialized);
  MotProtocolSocket stop = MotProtocolSocket(_uninitialized);
  MotProtocolSocket varRead = MotProtocolSocket(_uninitialized);
  MotProtocolSocket varWrite = MotProtocolSocket(_uninitialized);

  bool get isConnected => activeProtocol.link.isConnected;

  Future<LinkStatus> begin({Enum? linkType, String? name, int? baudRate}) async {
    //  switch on link type
    activeProtocol = _serial; // [status] listeners run inside connect, and read [isConnected] through it
    _serial.end(); // connect closes the held session, whose end of stream would otherwise disconnect the new one
    serialLink
      ..portConfigName = name ?? serialLink.portConfigName
      ..baudRate = baudRate ?? serialLink.baudRate;
    final LinkStatus result = await serialLink.connect();

    if (result.isConnected) {
      _serial.begin();

      general = MotProtocolSocket(_serial);
      stop = MotProtocolSocket(_serial);
      varRead = MotProtocolSocket(_serial);
      varWrite = MotProtocolSocket(_serial);
    }

    return result;
  }
}
