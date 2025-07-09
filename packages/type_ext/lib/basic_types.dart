import 'package:collection/collection.dart';

/// Mixin for methods
/// Instantiate temporary object for type checking
// TypeCarrier, TypeHost, TypeKey
mixin class TypeKey<T> {
  const TypeKey();

  Type get type => T;
  bool isSubtype<S>() => this is TypeKey<S>;
  bool isSupertype<S>() => TypeKey<S>() is TypeKey<T>;
  bool isExactType<S>() => S == T;
  bool get isNullable => null is T;

  bool compareType(Object? object) => object is T;
  // bool isThisType(Object? object) => object is T;

  // call passing type
  R call<R>(R Function<G>() callback) => callback<T>();
  // callGeneric, callTyped
  R callWithType<R>(R Function<G>() callback) => callback<T>();
  // R callAsKey<R>(R Function<G>(TypeKey key) callback) => callback<T>(this);
}

extension TypeKeysValidate on List<TypeKey> {
  bool compareTypes(Iterable<Object?> objects) => objects.indexed.every((e) => elementAt(e.$1).compareType(e.$2));
}

// mixin TypeKeyFactory<T> on TypeKey<T> {
//   T constructor() => throw UnimplementedError('TypeKeyFactory.create() must be implemented in subclass');
// }

// workaround for calling generic methods with type restrictions
mixin class TypeRestrictedKey<T extends S, S> {
  const TypeRestrictedKey();
  R callWithRestrictedType<R>(R Function<G extends S>() callback) => callback<T>();
}

/// [Range] types
typedef NumRange = ({num min, num max});
typedef EnumRange = List<Enum>;

/// [Stringifier]
typedef Stringifier<T> = String Function(T input);
typedef NullableStringifier<T> = String Function(T? input);
typedef GenericStringifier = String Function<T>(T input);
// typedef GenericStringifier = String Function<T>(T? input); // pass non-nullable type allows null input, cases where T is used for selection

/// [Slicer]
mixin Sliceable<T extends Sliceable<dynamic>> {
  // int get start => 0;
  int get totalLength;
  T slice(int start, int end);

  Iterable<T> slices(int sliceLength) sync* {
    for (var index = 0; index < totalLength; index += sliceLength) {
      yield slice(index, (totalLength - index).clamp(0, totalLength));
    }
  }
}

class Slicer<T> {
  const Slicer(this.slicer, this.length);
  final T Function(int start, int end) slicer;
  final int length;
  // final int start;

  Iterable<T> slices(int sliceLength) sync* {
    for (var index = 0; index < length; index += sliceLength) {
      yield slicer(index, (length - index).clamp(0, length));
    }
  }
}

/// [PropertyFilter]
// filterable property
// encapsulated for selection
// implements Enum for List
// PropertyOf<T>
abstract mixin class PropertyFilter<T> {
  const PropertyFilter();

  ValueTest<T> get test;

  Iterable<T> call(Iterable<T> input) => input.where(test);
  Iterable<T> Function(Iterable<T> input) get asIterableFilter => call;
}

typedef ValueTest<T> = bool Function(T input);

extension WhereFilter<T> on Iterable<T> {
  Iterable<T> filter(Iterable<T> Function(Iterable<T> input)? filter) => filter?.call(this) ?? this;
  Iterable<T> havingProperty(PropertyFilter<T>? property) => property?.call(this) ?? this;
  // Iterable<T> havingTyped<P extends PropertyFilter<T>>(Iterable<List<PropertyFilter<T>>> allProperties, P filter) {
  Iterable<T> havingTyped<P extends PropertyFilter<T>>(Iterable<List<PropertyFilter<T>>> allProperties) {
    return allProperties.whereType<List<P>>().whereType<P>().singleOrNull?.call(this) ?? this;
  }
}

// naming convention notes
// For classes and types -
// consider Module/Most descriptive noun first, then adjective descriptions
// this way Aligns characters
// allows the first word to be the module/group name
// unlike objects types are not called with dot notation, so placing the most descriptive noun last is less meaningful
