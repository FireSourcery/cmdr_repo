import 'dart:math';

extension EnumByNullable<T extends Enum> on List<T> {
  T byIndex(int index, [T? defaultValue]) => elementAtOrNull(index) ?? defaultValue ?? elementAt(min(index, length - 1));

  T? resolve(int? index) => (index != null) ? elementAtOrNull(index) : null;

  Map<V, T> asReverseMap<V>([V Function(T)? valueOf]) {
    if (valueOf != null) return {for (final key in this) valueOf(key): key};
    if (V == int) return asMap() as Map<V, T>; // index by default
    throw ArgumentError('EnumMap: $V must be defined for reverseMap');
  }

  // EnumCodec<T> asCodec() => EnumCodec.of(this);
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

class EnumCodecDefault<V extends Enum> with EnumCodecByIndex<V> {
  const EnumCodecDefault(this.values, [this.defaultValue]);

  final List<V> values;
  final V? defaultValue;

  V decode(int data) => values.byIndex(data, defaultValue);
}

///
abstract mixin class Sign<T extends Sign<T>> implements Enum {
  // as class variables
  // @protected
  EnumCodecSign<T> get codec;
  T of(int value) => codec.decode(value);

  int get value => codec.encode(this as T);
}

enum SignId with Sign<SignId> {
  minus, // -1
  none, //  0
  plus; //  1

  static const EnumCodecSign<SignId> factory = EnumCodecSign<SignId>(SignId.values);
  @override
  EnumCodecSign<SignId> get codec => factory;
}

// class EnumUnionCodecDefault {
//   const EnumUnionCodecDefault(this.switcher);

//   final List<T> Function<T extends Enum>() switcher;

//   @override
//   V decodeAs<V extends Enum>(int data) => switcher<V>().byIndex(data);
//   @override
//   int encodeAs<V extends Enum>(V view) => view.index;
// }

// class EnumUnionCodecMapDefault {
//   const EnumUnionCodecMapDefault(this.map);

//   final Map<Type, List<Enum>> map;

//   @override
//   V decodeAs<V extends Enum>(int data) => map[V]!.byIndex(data) as V;
//   @override
//   int encodeAs<V extends Enum>(V view) => view.index;
// }
// T is only used for nested types, if the subtype implements a common type
// extension type const EnumUnionType<T extends Enum>(Set<List<T>> valuesUnion) implements Set<List<T>> {
//   // if S extends T then non-null is guaranteed by class definition
//   List<S> subtype<S extends T>() => valuesUnion.whereType<List<S>>().single;
//   S bySubtype<S extends T>(int index) => subtype<S>().elementAt(index);

//   S? resolve<S extends T>(int? index) => subtype<S>().resolve(index);

//   // List<S>? subtypeOrNull<S extends Enum>() => valuesUnion.whereType<List<S>>().singleOrNull;
//   // S? resolve<S extends Enum>(int? index) => subtypeOrNull<S>()?.resolve(index);

//   // Map<Type, Map<int, T>> asMap() {
//   //   return {for (var values in valuesUnion) values.first.runtimeType: valuesUnion.map((list) => list.asMap())};
//   // }
// }
