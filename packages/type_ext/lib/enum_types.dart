// inherits
//  T byName(String name)
//  Map<String, T> asNameMap()
extension type const EnumType<T extends Enum>(List<T> enumValues) implements List<T> {
  // EnumType.inUnion(Set<List<Enum>> enumValues) : this(enumValues.whereType<List<T>>().single);

  T? resolve(int? index) => (index != null) ? enumValues.elementAtOrNull(index) : null;
}

extension EnumByNullable<T extends Enum> on List<T> {
  T? resolve(int? index) => (index != null) ? elementAtOrNull(index) : null;
}

// T is only used for nested types, if the subtype implements a common type
extension type const EnumUnionType<T extends Enum>(Set<List<T>> valuesUnion) {
// extension type const EnumValuesUnion(Set<List<Enum>> valuesUnion) {
  // if S extends T then non-null is guaranteed by class definition
  List<S> subtype<S extends T>() => valuesUnion.whereType<List<S>>().single;
  S bySubtype<S extends T>(int index) => subtype<S>().elementAt(index);

  // pass any type, return nullable
  List<S>? subtypeOrNull<S extends Enum>() => valuesUnion.whereType<List<S>>().singleOrNull;
  S? resolve<S extends Enum>(int? index) => subtypeOrNull<S>()?.resolve(index);
}
