// inherits
//  T byName(String name)
//  Map<String, T> asNameMap()
//
extension type const EnumType<T extends Enum>(List<T> enumValues) implements List<Enum> {
  // EnumType.inUnion(Set<List<Enum>> enumValues) : this(enumValues.whereType<List<T>>().single);

  T resolve(int index) => enumValues[index];
  T? resolveOrNull(int? index) => index != null ? enumValues.elementAtOrNull(index) : null;
}

// T is only used, if the subtype implements a common type
extension type const EnumTypeUnion<T extends Enum>(Set<List<T>> valuesUnion) {
  // if S extends T then non-null is guaranteed by class definition
  List<S> resolveSubtype<S extends T>() => valuesUnion.whereType<List<S>>().single;
  S resolve<S extends T>(int index) => resolveSubtype<S>().elementAt(index);

  List<S>? resolveSubtypeOrNull<S>() => valuesUnion.whereType<List<S>>().singleOrNull;
  S? resolveOrNull<S>(int? index) => (index == null) ? null : resolveSubtypeOrNull<S>()?.elementAtOrNull(index);
}
