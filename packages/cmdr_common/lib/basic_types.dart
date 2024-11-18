typedef Stringifier<T> = String Function(T input);
typedef GenericStringifier = String Function<T>(T input);
typedef NullableStringifier<T> = String Function(T? input); // defining non-nullable type allows null input, cases where T is used for selection

// abstract mixin class StringifierMixin<T>  {
//   ValueGetter<T?> get valueGetter;
//   ValueGetter<String>? get valueStringGetter;
//   Stringifier<T>? get valueStringifier;

//   static String _stringifyDefault(Object? value) => value.toString(); // unhandled null value string
//   Stringifier<T> get _effectiveStringifier => valueStringifier ?? _stringifyDefault;

//   Stringifier<T?> get _effectiveNullableStringifier {
//     if (valueStringifier case Stringifier<T?> stringifier) stringifier;
//     return _stringifyDefault;
//   }

//   String _stringifyValue() {
//     if (valueGetter() case T value) return _effectiveStringifier(value);
//     return 'Value Error'; // or handle null

//     // _effectiveNullableStringifier(valueGetter());
//   }

//   ValueGetter<String> get _effectiveValueStringGetter => valueStringGetter ?? _stringifyValue;

// }

typedef ValueTest<T> = bool Function(T input);

// encapsulated for selection
// implements Enum for List
// PropertyOf<T>
abstract mixin class PropertyFilter<T> {
  const PropertyFilter();

  ValueTest<T> get test;

  Iterable<T> call(Iterable<T> input) => input.where(test);
  Iterable<T> Function(Iterable<T> input) get asIterableFilter => call;
}

extension WhereFilter<T> on Iterable<T> {
  // havingProperty
  Iterable<T> whereFilter(PropertyFilter<T>? filter) => filter?.call(this) ?? this;
  // whereFilter
  Iterable<T> filter(Iterable<T> Function(Iterable<T> input)? filter) => filter?.call(this) ?? this;
}

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

  // call passing type
  R call<R>(R Function<G>() callback) => callback<T>();
  // callGeneric, callTyped
  R callWithType<R>(R Function<G>() callback) => callback<T>();
  // R callAsKey<R>(R Function<G>(TypeKey key) callback) => callback<T>(this);
}

// workaround for calling generic methods with type restrictions
mixin class TypeRestrictedKey<T extends S, S> {
  const TypeRestrictedKey();
  R callWithRestrictedType<R>(R Function<G extends S>() callback) => callback<T>();
}

/// Union of generic types
// A primitive union type key
// boundary depending on type
abstract mixin class UnionTypeKey<V> implements TypeKey<V> {
  const UnionTypeKey();

  List<Enum>? get valueEnumRange; // EnumSubtype.values must be non-null for Enum types
  // Limits as the values the num can take, compare with >= and <=
  ({num min, num max})? get valueNumLimits; // must be null for non-num types
  V? get valueDefault;
}

// does not implement Enum, as it can be a union of Enums
abstract mixin class Status implements Exception {
  int get code;
  String get message;
  bool get isSuccess => code == 0;
  bool get isError => code != 0;
  Enum get enumId;
}

// naming convention notes
// For classes and types -
// Module/Most descriptive noun first, then adjective descriptions
// this way Aligns characters
// allows the first word to be the module/group name
// unlike objects types are not called with dot notation, so placing the most descriptive noun last is less meaningful
