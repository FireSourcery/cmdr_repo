// import 'dart:ffi';
// import 'dart:typed_data';
// import '../../binary_data/lib/src/binary_models/packet.dart';
// import 'package:flutter_test/flutter_test.dart';

// typedef PayloadCaster<T extends Payload> = T Function([TypedData typedData]);

// /// Id as payload factory
// /// paired request response id for simplicity in case of shared id by request and response
// /// under define responseId for 1-way e.g <T, void>
// ///   handlers must be constructors, mutable objects cannot be const for enum
// abstract interface class PacketIdRequestResponse<T extends Payload, R extends Payload> implements PacketId {
//   const PacketIdRequestResponse();

//   PacketId? get responseId; // null for 1-way or matching response, override for non matching
//   PayloadCaster<T>? get requestCaster;
//   PayloadCaster<R>? get responseCaster;
// }

// @Packed(1)
// final class TestPayload extends Struct implements Payload<(int, int)> {
//   @Uint32()
//   external int value0;
//   @Uint32()
//   external int value1;

//   factory TestPayload({int value1 = 0, int value0 = 0}) {
//     return Struct.create<TestPayload>()
//       ..value0 = value0
//       ..value1 = value1;
//   }

//   factory TestPayload.cast(TypedData typedData) => Struct.create<TestPayload>(typedData);

//   @override
//   PayloadMeta build((int, int) args, [Packet? a]) {
//     value0 = args.$1;
//     value1 = args.$2;
//     return const PayloadMeta(0);
//   }

//   @override
//   (int, int) parse(Packet a, [PayloadMeta? v]) {
//     return (value0, value1);
//   }
// }

// enum TestPacketPayloadId<T extends Payload, R extends Payload> implements PacketIdRequestResponse<T, R> {
//   // testPacketId1(0x1, requestCaster: TestPayload.cast, responseCaster: TestPayload.cast),
//   testPacketId2(0x2, requestCaster: Struct.create<TestPayload>, responseCaster: Struct.create<TestPayload>);

//   const TestPacketPayloadId(this.intId, {required this.requestCaster, required this.responseCaster, this.responseId});

//   @override
//   final int intId;
//   @override
//   final PacketId? responseId;
//   @override
//   final PayloadCaster<T> requestCaster;
//   @override
//   final PayloadCaster<R> responseCaster;
// }

// void main() {
//   test('test', () {
//     Uint32List list = Uint32List.fromList([0, 0]);

//     PacketIdRequestResponse<TestPayload, TestPayload> id = TestPacketPayloadId.testPacketId2;
//     // TestPayload payload1 = id.requestCaster(list)..build((12345678, 87654321));

//     print(list[0]);
//     print(list[1]);
//   });
// }
