/// enum data utilities
/// codec using Enum.values
library;

extension EnumByIndex<T extends Enum> on List<T> {
  T byIndex(int index, [T? defaultValue]) => elementAt(index.clamp(0, length - 1));

  T? resolve(int? index) => (index != null) ? elementAtOrNull(index) : null;

  EnumCodec<T> asCodec() => EnumCodecDefault(this);
}

abstract interface class EnumCodec<V extends Enum> {
  const factory EnumCodec(List<V> values) = EnumCodecDefault;

  List<V> get values;
  V decode(int data);
  int encode(V view);
}

abstract mixin class EnumCodecByIndex<V extends Enum>() implements EnumCodec<V> {
  @override
  V decode(int data) => values.byIndex(data);
  @override
  int encode(V view) => view.index;
}

// in negative to positive order. [-2, -1, 0, 1, 2], zeroIndex == 2
abstract mixin class EnumCodecByOffset<V extends Enum>() implements EnumCodec<V> {
  int get zeroIndex;
  @override
  V decode(int data) => values.byIndex(data + zeroIndex);
  @override
  int encode(V view) => view.index - zeroIndex;
}

class const EnumCodecByHandlers<V extends Enum>({@override required final List<V> values, required final V Function(int data) decoder, required final int Function(V view) encoder})
    implements EnumCodec<V> {
  @override
  V decode(int data) => decoder(data);
  @override
  int encode(V view) => encoder(view);
}

/// concrete
class const EnumCodecDefault<V extends Enum>(@override final List<V> values) with EnumCodecByIndex<V> {}

class const EnumCodecOffset<V extends Enum>(@override final List<V> values, @override final int zeroIndex) with EnumCodecByOffset<V> {}

class const EnumCodecSign<V extends Enum>(@override final List<V> values) with EnumCodecByOffset<V> {
  @override
  final int zeroIndex = 1; // default to offset of 1 for sign enums with -1, 0, 1 values
}

extension EnumCodecResolve<T extends Enum> on EnumCodec<T> {
  T? resolve(int? data) => (data != null) ? decode(data) : null;
}

class EnumUnionCodec<S extends Enum> {
  EnumUnionCodec(this.codecs);
  EnumUnionCodec.of(Set<List<S>> codecs) : codecs = {for (var c in codecs) c.first.runtimeType: c};

  final Map<Type, List<S>> codecs;

  List<T> valuesTyped<T extends S>() => codecs[T] as List<T>? ?? (throw UnsupportedError('EnumUnionCodec: No codec for type $T'));

  @override
  List<S> get values => codecs.values.expand((e) => e).toList();

  T? resolve<T extends S>(int? data) => (data != null) ? valuesTyped<T>().byIndex(data) : null;
}
