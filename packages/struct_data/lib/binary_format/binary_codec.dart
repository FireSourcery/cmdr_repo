///
/// [BinaryCodec<V>]
///
abstract interface class BinaryCodec<V> {
  const BinaryCodec._();

  static const BinaryCodec<int> identity = BinaryCodecIdentity._();

  V decode(int data);
  int encode(V view);

  // default implementation for num codec, can be overridden for specialized handling of double or other num types.
  // num decodeAsNum(int data) => data;
  // int encodeAsNum(num view) => view as int;
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

class BinaryCodecIdentity implements BinaryCodec<int> {
  const BinaryCodecIdentity._();

  @override
  int decode(int data) => data;
  @override
  int encode(int view) => view;
}

extension BinaryCodecAsNum<V> on BinaryCodec<V> {
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
