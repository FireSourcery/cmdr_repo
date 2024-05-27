import 'dart:collection';

/// assigns key and name to Map-like classes, using Enum as keys
abstract mixin class EnumMap<E extends Enum, V> implements MapBase<E, V> {
  @override
  List<E> get keys;

  @override
  V operator [](covariant E key);

  // if this accepts null then, clear can call to reset
  @override
  void operator []=(covariant E key, V value);

  @override
  void clear();

  @override
  V? remove(covariant E key) => throw UnsupportedError('EnumMap does not support remove operation');

  Iterable<({String name, V value})> get namedValues => keys.map((e) => (name: e.name, value: this[e]));

  // MapEntries as Records
  Iterable<(E, V)> get pairs => keys.map((e) => (e, this[e]));

  // @protected
  // S asChildType<S extends EnumMap>() => this as S;

  S fillWithEntry<S extends EnumMap>(E key, V value) => (this..[key] = value) as S;

  /// [EnumMap] asserts all keys are present
  /// fills values, user may call from 'static' constructor
  S fromMap<S extends EnumMap>(EnumMap<E, V> map) => (this..addAll(map)) as S;

  /// create a new modifiable map
  Map<E, V> toMap() => Map.of(this);

  /// [Map] includes updated values
  S fillWithMap<S extends EnumMap>(Map<E, V> map) => (this..addAll(map)) as S;

  S fromMapByName<S extends EnumMap>(Map<String, V> map) => (this..addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)))) as S;

  Map<String, V> toMapByName() => {for (final key in keys) key.name: this[key]};
}

// abstract mixin class NamedFields<E extends NamedField<V>, V> implements EnumMap<E, V> {}

// abstract mixin class NamedField<V> implements Enum {
//   const NamedField();
//   Type get type => V;
//   bool compareType(Object? object) => object is V;
//   V get(EnumMap enumMap) => enumMap[this] as V;
//   void set(EnumMap enumMap, V value) => enumMap[this] = value;

//   // String get name; // Enum.name
// }
