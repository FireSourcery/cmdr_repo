export 'binary_format.dart';

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

// canonical form in num to include double.
// abstract interface class NumCodec<V> {
//   const NumCodec._();

//   V decode(covariant num data);
//   num encode(V view);
// }

// swap implementation
// class StorageConverter<S, T> with Converter<S, T> {
//   const StorageConverter(this._convert);
//   final T Function(S input) _convert;
//   @override
//   T convert(S input) => _convert(input);
// }

// abstract mixin class StorageCodec<S, T> implements Codec<S, T> {
//   const StorageCodec._();

//   Converter<S, T> get encoder => StorageConverter(encode);
//   Converter<T, S> get decoder => StorageConverter(decode);
//   T encode(S input);
//   S decode(T encoded);
// }
