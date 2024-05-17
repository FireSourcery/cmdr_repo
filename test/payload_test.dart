import 'dart:ffi';
import 'dart:typed_data';
import 'package:cmdr/connection/base/packet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmdr/connection/base/packet_handlers.dart';

// class VersionResponse extends MotPacket implements PayloadHandler<(int, int, int, int)> {
//   @override
//   VersionResponseValues parsePayload([void status]) => (
//         protocol: payloadWordAt<Uint32>(0),
//         library: payloadWordAt<Uint32>(4),
//         firmware: payloadWordAt<Uint32>(8),
//         board: payloadWordAt<Uint32>(12),
//       );

//   @override
//   void buildPayload(args) => throw UnimplementedError();
// }

@Packed(1)
final class TestPayload extends Struct implements Payload<(int, int)> {
  @Uint32()
  external int value0;
  @Uint32()
  external int value1;

  factory TestPayload({int value1 = 0, int value0 = 0}) {
    return Struct.create<TestPayload>()
      ..value0 = value0
      ..value1 = value1;
  }

  factory TestPayload.cast(TypedData typedData) => Struct.create<TestPayload>(typedData);
  // static PayloadCaster<TestPayload> get caster => Struct.create<TestPayload>;

  @override
  void build((int, int) args) {
    value0 = args.$1;
    value1 = args.$2;
  }

  @override
  (int, int) parse([void meta]) {
    return (value0, value1);
  }

  @override
  void get meta {}
}

enum TestPacketPayloadId<T extends Payload, R extends Payload> implements PacketIdRequestResponse<T, R> {
  testPacketId1(0x1, requestCaster: TestPayload.cast, responseCaster: TestPayload.cast);

  const TestPacketPayloadId(this.asInt, {required this.requestCaster, required this.responseCaster, this.responseId});

  @override
  final int asInt;
  @override
  final PacketId? responseId;
  @override
  final PayloadCaster<T> requestCaster;
  @override
  final PayloadCaster<R> responseCaster;
}

void main() {
  test('test', () {
    Uint32List list = Uint32List.fromList([0, 0]);

    PacketIdRequestResponse<TestPayload, TestPayload> id = TestPacketPayloadId.testPacketId1;
    TestPayload payload1 = id.requestCaster(list)..build((12345678, 87654321));

    print(list[0]);
    print(list[1]);
  });
}
