import 'packet.dart';

extension PacketExt on Packet {
  static int crc16(Uint8List u8list) {
    var crc = 0;
    for (final byte in u8list) {
      crc ^= (byte << 8);
      for (var i = 0; i < 8; ++i) {
        int temp = (crc << 1);
        if (crc & 0x8000 != 0) {
          temp ^= (0x1021);
        }
        crc = temp;
      }
    }
    return crc;
  }
}
