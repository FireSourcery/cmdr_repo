// abstract mixin class EnumStatus implements Enum, Exception {
//   String get message => name;
// }

// inherits
//  T byName(String name)
//  Map<String, T> asNameMap()
import 'dart:math';

// when inverting implements dependency is preferable
// alternative to EnumSubtype implements EnumInterface
// optionally constrain T to EnumSubtype
// extension type const EnumTypeUnion<T>(Set<List<T>> valuesUnion) {
//   // abstract class EnumTypeUnion<T extends Enum> {
//   // Set<List<T>> get valuesUnion;

//   // if S extends T then non-null is guaranteed by class definition
//   List<S> values<S extends T>() => valuesUnion.whereType<List<S>>().single;

//   S valueOf<S extends T>(int index) => values<S>().elementAt(index);

//   S? valueOrNullOf<S extends T>(int? index) => (index == null) ? null : values<S>().elementAtOrNull(index);
// }

// unlikely T is used, if the subtype implements a common type, then there would be no need to invert dependency
extension type const EnumTypeUnion<T extends Enum>(Set<List<T>> valuesUnion) {
  // abstract class EnumTypeUnion<T extends Enum> {
  // Set<List<T>> get valuesUnion;

  // if S extends T then non-null is guaranteed by class definition
  List<S> valueSubtype<S extends T>() => valuesUnion.whereType<List<S>>().single;
  S valueOf<S extends T>(int index) => valueSubtype<S>().elementAt(index);

  List<S>? valueSubtypeOrNull<S>() => valuesUnion.whereType<List<S>>().single;
  S? valueOrNullOf<S>(int? index) => (index == null) ? null : valueSubtypeOrNull<S>()?.elementAtOrNull(index);
}

// is a base class needed?
// abstract class EnumUnion<T extends Enum> {
//   const EnumUnion._(this.value);
//   // const factory MotStatus.cast(T status) = MotStatus<T>._; // Type defined and inferred by arg
//   // // Type defined by type parameter input
//   EnumUnion.index(Set<List<Enum>> valuesUnion, int index) : this._(EnumTypeUnion<Enum>(valuesUnion).valueOf<T>(index));

//   // static T of<T extends EnumUnion>(int index) => enumType.valueOf<T>(index);
//   //   EnumTypeUnion get enumType;

//   final Enum? value;
// }


// extension type const EnumResolver<T extends Enum>._(T enumValue) implements Enum {
//   EnumResolver(List<T> enumValues, int index) : this._(enumValues[index]);
//   EnumResolver.ofSuper(Set<List<Enum>> enumValues, int index) : this._(enumValues.whereType<List<T>>().single[index]);
// }

// //
// extension type const UnresolvedEnum<T extends Enum>._(T? enumValue) {
//   UnresolvedEnum(List<T> enumValues, int index) : this._(enumValues[index]);
//   UnresolvedEnum.ofSuper(Set<List<Enum>> enumValues, int index) : this._(enumValues.whereType<List<T>>().single[index]);
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

// class UnresolvedEnumNull<T extends Enum> extends UnresolvedEnum<T> {
//   const UnresolvedEnumNull() : super(-1);

//   @override
//   T resolveWith(List<T> enumValues) => throw UnsupportedError('UnresolvedEnumNull.resolveWith');
//   @override
//   T resolveWithSuper(Set<List<Enum>> enumValues) => throw UnsupportedError('UnresolvedEnumNull.resolveWithSuper');

//   @override
//   T? resolveOrNullWith(List<T> enumValues) => null;
//   @override
//   T? resolveOrNullWithSuper(Set<List<Enum>> enumValues) => null;
// }
