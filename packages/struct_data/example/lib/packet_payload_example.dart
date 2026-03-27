import 'dart:ffi';
import 'dart:typed_data';

import 'package:struct_data/packet/packet.dart';

@Packed(1)
final class EchoPayload extends Struct implements Payload<(int, int)> {
  @Uint32()
  external int value0;
  @Uint32()
  external int value1;

  factory EchoPayload({int value1 = 0, int value0 = 0}) => Struct.create<EchoPayload>()..build((value1, value0));

  factory EchoPayload.cast(TypedData typedData) => Struct.create<EchoPayload>(typedData); // ensures Struct.create<EchoPayload> is compiled at compile time

  @override
  PayloadMeta build((int, int) args, [Packet? header]) {
    final (newValue0, newValue1) = args;
    value0 = newValue0;
    value1 = newValue1;
    return const PayloadMeta(8);
  }

  @override
  (int, int) parse([Packet? header, void stateMeta]) {
    return (value0, value1);
  }
}

enum PacketIdRequestExample<T, R> implements PacketIdRequest<T, R> {
  echo(0xFF, requestCaster: EchoPayload.cast, responseCaster: EchoPayload.cast)
  ;

  const PacketIdRequestExample(this.intId, {required this.requestCaster, required this.responseCaster, this.responseId});

  @override
  final int intId;
  @override
  final PacketId? responseId;
  @override
  final PayloadCaster<T>? requestCaster;
  @override
  final PayloadCaster<R>? responseCaster;
}
