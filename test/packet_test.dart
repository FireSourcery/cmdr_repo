import 'dart:typed_data';
import 'package:cmdr/connection/base/packet.dart';
import 'package:cmdr/connection/mot_connection/mot_packet.dart';
import 'package:flutter_test/flutter_test.dart';

R? checkType<T, R>(PacketIdRequest<Payload<T>, Payload<R>> requestId, T requestArgs) {
  Uint8List list = Uint8List(40);
  MotPacket packet = MotPacket.cast(list);

  Payload<T> request = requestId.requestCaster!(list)..build(requestArgs);
  Payload<R> response = requestId.responseCaster!(list);

  return response.parse(packet, null);
}

void packetTest() {
  // Uint8List list = Uint8List(40);
  Uint8List packetIn0 = Uint8List.fromList([165, 180, 210, 2, /**/ 20, 0, 6, 0, /**/ 1, 0, 100, 0, 2, 0, 200, 0, 3, 0, 44, 1]); //1
  MotPacket packet = MotPacket.cast(packetIn0);
  expect(packet.packetHeader.startField, 165);
  expect(packet.packetHeader.idField, 180);
  expect(packet.packetHeader.checksumField, (2 << 8) | 210);
  expect(packet.packetHeader.flex1FieldValue, 6);
}

void main() {
  test('test', () {
    Uint8List list = Uint8List(40);

    PacketIdRequest id = MotPacketRequestId.MOT_PACKET_MEM_WRITE;
    Payload payload = id.requestCaster!(list);
    // TestPayload payload1 = id.requestCaster!(list)..build((12345678, 87654321));
    final results = checkType(MotPacketRequestId.MOT_PACKET_MEM_WRITE, (1, 2, 3, Uint8List.fromList([255, 255, 255])));

    print(list[0]);
    print(list[1]);

    packetTest();
    // print(payload.address);
    // print(list[1]);
    // expect(actual, matcher);
  });
}
