/// Mixin for methods
/// Instantiate temporary object for type checking
mixin class TypeKey<T> {
  const TypeKey();

  Type get type => T;

  bool isSubtype<S>() => this is TypeKey<S>;
  bool isSupertype<S>() => TypeKey<S>() is TypeKey<T>;
  bool isExactType<S>() => S == T;
  bool get isNullable => null is T;

  bool isTypeOf(Object? object) => object is T;

  // call passing type
  R call<R>(R Function<G>() callback) => callback<T>();
  R callWithType<R>(R Function<G>() callback) => callback<T>();
}

extension TypeKeysValidate on List<TypeKey> {
  bool compareTypes(Iterable<Object?> objects) => objects.indexed.every((e) => elementAt(e.$1).isTypeOf(e.$2));
}

// workaround for calling generic methods with type restrictions
mixin class TypeRestrictedKey<T extends S, S> {
  const TypeRestrictedKey();
  R callWithRestrictedType<R>(R Function<G extends S>() callback) => callback<T>();
}

// swap implementation
// abstract mixin class SimpleCodec<S, T> implements Codec<S, T> {
//   const SimpleCodec();

//   T encode(S input);
//   S decode(T encoded);

//   Converter<S, T> get encoder => _SimpleConverter(encode);
//   Converter<T, S> get decoder => _SimpleConverter(decode);
// Codec<S, R> fuse<R>(Codec<T, R> other) { ... }
// }

// class _SimpleConverter<S, T> extends Converter<S, T> {
//   const _SimpleConverter(this._convert);
//   final T Function(S input) _convert;
//   T convert(S input) => _convert(input);
// }
