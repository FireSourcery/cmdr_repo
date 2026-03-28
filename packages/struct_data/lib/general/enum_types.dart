extension EnumByIndex<T extends Enum> on List<T> {
  T byIndex(int index, [T? defaultValue]) => elementAt(index.clamp(0, length - 1));

  T? resolve(int? index) => (index != null) ? byIndex(index) : null;

  EnumCodec<T> asCodec() => EnumCodecDefault(this);
}

abstract interface class EnumCodec<V extends Enum> /* implements Codec<V> */ {
  List<V> get values;
  V decode(int data);
  int encode(V view);
}

abstract mixin class EnumCodecByIndex<V extends Enum> implements EnumCodec<V> {
  @override
  V decode(int data) => values.byIndex(data);
  @override
  int encode(V view) => view.index;
}

// in negative to positive order. [-2, -1, 0, 1, 2], zeroIndex == 2
abstract mixin class EnumCodecByOffset<V extends Enum> implements EnumCodec<V> {
  int get zeroIndex;
  @override
  V decode(int data) => values.byIndex(data + zeroIndex);
  @override
  int encode(V view) => view.index - zeroIndex;
}

class EnumCodecByHandlers<V extends Enum> implements EnumCodec<V> {
  const EnumCodecByHandlers({required this.values, required this.decoder, required this.encoder});
  @override
  final List<V> values;
  final V Function(int data) decoder;
  final int Function(V view) encoder;

  @override
  V decode(int data) => decoder(data);
  @override
  int encode(V view) => encoder(view);
}

/// concrete
class EnumCodecDefault<V extends Enum> with EnumCodecByIndex<V> {
  const EnumCodecDefault(this.values);
  final List<V> values;
}

class EnumCodecOffset<V extends Enum> with EnumCodecByOffset<V> {
  const EnumCodecOffset(this.values, this.zeroIndex);
  final List<V> values;
  final int zeroIndex;
}

class EnumCodecSign<V extends Enum> with EnumCodecByOffset<V> {
  const EnumCodecSign(this.values);
  final List<V> values;
  final int zeroIndex = 1; // default to offset of 1 for sign enums with -1, 0, 1 values
}

// optional or move to models
///
// abstract mixin class Sign<T extends Sign<T>> implements Enum {
//   EnumCodecSign<T> get codec;
//   // T of(int value) => codec.decode(value);

//   int get value => codec.encode(this as T);
// }

// enum SignId with Sign<SignId> {
//   minus, // -1
//   none, //  0
//   plus; //  1

//   static const EnumCodecSign<SignId> factory = EnumCodecSign<SignId>(SignId.values);
//   @override
//   EnumCodecSign<SignId> get codec => factory;
// }

// class EnumUnionCodec<V extends Enum> implements EnumCodec<V> {
//   const EnumUnionCodec(this.codecs);

//   final Map<Type, List<V>> codecs;
//   @override
//   List<V> get values => codecs[V] ?? (throw UnsupportedError('EnumUnionCodec: No codec for type $V'));

//   @override
//   V decode(int data) => values.byIndex(data);

//   @override
//   int encode(V view) => view.index;
// }
