import 'dart:collection';

import 'package:meta/meta.dart';

/// [FixedMap] - A simplified map implementation
///   using a direct mapping function, e.g. a provided switch expression on Keys
///   optimized for small fixed set of keys
///   additionally constrains input type and promises non null return
///   assigns String name via Enum.name
abstract mixin class FixedMap<E extends Enum, V> implements Map<E, V> {
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
  V? remove(covariant E key) => throw UnsupportedError('FixedMap does not support remove operation');

  Iterable<({String name, V value})> get namedValues => keys.map((e) => (name: e.name, value: this[e]));

  // MapEntries as Records
  Iterable<(E, V)> get pairs => keys.map((e) => (e, this[e]));

  /// ready to wrap with a child constructor
  ///   initWith(covariant Map<E, V> map); // alternative use a factory class
  /// can be overridden to skip buffering
  @protected
  FixedMap<E, V> modifyEntryAsMap(E key, V value) => FixedMapModified<E, V>(this, [MapEntry(key, value)]);

  // /// when `this` is modifiable
  // /// [FixedMap] asserts all keys are present
  // /// fills values, user may call from 'static' constructor
  // S fillFromMap<S extends FixedMap>(FixedMap<E, V> map) => (this..addAll(map)) as S;
  // S fillWithEntry<S extends FixedMap>(E key, V value) => (this..[key] = value) as S;
  // S fillWithEntries<S extends FixedMap>(Iterable<MapEntry<E, V>> entries) => (this..addEntries(entries)) as S;

  // /// [Map] includes updated values
  // S fillWithMap<S extends FixedMap>(Map<E, V> map) => (this..addAll(map)) as S;

  /// create a new modifiable hash map
  Map<E, V> toMap() => Map.of(this);

  S fromMapByName<S extends FixedMap>(Map<String, V> map) => (this..addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)))) as S;

  // factory FixedMap.fromMapByName(Map<String, V> map) =>
  // FixedMapBuffer(map.keys.map( (key) => keys.byName).toList()) ;
  //  (this..addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)))) as S;

  Map<String, V> toMapByName() => {for (final key in keys) key.name: this[key]};
}

/// for heterogeneous data types
// abstract mixin class NamedFields<E extends NamedField<V>, V> implements FixedMap<E, V> {
//   // factory NamedFields.buffer() = NamedFieldsBuilder;

//   // List<E> get keys;
//   // List<E> get fields;
//   // the getter for each field
//   // V operator [](covariant E key);
//   // void operator []=(covariant E key, V value);

//   // NamedFields<E, V> cloneWith(covariant Map<E, V?>? map);
//   // NamedFields<E, V> modify(E key, V value) => copyWithEntry(key, value);

//   // the child class constructor
//   // cloneWith
//   // implicitly requires V to be nullable or defined with default value
//   NamedFields<E, V> initWith(covariant Map<E, V> map); // alternative use a factory class

//   NamedFields<E, V> copyWithEntry(E key, V value) => initWith(NamedFieldsModified<E, V>(this, [MapEntry(key, value)]));
//   // NamedFields<E, V> copyWithEntry(E key, V value) => initWith(NamedFieldsBuffer<E, V>(keys).fillWithEntry(key, value));
//   // NamedFields<E, V> copyWithEntries(Iterable<MapEntry<E, V>> entries) => initWith(NamedFieldsBuffer<E, V>(keys).fillWithEntries(entries));
// }

// abstract mixin class NamedField<V> implements Enum {
//   const NamedField();
//   // type checking is more simply implemented internally
//   Type get type => V;
//   bool compareType(Object? object) => object is V;
//   R callTyped<R>(R Function<G>() fn) => fn<V>();
//   // String get name; // Enum.name

//   // or should get/set implementation be here? and redirect operators?
//   // probably better to do so in the child class with context of mutable or immutable
//   // V get(covariant NamedFields fieldsMap);
// }

// a builder surrogate for simplifying child class constructors
// in the case switch mapping is not is provided
class FixedMapModified<E extends Enum, V> with MapBase<E, V>, FixedMap<E, V> {
  const FixedMapModified(this._source, this._modified);
  final FixedMap<E, V> _source;
  final Iterable<MapEntry<E, V>> _modified;

  @override
  List<E> get keys => _source.keys;
  @override
  V operator [](E key) {
    return _modified.firstWhere((element) => element.key == key, orElse: () => MapEntry(key, _source[key]!)).value;
  }

  @override
  void operator []=(E key, V? value) {
    // _modified.firstWhere((element) => element.key == key, orElse: () => _modified.add(MapEntry<E, V>(key)));
    throw UnsupportedError('FixedMapModified does not support assignment');
  }

  @override
  void clear() => throw UnsupportedError('FixedMapModified does not support clear');

  // @override
  // FixedMap<E, V> initWith(Map<E, V?> map) => throw UnsupportedError('FixedMapModified does not support initWith');
}

class FixedMapBuffer<E extends Enum, V> with MapBase<E, V?>, FixedMap<E, V?> {
  FixedMapBuffer(this._keys, [List<V>? values]) : _values = values ?? List<V?>.filled(_keys.length, null);

  final List<E> _keys;
  final List<V?> _values;
  @override
  List<E> get keys => _keys;
  @override
  V? operator [](E key) => _values[key.index];
  @override
  void operator []=(E key, V? value) => _values[key.index] = value;
  @override
  void clear() => _values.fillRange(0, _values.length, null);

  // @override
  // FixedMap<E, V?> initWith(Map<E, V?> map) => fillWithMap(map);
}
