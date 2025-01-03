// inherits
//  T byName(String name)
//  Map<String, T> asNameMap()
///
extension type const EnumType<T extends Enum>(List<T> enumValues) implements List<Enum> {
  EnumType.inUnion(Set<List<Enum>> enumValues) : this(enumValues.whereType<List<T>>().single);

  T resolve(int index) => enumValues[index];
  T? resolveOrNull(int? index) => index != null ? enumValues.elementAtOrNull(index) : null;
}

// abstract class EnumTypeUnion<T extends Enum> {
// Set<List<T>> get valuesUnion;
// unlikely T is used, if the subtype implements a common type, then there would be no need to invert dependency
extension type const EnumTypeUnion<T extends Enum>(Set<List<T>> valuesUnion) {
  // if S extends T then non-null is guaranteed by class definition
  List<S> valueSubtype<S extends T>() => valuesUnion.whereType<List<S>>().single;
  S valueOf<S extends T>(int index) => valueSubtype<S>().elementAt(index);

  List<S>? valueSubtypeOrNull<S>() => valuesUnion.whereType<List<S>>().singleOrNull;
  S? valueOrNullOf<S>(int? index) => (index == null) ? null : valueSubtypeOrNull<S>()?.elementAtOrNull(index);
}

// //
// extension type const UnresolvedEnum<T extends Enum>._(T enumValue) implements Enum {
//   UnresolvedEnum( int index) : this._( );
//   UnresolvedEnum.ofSuper(  int index) : this._(enumValues.whereType<List<T>>().single[index]);
// }

// extension type const UnresolvedEnumValue<T extends Enum>._(T enumValue) implements UnresolvedEnum<T>, Enum {
//   UnresolvedEnumValue(List<T> enumValues, int index) : this._(enumValues[index]);
//   UnresolvedEnumValue.ofSuper(Set<List<Enum>> enumValues, int index) : this._(enumValues.whereType<List<T>>().single[index]);
// }

// extension type const UnresolvedEnumNull<T extends Enum>._(Null enumValue) implements UnresolvedEnum<Never> {
//   UnresolvedEnumNull() : this._(null);
// }

// extension type const UnresolvedEnum<T extends Enum>._(int? enumIndex) {}
// class UnresolvedEnum<T extends Enum> {
//   const UnresolvedEnum(this.index);
//   final int index;

//   T resolveWith(List<T> enumValues) => enumValues[index];
//   T resolveWithSuper(Set<List<Enum>> enumValues) => enumValues.whereType<List<T>>().single[index];

//   T? resolveWithOrNull(List<T> enumValues) => enumValues.elementAtOrNull(index);
//   T? resolveWithSuperOrNull(Set<List<Enum>> enumValues) => enumValues.whereType<List<T>>().single.elementAtOrNull(index);
// }
