import 'dart:ffi';
import 'dart:typed_data';

import 'package:struct_data/packet/packet.dart';

/// A fixed-size payload: two 32-bit words, cast in place over the packet's payload region.
@Packed(1)
final class EchoPayload extends Struct implements Payload<(int, int)> {
  @Uint32()
  external int value0;
  @Uint32()
  external int value1;

  factory EchoPayload({int value1 = 0, int value0 = 0}) => Struct.create<EchoPayload>()..build((value1, value0));

  /// Ensures `Struct.create<EchoPayload>` is compiled ahead of time.
  factory EchoPayload.cast(TypedData typedData) => Struct.create<EchoPayload>(typedData);

  @override
  PayloadMeta build((int, int) args) {
    final (newValue0, newValue1) = args;
    value0 = newValue0;
    value1 = newValue1;
    return const PayloadMeta(8);
  }

  /// Fixed size, so the header's declared length is not consulted.
  @override
  (int, int) parse(PacketHeader header) => (value0, value1);
}
