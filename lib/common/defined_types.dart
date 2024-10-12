import 'package:flutter/foundation.dart';

// naming convention difference
// For classes and types -
//  Most descriptive noun first, then adjective descriptions
// this way Aligns characters
// allows the first word to be the module/group name
// unlike objects types are not called with dot notation, so placing the most descriptive noun last is less meaningful

typedef KeyValuePair<K, V> = (K key, V value);
typedef KeyValueEntry<K, V> = ({K key, V value});

typedef Stringifier<T> = String Function(T input);

/// PropertyFilter
typedef WhereTest<T> = bool Function(T input);

// filter with a name
abstract mixin class PropertyFilter<T> implements Enum {
  const PropertyFilter();

  WhereTest<T> get test;

  Iterable<T> call(Iterable<T> input) => input.where(test);

  IterableFilter<T> get asIterableFilter => call;
}

extension CallOnNullAsNull on Function {
  // callIfNotNull, callOrNull
  R? calln<T, R>(T? arg) => switch (arg) { T value => this(value), null => null };
}

extension IsNotNullThen on Object? {
  // analogous to synchronous Future.then
  R? isThen<T, R>(R Function(T value) fn) => switch (this as T?) { T value => fn(value), null => null };
  R? nullThen<R>(R Function() fn) => (this == null) ? fn() : null;
}

// extension type NumTo<R extends num>(num value) implements num {
//   // NumTo.parse(String string) : value = num.parse(string);
//   NumTo.parse(String string) : value = switch (R) { const (int) => int.parse(string), const (double) => double.parse(string), _ => throw TypeError() };
// }

// extension NumTo on num {
//   R to<R extends num>() => switch (R) { const (int) => toInt(), const (double) => toDouble(), _ => throw TypeError() } as R;
// }

extension MapPairs<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<(K, V)> asPairs() => map((e) => (e.key, e.value));
}

// only necessary for no heterogeneous keys
abstract mixin class TypedKey<V> {
  // defined by Enum
  // String get name;
  // int get index;

  // type checking is more simply implemented internally
  Type get type => V;
  bool compareType(Object? object) => object is V;
  R callTyped<R>(R Function<G>() callback) => callback<V>();
}
