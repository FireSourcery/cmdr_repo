// import 'package:flutter/foundation.dart';

typedef KeyValuePair<K, V> = (K key, V value);
typedef KeyValueEntry<K, V> = ({K key, V value});

typedef Stringifier<T> = String Function(T input);
// typedef Stringifier<T> = String Function(T? input);

typedef ValueTest<T> = bool Function(T input);

// filter with a name
abstract mixin class PropertyFilter<T> implements Enum {
  const PropertyFilter();

  ValueTest<T> get test;

  Iterable<T> call(Iterable<T> input) => input.where(test);

  // IterableFilter<T> get asIterableFilter => call;
}

extension WhereFilter<T> on Iterable<T> {
  Iterable<T> whereFilter(PropertyFilter<T>? filter) => filter?.call(this) ?? this;
}

// TypeCarrier, TypeHost, TypeKey
mixin class TypeKey<T> {
  const TypeKey();

  Type get type => T;
  bool isSubtype<S>() => this is TypeKey<S>;
  bool isSupertype<S>() => TypeKey<S>() is TypeKey<T>;
  bool isExactType<S>() => S == T;
  bool get isNullable => isExactType<T?>();

  bool compareType(Object? object) => object is T;

  // call passing type
  R call<R>(R Function<G>() callback) => callback<T>();
  // callGeneric, callTyped
  R callWithType<R>(R Function<G>() callback) => callback<T>();
  // callWithTypeAsRestricted
  R callWithRestrictedType<R>(R Function<G extends T>() callback) => callback<T>();
  // T callAsKey(T Function<G>(TypeKey key) callback) => callback<T>(this);
}

// A primitive union type key
// boundary depending on type
abstract mixin class UnionTypeKey<V> implements TypeKey<V> {
  const UnionTypeKey();

  List<Enum>? get valueEnumRange; // EnumSubtype.values must be non-null for Enum types
  // Limits as the values the num can take, compare with >= and <=
  ({num min, num max})? get valueNumLimits; // must be null for non-num types
  V? get valueDefault;
}

// IdKey, EntityKey, DataKey, FieldKey, VarKey,
// ServiceKey for retrieving data of dynamic type from external source and casting
abstract mixin class ServiceKey<K, V> implements UnionTypeKey<V> {
  // VarKey
  K get key;
  String get label;
  // Stringifier? get valueStringifier;

  // a serviceKey can directly access the value with a provided reference to service
  // ServiceIO? get service;
  // V? get value => service?.get(keyValue);
  V? get value;
  set value(V? value);
  Future<bool> updateValue(V value);
  Future<V?> loadValue();
  String get valueString;

  // Type get type;
  TypeKey<V> get valueType => TypeKey<V>();
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
