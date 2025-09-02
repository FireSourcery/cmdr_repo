// inherits
//  T byName(String name)
//  Map<String, T> asNameMap()
extension type const EnumType<T extends Enum>(List<T> enumValues) implements List<T> {
  // EnumType.inUnion(Set<List<Enum>> enumValues) : this(enumValues.whereType<List<T>>().single);

  // T? resolve(int? index) => (index != null) ? enumValues.elementAtOrNull(index) : null;
}

extension EnumByNullable<T extends Enum> on List<T> {
  T? resolve(int? index) => (index != null) ? elementAtOrNull(index) : null;

  // non nullable result using default
  /// byIndexOrDefault
  Enum resolveAsBase(int index) => elementAtOrNull(index) ?? EnumUnknown.unknown; // on List<Enum>?
  /// byIndexOr
  T byIndex(int index, [T? defaultValue]) => elementAtOrNull(index) ?? defaultValue ?? first;
}

enum EnumUnknown { unknown }

// T is only used for nested types, if the subtype implements a common type
// extension type const EnumValuesUnion(Set<List<Enum>> valuesUnion) {
extension type const EnumUnionType<T extends Enum>(Set<List<T>> valuesUnion) implements Set<List<T>> {
  // if S extends T then non-null is guaranteed by class definition
  List<S> subtype<S extends T>() => valuesUnion.whereType<List<S>>().single;
  S bySubtype<S extends T>(int index) => subtype<S>().elementAt(index);

  List<S>? subtypeOrNull<S extends Enum>() => valuesUnion.whereType<List<S>>().singleOrNull;
  S? resolve<S extends Enum>(int? index) => subtypeOrNull<S>()?.resolve(index);

  // alternatively as status unions
  // pass any type, return nullable
  // without extends Enum, for work around subtype issues
  List<S>? _resolveSubtype<S>() => valuesUnion.whereType<List<S>>().singleOrNull;
  S? resolveSubtype<S>(int? index) => (_resolveSubtype<S>() as List<Enum>?)?.resolve(index) as S?;

  // Map<Type, Map<int, T>> asMap() {
  //   return {for (var list in valuesUnion) list.first.runtimeType: valuesUnion.map((list) => list.asMap())};
  // }
}

// extension type const EnumIdFactory<K extends Enum, V>._(Map<V, K> reverseMap) {
//   EnumIdFactory.of(List<K> keys) : reverseMap = EnumMap.buildReverseMap<K, V>(keys);
//   K? idOf(V mappedValue) => reverseMap[mappedValue];

// static Map<V, K> buildReverse<K extends Enum, V>(List<K> keys, [V Function(K)? valueOf]) {
//   if (valueOf != null) {
//     return keys.asReverseMap(valueOf);
//   } else if (V == int) {
//     return keys.asMap() as Map<V, K>; // index by default
//   } else {
//     throw ArgumentError('EnumMap: $V must be defined for reverseMap');
//   }
//   // assert(V == int, 'EnumMap: $V must be defined for reverseMap');
// }
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

//   final DataDecoder<V> decoder;
//   final DataEncoder<V> encoder;
//   final List<V> enumRange;

//   static int _defaultEnumEncoder(Enum view) => view.index;

//   @override
//   V decode(int data) => decoder.call(data);
//   @override
//   int encode(V view) => encoder.call(view);
// }
