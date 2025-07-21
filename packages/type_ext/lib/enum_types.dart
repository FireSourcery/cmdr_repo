// inherits
//  T byName(String name)
//  Map<String, T> asNameMap()
extension type const EnumType<T extends Enum>(List<T> enumValues) implements List<T> {
  // EnumType.inUnion(Set<List<Enum>> enumValues) : this(enumValues.whereType<List<T>>().single);

  // T? resolve(int? index) => (index != null) ? enumValues.elementAtOrNull(index) : null;
}

extension EnumByNullable<T extends Enum> on List<T> {
  T? resolve(int? index) => (index != null) ? elementAtOrNull(index) : null;
}

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
