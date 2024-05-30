import 'package:flutter/foundation.dart';

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
  // callIfNotNull
  R? calln<T, R>(T? arg) => switch (arg) { T value => this(value), null => null };
}

extension IsNotNullThen on Object? {
  R? isThen<T, R>(R Function(T value) fn) => switch (this as T?) { T value => fn(value), null => null };
  R? nullThen<R>(R Function() fn) => (this == null) ? fn() : null;
}

// extension type NumTo<R>(num value) implements num {
//   // NumTo.parse(String string) : value = num.parse(string);
//   NumTo.parse(String string) : value = switch (R) { const (int) => int.parse(string), const (double) => double.parse(string), _ => throw TypeError() };

//   // R to<R>() => switch (R) { const (int) => toInt(), const (double) => toDouble(), _ => throw TypeError() } as R;
// }
