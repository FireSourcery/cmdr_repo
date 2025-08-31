/// Mixin for methods
/// Instantiate temporary object for type checking
// TypeCarrier, TypeHelper
mixin class TypeKey<T> {
  const TypeKey();

  Type get type => T;

  // if (TypeKey<T> is TypeKey<S>)
  bool isSubtype<S>() => this is TypeKey<S>;
  bool isSupertype<S>() => TypeKey<S>() is TypeKey<T>;
  bool isExactType<S>() => S == T;
  bool get isNullable => null is T;

  bool compareType(Object? object) => object is T;
  bool isTypeOf(Object? object) => object is T;

  // call passing type
  R call<R>(R Function<G>() callback) => callback<T>();
  // callGeneric, callTyped, callPassingType, passType
  R callWithType<R>(R Function<G>() callback) => callback<T>();
}

extension TypeKeysValidate on List<TypeKey> {
  bool compareTypes(Iterable<Object?> objects) => objects.indexed.every((e) => elementAt(e.$1).compareType(e.$2));
}

// mixin TypeKeyFactory<T> on TypeKey<T> {
//   T constructor() => throw UnimplementedError('TypeKeyFactory.create() must be implemented in subclass');
// }

// workaround for calling generic methods with type restrictions
// SubtypeKey
mixin class TypeRestrictedKey<T extends S, S> {
  const TypeRestrictedKey();
  R callWithRestrictedType<R>(R Function<G extends S>() callback) => callback<T>();
}

///
typedef ValueTest<T> = bool Function(T input);

/// [Range] types
typedef NumRange = ({num min, num max});
typedef EnumRange = List<Enum>;

/// [Stringifier]
typedef Stringifier<T> = String Function(T input);
typedef NullableStringifier<T> = String Function(T? input);
typedef GenericStringifier = String Function<T>(T input);
// typedef GenericStringifier = String Function<T>(T? input); // non-nullable type, with nullable input, cases where T is used for selection

// naming convention notes
// For classes and types -
// consider Module/Most descriptive noun first, then adjective descriptions
// this way Aligns characters
// allows the first word to be the module/group name
// unlike objects types are not called with dot notation, so placing the most descriptive noun last is less meaningful
