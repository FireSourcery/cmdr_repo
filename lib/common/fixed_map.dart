import 'dart:collection';

import 'package:cmdr/binary_data/bitfield.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// [FixedMap]/[EnumMap] - A simplified map implementation
///   using a direct mapping function, e.g. a provided switch expression on Keys
///   optimized for small fixed set of keys
///   additionally constrains input type guarantees all keys are present
///      and promises non null return
///   assigns String name via Enum.name
abstract mixin class FixedMap<K extends Enum, V> implements Map<K, V> {
  // const factory FixedMap();
  @override
  List<K> get keys;

  @override
  V operator [](covariant K key);
  // V? operator [](covariant E key);

  // if this V accepts null then, clear can call to reset
  @override
  void operator []=(covariant K key, V value);

  @override
  void clear();

  @override
  V? remove(covariant K key) => throw UnsupportedError('FixedMap does not support remove operation');

  Iterable<({String name, V value})> get nameValues => keys.map((e) => (name: e.name, value: this[e]));

  // MapEntries as Records
  Iterable<(K, V)> get pairs => keys.map((e) => (e, this[e]));

  //todo
  // need concrete constructor, or child caster constructor
  // FixedMap<K, V> castAs(FixedMap<K, V>);
  // FixedMap<K, V> copyWithEntry(K key, V value) =>  castAs(FixedMapModified<K, V>(this, [MapEntry(key, value)]));

  // FixedMap<K, V> copyWithEntry(K key, V value) => FixedMapModified<K, V>(this, [MapEntry(key, value)]);

  /// ready to wrap with a child constructor
  ///   initWith(covariant Map<E, V> map); // alternative use a factory class
  /// can be overridden to skip buffering
  /// withEntry(E key, V value);
  @protected
  FixedMap<K, V> modifyEntryAsMap(K key, V value) => FixedMapModified<K, V>(this, [MapEntry(key, value)]);

  // S modifyEntry<S extends FixedMap>(K key, V value) => FixedMapModified<K, V>(this, [MapEntry(key, value)]) as S;

  // /// when `this` is modifiable
  // /// [FixedMap] asserts all keys are present
  // /// fills values, user may call from 'static' constructor
  // S fillFromMap<S extends FixedMap>(FixedMap<E, V> map) => (this..addAll(map)) as S;
  // S fillWithEntry<S extends FixedMap>(E key, V value) => (this..[key] = value) as S;
  // S fillWithEntries<S extends FixedMap>(Iterable<MapEntry<E, V>> entries) => (this..addEntries(entries)) as S;

  // /// [Map] includes updated values
  // S fillWithMap<S extends FixedMap>(Map<E, V> map) => (this..addAll(map)) as S;

  /// create a new modifiable hash map
  Map<K, V> toMap() => Map.of(this);

  S fromMapByName<S extends FixedMap>(Map<String, V> map) => (this..addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)))) as S;

  // factory FixedMap.fromMapByName(Map<String, V> map) =>
  // FixedMapBuffer(map.keys.map( (key) => keys.byName).toList()) ;
  //  (this..addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)))) as S;

  Map<String, V> toMapByName() => {for (final key in keys) key.name: this[key]};
}

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
    // return _modified.firstWhere((element) => element.key == key, orElse: () => MapEntry(key, _source[key]!)).value;
    return _modified.firstWhereOrNull((element) => element.key == key)?.value ?? _source[key];
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

/// mutable implementation
class FixedMapBuffer<E extends Enum, V> with MapBase<E, V?>, FixedMap<E, V?> {
  FixedMapBuffer(this._keys, [List<V>? values]) : _values = values ?? List<V?>.filled(_keys.length, null);
  FixedMapBuffer.initWith(FixedMap<E, V> source)
      : _keys = source.keys,
        _values = source.keys.map((e) => source[e]).toList(); // values in parallel order

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

  @override
  FixedMap<E, V> modifyEntryAsMap(E key, V? value) => (this..[key] = value) as FixedMap<E, V>;

  // @override
  // FixedMap<E, V?> initWith(Map<E, V?> map) => fillWithMap(map);
}
