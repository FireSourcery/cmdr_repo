import 'dart:collection';

/// [TypedMap] - interface for Map constraints
abstract mixin class TypedMap<K, V> implements Map<K, V> {
  const TypedMap();

  @override
  List<K> get keys;
  @override
  V operator [](covariant K key);
  @override
  void operator []=(covariant K key, V value);
  @override
  void clear();
  @override
  V remove(covariant K key);
}

/// [IndexMap]
/// Default implementation using parallel arrays
/// Mutable
/// K must have .index property
class IndexMap<K extends dynamic, V> with MapBase<K, V> implements TypedMap<K, V> {
  // default by assignment, initialize const using list literal
  const IndexMap._(this._keysReference, this._valuesBuffer) : assert(_keysReference.length == _valuesBuffer.length);

  /// constructors always pass original keys, concrete class cannot use getter, do not derive from Map.keys
  // a new list should always be allocated for a new map

  IndexMap.of(List<K> keys, Iterable<V> values) : this._(keys, List<V>.of(values, growable: false));

  IndexMap.filled(List<K> keys, V fill) : this._(keys, List<V>.filled(keys.length, fill, growable: false));

  // possibly with nullable entries value V checking key for default value first
  IndexMap.fromEntries(List<K> keys, Iterable<MapEntry<K, V>> entries)
      : assert(keys.every((key) => entries.map((entry) => entry.key).contains(key))),
        _keysReference = keys,
        _valuesBuffer = List.from((IndexMap<K, V?>.filled(keys, null)..addEntries(entries))._valuesBuffer);

  // default copyFrom implementation
  IndexMap.castBase(IndexMap<K, V?> state) : this._(state.keys, List<V>.from(state.values, growable: false));

  final List<K> _keysReference;
  final List<V> _valuesBuffer; // non growable List
  // final List<V>? _defaultValues;

  @override
  List<K> get keys => _keysReference;
  @override
  V operator [](covariant K key) => _valuesBuffer[key.index]!;
  @override
  void operator []=(covariant K key, V value) => _valuesBuffer[key.index] = value;

  @override
  void clear() {
    if (null is V) {
      updateAll((key, value) => null as V);
    } else {
      keys.forEach(remove);
    }
    // if Key contains default value
    // else if (this case IndexMap<Field, V> map when map.keys.every((key) => key.defaultValue != null)) {
    //   map.updateAll((key, value) => key.defaultValue as V);
    // }
    // throw UnsupportedError('IndexMap default clear operation not defined');
  }

  @override
  V remove(covariant K key) {
    if (null is V) {
      final value = _valuesBuffer[key.index];
      _valuesBuffer[key.index] = null as V;
      return value;
    }
    // else if (key.defaultValue != null) // throws via noSuchMethod
    // {}
    throw UnsupportedError('IndexMap default remove operation not defined');
  }

  // IndexMap<K, V> toMap() => IndexMap<K, V>.castBase(this);
}

/// IndexMapWith -
/// default copyWith implementation via replacement/override List
/// a builder surrogate optimize for case replacing a single, or few entries
///
/// create a new view with an additionally allocated iterable or IndexMap for replacements.
/// necessary before the subtype memory layout is known
///
/// double buffers, however, it can optimize for multiple replacements before copying to the subtype object
///
/// same as cast + modified
///
/// does not need to wrap general maps, general maps are must be converted first to guarantee all keys are present
///
class ProxyIndexMap<K extends dynamic, V> with MapBase<K, V> implements TypedMap<K, V> {
  const ProxyIndexMap._(this._source, this._modified);
  ProxyIndexMap(TypedMap<K, V> source) : this._(source, IndexMap<K, V?>.filled(source.keys, null));

  // ProxyIndexMap.field(IndexMap<K, V> source, K key, V value) : this(source, [MapEntry(key, value)]);
  // ProxyIndexMap.entry(IndexMap<K, V> source, MapEntry<K, V> modified) : this(source, [modified]);
  // ProxyIndexMap.entries(IndexMap<K, V> source, Iterable<MapEntry<K, V>> modified) : this(source, [...modified]);

  final TypedMap<K, V> _source;

  // a new IndexMap is optimized over a searchable List<MapEntry<K, V>>
  //   equal to preemptively allocating a fixed size _modified list
  //   if a non growable list is used, IndexMap allocates the same size buffer
  //   a growable list either allocates a larger buffer or invoke performance penalties
  final TypedMap<K, V?> _modified;

  @override
  List<K> get keys => _source.keys;

  @override
  V operator [](covariant K key) => _modified[key] ?? _source[key];

  // optimize for multiple replacements, may not notify listeners until copyWith is called
  @override
  void operator []=(covariant K key, V value) => _modified[key] = value;

  @override
  void clear() => throw UnsupportedError("Cannot modify unmodifiable");

  @override
  V remove(covariant K key) => throw UnsupportedError("Cannot modify unmodifiable");
}
