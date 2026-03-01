import 'package:binary_data/data/enum_types.dart';
import 'package:binary_data/data/num_ext.dart';

import '../bits/bit_struct.dart';
import 'binary_format.dart';

export 'binary_format.dart';

///
/// [BinaryCodec<V>]
///
abstract interface class BinaryCodec<V> {
  const BinaryCodec._();

  V decode(int data);
  int encode(V view);
}

typedef DataDecoder<T> = T Function(int data);
typedef DataEncoder<T> = int Function(T view);

class BinaryCodecByHandlers<V> implements BinaryCodec<V> {
  const BinaryCodecByHandlers({required this.decoder, required this.encoder});

  final DataDecoder<V> decoder;
  final DataEncoder<V> encoder;

  @override
  V decode(int data) => decoder(data);
  @override
  int encode(V view) => encoder(view);
}
