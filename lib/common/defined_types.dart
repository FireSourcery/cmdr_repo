import 'package:flutter/foundation.dart';
import 'package:recase/recase.dart';

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
  // String get label => name.pascalCase;
}
