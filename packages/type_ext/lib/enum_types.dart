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

extension type const EnumType<T extends Enum>(List<T> _) implements List<T> {}

enum EnumUnknown { unknown }

// T is only used for nested types, if the subtype implements a common type
extension type const EnumUnionType<T extends Enum>(Set<List<T>> valuesUnion) implements Set<List<T>> {
  // if S extends T then non-null is guaranteed by class definition
  List<S> subtype<S extends T>() => valuesUnion.whereType<List<S>>().single;
  S bySubtype<S extends T>(int index) => subtype<S>().elementAt(index);

  S? resolve<S extends T>(int? index) => subtype<S>().resolve(index);

  // List<S>? subtypeOrNull<S extends Enum>() => valuesUnion.whereType<List<S>>().singleOrNull;
  // S? resolve<S extends Enum>(int? index) => subtypeOrNull<S>()?.resolve(index);

  // alternatively as status unions
  // pass any type, return nullable
  // without extends Enum, for work around subtype issues
  // List<S>? _resolveSubtype<S>() => valuesUnion.whereType<List<S>>().singleOrNull;
  // S? resolveSubtype<S>(int? index) => (_resolveSubtype<S>() as List<Enum>?)?.resolve(index) as S?;

  // Map<Type, Map<int, T>> asMap() {
  //   return {for (var list in valuesUnion) list.first.runtimeType: valuesUnion.map((list) => list.asMap())};
  // }
}

abstract mixin class Sign<T extends Sign<T>> implements Enum {
  static const _zeroIndex = 1;

  int get value => index - _zeroIndex;

// assert(T==dynamic)
  factory Sign.of(int value) => SignId.of(value) as Sign<T>;
}

enum SignId with Sign<SignId> {
  negative, // -1
  none, //  0
  forward; //  1

  factory SignId.of(int value) => SignId.values[value + 1];
}

// extension type const OffsetEnumType<T extends Enum>((List<T> enums, int zeroIndex) _) {
//   // const OffsetEnumType ( List<T> enums, int zeroIndex ) : _ = (enums, zeroIndex);
//   T factory(int value) => _.$1.elementAt(value - _.$2);
//   int value(T e) => e.index + _.$2;
//   int call(T e) => e.index + _.$2;
// }

// enum SignId1 {
//   negative, // -1
//   none, //  0
//   forward; //  1

//   factory SignId1.of(int value) => const OffsetEnumType((SignId1.values, 1)).factory(value);
//   get value => const OffsetEnumType((SignId1.values, 1))(this);
// }

// inherits
//  T byName(String name)
//  Map<String, T> asNameMap()
// extension type const EnumType<T extends Enum>(List<T> enums) implements List<T>, EnumMapFactory<T> {
//   EnumCodec<T> get codec => EnumCodec.of(enums);
//   EnumCodec<T?> get nullableCodec => EnumCodec.nullable(enums);
//   EnumCodec<Enum> get baseCodec => EnumCodec.base(enums);
// }

// class EnumCodec<V extends Enum> /* implements Codec<V> */ {
//   /// Enum subtype, in case a value other than enum.index is selected
//   const EnumCodec({required this.decoder, required this.encoder, required this.enumRange});

//   /// [byIndex] returns first on out of range input
//   EnumCodec.of(this.enumRange)
//       : decoder = enumRange.byIndex,
//         encoder = _defaultEnumEncoder;

//   /// [byIndexOrNull] returns null on out of range input
//   EnumCodec.nullable(this.enumRange)
//       : assert(null is V),
//         decoder = enumRange.elementAtOrNull,
//         encoder = _defaultEnumEncoder;

//   /// throw if V is not exactly type Enum, returns non-nullable Enum
//   EnumCodec.base(this.enumRange)
//       : assert(V == Enum),
//         decoder = enumRange.resolveAsBase,
//         encoder = _defaultEnumEncoder;

//   static int _defaultEnumEncoder(Enum view) => view.index;

//   @override
//   V decode(int data) => decoder.call(data);
//   @override
//   int encode(V view) => encoder.call(view);
// }
