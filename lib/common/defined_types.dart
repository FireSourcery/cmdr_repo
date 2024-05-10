import 'package:flutter/foundation.dart';
import 'package:recase/recase.dart';

typedef WhereTest<T> = bool Function(T input);

// filter with a name
abstract mixin class PropertyFilter<T> implements Enum {
  const PropertyFilter();

  WhereTest<T> get test;

  Iterable<T> call(Iterable<T> input) => input.where(test);

  String get label => name.pascalCase;
  IterableFilter<T> get asIterableFilter => call;
}
