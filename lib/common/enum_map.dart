import 'dart:collection';

/// assigns key and label to Map-like classes
abstract mixin class EnumMap<T extends Enum, V> implements MapBase<T, V> {
  @override
  List<T> get keys;

  @override
  V operator [](covariant T key);

  @override
  void operator []=(T key, V value);

  @override
  void clear();

  @override
  V? remove(covariant T key) => throw UnsupportedError('EnumMap does not support remove operation');

  Iterable<(String, V)> get namedValues => keys.map((e) => (e.name, this[e]));

  // MapEntries as Records
  Iterable<(T, V)> get pairs => keys.map((e) => (e, this[e]));
}
