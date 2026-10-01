///
/// [BinaryCodec<V>]
///
abstract interface class const BinaryCodec<V>._() {
  static const BinaryCodec<int> identity = BinaryCodecIdentity._();

  V decode(int data);
  int encode(V view);
}

typedef DataDecoder<T> = T Function(int data);
typedef DataEncoder<T> = int Function(T view);

class const BinaryCodecByHandlers<V>({
  required final DataDecoder<V> decoder,
  required final DataEncoder<V> encoder,
}) implements BinaryCodec<V> {
  @override
  V decode(int data) => decoder(data);
  @override
  int encode(V view) => encoder(view);
}

class const BinaryCodecIdentity._() implements BinaryCodec<int> {
  @override
  int decode(int data) => data;
  @override
  int encode(int view) => view;
}

// default implementation for num codec, can be overridden for specialized handling of double or other num types.
extension BinaryCodecAsNum<V extends num> on BinaryCodec<V> {
  // all types can be represented as num by binary value, num codecs use the codec.
  num decodeAsNum(int data) {
    return switch (V) {
      const (double) || const (num) => decode(data) as num,
      _ => data,
    };
  }

  int encodeAsNum(num view) {
    return switch (V) {
      const (double) || const (num) => encode(view as V),
      _ => view.toInt(),
    };
  }
}
