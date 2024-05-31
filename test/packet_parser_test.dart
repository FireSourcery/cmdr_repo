import 'dart:async';

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmdr/connection.dart';
import 'package:cmdr/connection/mot_connection/mot_packet.dart';

void handleProtocolException(Object e) {
  print('handleProtocolException ${(e as ProtocolException).message}');
}

const MotPacketInterface packetInterface = MotPacketInterface();
// final PacketBuffer packetBufferIn = PacketBuffer(packetInterface, 320);
// final PacketBuffer packetBufferOut = PacketBuffer(packetInterface, 320);
final HeaderParser headerHandler = HeaderParser(MotPacket.cast, 320);

List<Uint8List> rxList = [];

// Packet packet = MotPacket.cast(Uint8List(40));

Uint8List packetIn0 = Uint8List.fromList([165, 180, 210, 2, /**/ 20, 0, 6, 0, /**/ 1, 0, 100, 0, 2, 0, 200, 0, 3, 0, 44, 1]); //1
Uint8List packetIn1 = Uint8List.fromList([165, 180, 114, 1, /**/ 16, 0, 3, 0, /**/ 1, 0, 1, 0, 2, 0, 2, 0]); //7  13
Uint8List packetInExcess = Uint8List.fromList([165, 180, 114, 1, /**/ 16, 0, 3, 0, /**/ 1, 0, 1, 0, 2, 0, 2, 0, /**/ 1]); //2
Uint8List packetInMerged = Uint8List.fromList([165, 180, 114, 1, /**/ 16, 0, 3, 0, /**/ 1, 0, 1, 0, 2, 0, 2, 0, /**/ 165, 162]); //3
Uint8List packetInChecksum = Uint8List.fromList([165, 180, 114, 2, /**/ 16, 0, 3, 0, /**/ 1, 0, 1, 0, 2, 0, 2, 0]); //4
Uint8List packetInLengthOver = Uint8List.fromList([165, 180, 210, 2, /**/ 100, 0, 6, 0, /**/ 1, 0, 100, 0, 2, 0, 200, 0, 3, 0, 44, 1]); //5
Uint8List packetInLengthUnder = Uint8List.fromList([165, 180, 210, 2, /**/ 10, 0, 6, 0, /**/ 1, 0, 100, 0, 2, 0, 200, 0, 3, 0, 44, 1]); //6
Uint8List packetInIdError = Uint8List.fromList([165, 5, 210, 2, /**/ 20, 0, 6, 0, /**/ 1, 0, 100, 0, 2, 0, 200, 0, 3, 0, 44, 1]); //8 9
Uint8List packetInPart1 = Uint8List.fromList([1, 2, 3, 4, /**/ 165, 180, 114, 1, /**/ 16, 0]); //10
Uint8List packetInPart2 = Uint8List.fromList([3, 0, /**/ 1, 0, 1, 0, 2, 0, 2, 0, /**/ 1, 165]); //11
Uint8List packetInSync = Uint8List.fromList([165, 162]); //12
Uint8List packetHedad = Uint8List.fromList([164, 165, 180, 210, 2, /**/ 20, 0, 6, 0, /**/ 1, 0, 100, 0, 2, 0, 200, 0, 3, 0, 44, 1, 2]);
Uint8List packetHedad1 = Uint8List.fromList([164, 180, 200, 2, /**/ 20, 0, 6, 0, /**/ 1, 0, 100, 0, 2, 0, 200, 0, 3, 0, 44, 1, 2]);
Uint8List packetInRepeatStart = Uint8List.fromList([165, 165, 165]);
Uint8List packetInRepeatStart2 = Uint8List.fromList([165, 165]);
// _Uint8ArrayView ([165, 162, 165, 219, 145, 1, 10, 0])

final StreamController<Uint8List> inputController = StreamController.broadcast();
final Stream<Packet> packetStream =
    inputController.stream.transform(PacketTransformer(parserBuffer: headerHandler)).handleError(handleProtocolException, test: (error) => (error is ProtocolException));
void main() {
  test('test', () async {
    print(headerHandler.length);
    packetStream.listen(
      (event) {
        print('=> packet stream: ${event.bytes}');
        rxList.add(event.bytes.sublist(0));
      },
      onError: (Object e) => print('listen onError packetStream Error $e'),
      onDone: () => rxList.forEach((element) => print(element)),
    );

    print('begin');
    motPacket.buildRequest(MotPacketRequestId.MOT_PACKET_VAR_READ, [0, 1, 2, 3]);
    print(motPacket.packet.checksumTest);

    inputController.sink.add(motPacket.bytes);
    inputController.sink.add(packetIn0);
    inputController.sink.add(packetIn1);
    inputController.sink.add(packetInExcess);
    inputController.sink.add(packetInMerged);
    inputController.sink.add(packetInChecksum);
    inputController.sink.add(packetInLengthOver);
    inputController.sink.add(packetInLengthUnder); //length under, results in checksum error
    inputController.sink.add(packetIn1);
    inputController.sink.add(packetInIdError);
    inputController.sink.add(packetInIdError);
    inputController.sink.add(packetInPart1);
    inputController.sink.add(packetInPart2);
    inputController.sink.add(packetInSync);
    inputController.sink.add(packetIn1);
    inputController.sink.add(packetInRepeatStart);
    inputController.sink.add(packetInRepeatStart2);
    inputController.sink.add(packetHedad);
    inputController.sink.add(packetHedad1);
    await inputController.sink.close();

    await inputController.done;
    print('done');
  });
}
