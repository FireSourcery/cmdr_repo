import 'package:type_ext/type_ext.dart';

extension EnumByNullable<T extends Enum> on List<T> {
  T? resolve(int? index) => (index != null) ? elementAtOrNull(index) : null;

  // non nullable result using default
  /// byIndexOrDefault
  Enum resolveAsBase(int index) => elementAtOrNull(index) ?? EnumUnknown.unknown; // on List<Enum>?
  /// byIndexOr
  T byIndex(int index, [T? defaultValue]) => elementAtOrNull(index) ?? defaultValue ?? first;
  // T byIndex(int index, [T? defaultValue]) => elementAtOrNull(index) ?? defaultValue ?? (throw ArgumentError.checkNotNull(defaultValue, 'defaultValue'));

  Map<V, T> asReverseMap<V>([V Function(T)? valueOf]) {
    if (valueOf != null) return {for (final key in this) valueOf(key): key};
    if (V == int) return asMap() as Map<V, T>; // index by default
    throw ArgumentError('EnumMap: $V must be defined for reverseMap');
  }

  // EnumCodec<T> asCodec() => EnumCodec.of(this);
}

// extension type const EnumType<T extends Enum>(List<T> _) implements List<T> {}

enum EnumUnknown { unknown }

// typedef EnumUnionFn = List<T> Function<T extends Enum>();

// T is only used for nested types, if the subtype implements a common type
// extension type const EnumUnionType<T extends Enum>(Set<List<T>> valuesUnion) implements Set<List<T>> {
//   // if S extends T then non-null is guaranteed by class definition
//   List<S> subtype<S extends T>() => valuesUnion.whereType<List<S>>().single;
//   S bySubtype<S extends T>(int index) => subtype<S>().elementAt(index);

//   S? resolve<S extends T>(int? index) => subtype<S>().resolve(index);

//   // List<S>? subtypeOrNull<S extends Enum>() => valuesUnion.whereType<List<S>>().singleOrNull;
//   // S? resolve<S extends Enum>(int? index) => subtypeOrNull<S>()?.resolve(index);

//   // Map<Type, Map<int, T>> asMap() {
//   //   return {for (var list in valuesUnion) list.first.runtimeType: valuesUnion.map((list) => list.asMap())};
//   // }
// }
// inherits
//  T byName(String name)
//  Map<String, T> asNameMap()
// extension type const EnumType<T extends Enum>(List<T> enums) implements List<T>, EnumMapFactory<T> {
//   EnumCodec<T> get codec => EnumCodec.of(enums);
//   EnumCodec<T?> get nullableCodec => EnumCodec.nullable(enums);
//   EnumCodec<Enum> get baseCodec => EnumCodec.base(enums);
// }

abstract mixin class Sign<T extends Sign<T>> implements Enum {
  static const _zeroIndex = 1;

  int get value => index - _zeroIndex;

// assert(T==dynamic)
  // factory Sign.of(int value) => SignId.of(value) as Sign<T>;
}

enum SignId with Sign<SignId> {
  negative, // -1
  none, //  0
  forward; //  1

  factory SignId.of(int value) => SignId.values[value + 1];
}

abstract interface class EnumCodec<V extends Enum> /* implements Codec<V> */ {
  //  final List<V> list;
  @override
  V decode(int data);
  @override
  int encode(V view);
}

class EnumCodecSign<V extends Sign<V>> implements EnumCodec<V> {
  const EnumCodecSign(this.list, [this.zeroIndex = 1]);

  final List<V> list;
  final int zeroIndex;

  @override
  V decode(int data) => switch (data) {
        -1 => list[0], // negative
        0 => list[1], // none
        1 => list[2], // forward
        _ => throw ArgumentError('Invalid sign value: $data'),
      };
  @override
  int encode(V view) => view.value;

  // asStatelessCodec() => StatelessCodec<V>(decode, encode);
}

class EnumCodecOffset<V extends Enum> implements EnumCodec<V> {
  const EnumCodecOffset(this.list, this.zeroIndex);

  final List<V> list;
  final int zeroIndex;

  @override
  V decode(int data) => list.elementAtOrNull(data - zeroIndex) ?? (throw ArgumentError('Invalid enum value: $data'));
  @override
  int encode(V view) => view.index + zeroIndex;

  // asStatelessCodec() => StatelessCodec<V>(decode, encode);
}

//by index
class EnumCodecDefault<V extends Enum> implements EnumCodec<V> {
  const EnumCodecDefault(this.list, [this.defaultValue]);

  final List<V> list;
  final V? defaultValue;

  @override
  V decode(int data) => list.byIndex(data, defaultValue);
  @override
  int encode(V view) => view.index;

  // asStatelessCodec() => StatelessCodec<V>(decode, encode);
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
