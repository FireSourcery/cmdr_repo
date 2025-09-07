import 'dart:collection';
export 'dart:collection';

/// [FixedMap] - interface for Map constraints
/// FixedMap - fixed set of keys
///   optimized for small fixed set of keys
///   guarantees all keys are present
///   can guarantee non null return - if V is defined as non nullable
abstract mixin class FixedMap<K, V> implements Map<K, V> {
  const FixedMap();

  @override
  Iterable<K> get keys; // for implementation with const map literal
  // List<K> get keys;

  @override
  V operator [](covariant K key);
  @override
  void operator []=(covariant K key, V value);
  @override
  void clear();
  @override
  V remove(covariant K key);

//   // List<V>? get defaultValues;
//   // FixedMap<K, V> clone() => IndexMap<K, V>(this);
}

// abstract class FixedMap <K, V> implements FixedMap<K, V> {
//   const FixedMapImpl(this.keys);
//   final List<K> keys;
// }

// mixin FixedMapWith<K, V> on FixedMap<K, V> {
//   // analogous to operator []=, but returns a new instance
//   FixedMap<K, V> withField(K key, V value) => (IndexMap<K, V>.fromBase(this)..[key] = value);
//   //
//   FixedMap<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => IndexMap<K, V>.fromBase(this)..addEntries(newEntries);
//   // A general values map representing external input, may be a partial map
//   FixedMap<K, V> withAll(Map<K, V> map) => IndexMap<K, V>.fromBase(this)..addAll(map);
// }

/// [IndexMap]
/// Default implementation using parallel arrays
///
/// buffer a struct list of values
/// necessary before the subtype memory layout is known
/// double buffers, however, it can optimize for multiple replacements before copying to the subtype object
///
/// Mutable
/// K must have .index property
///
class IndexMap<K extends dynamic, V> with MapBase<K, V>, FixedMap<K, V> {
  // default by assignment, initialize const using list literal
  const IndexMap._(this._keysReference, this._valuesBuffer) : assert(_keysReference.length == _valuesBuffer.length);

  IndexMap._assert(this._keysReference, this._valuesBuffer)
      : assert(_keysReference.indexed.every((e) => e.$1 == e.$2.index), 'Keys must have index property'),
        assert(_valuesBuffer.length == _keysReference.length, 'Values buffer must match keys length');

  /// constructors pass original keys, do not derive from Map.keys
  // a new values buffer list is allocated for a new map

  IndexMap.of(List<K> keys, Iterable<V> values) : this._(keys, List<V>.of(values, growable: false));

  IndexMap.filled(List<K> keys, V fill) : this._(keys, List<V>.filled(keys.length, fill, growable: false));

  // possibly with nullable entries value V checking key for default value first
  IndexMap.fromEntries(List<K> keys, Iterable<MapEntry<K, V>> entries)
      : assert(keys.every((key) => entries.map((entry) => entry.key).contains(key))),
        _keysReference = keys,
        _valuesBuffer = List.from((IndexMap<K, V?>.filled(keys, null)..addEntries(entries))._valuesBuffer);

  // default copyFrom implementation
  // IndexMap.fromBase(IndexMap<K, V?> state) : this._(state.keys, List<V>.from(state.values, growable: false));
  IndexMap.fromBase(List<K> keys, FixedMap<K, V?> state) : this._(keys, List<V>.from(state.values, growable: false));

  IndexMap.fromMap(List<K> keys, Map<K, V?> state) : this._(keys, List<V>.from(state.values, growable: false));

  // IndexMap.castBase(IndexMap<K, V> state) : this._(state._keysReference, state._valuesBuffer);

  final List<K> _keysReference; // pointer to original
  final List<V> _valuesBuffer; // allocate new non growable List
  // final List<V>? _defaultValues;

  @override
  List<K> get keys => _keysReference;
  @override
  List<V> get values => _valuesBuffer;

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
}

/// IndexMap With -
/// default copyWith implementation via replacement/override List
///
/// In case IndexMap is unmodifiable
/// a builder surrogate for multiple replacements before copying to the subtype object.
///
/// create a new view with an additionally allocated iterable or IndexMap for replacements.
/// same as cast + modified
/// does not need to wrap general maps, general maps are must be converted first to guarantee all keys are present
///
class ProxyIndexMap<K extends dynamic, V> with MapBase<K, V>, FixedMap<K, V> {
  const ProxyIndexMap._(this._source, this._modified);
  ProxyIndexMap(IndexMap<K, V> source) : this._(source, IndexMap<K, V?>.filled(source.keys, null));

  // express synchronous creation before returning the new instance
  ProxyIndexMap.field(IndexMap<K, V> source, K key, V value) : this._(source, IndexMap<K, V?>.filled(source.keys, null)..[key] = value);
  ProxyIndexMap.entry(IndexMap<K, V> source, MapEntry<K, V> modified) : this._(source, IndexMap<K, V?>.filled(source.keys, null)..addEntries([modified]));
  ProxyIndexMap.entries(IndexMap<K, V> source, Iterable<MapEntry<K, V>> modified) : this._(source, IndexMap<K, V?>.filled(source.keys, null)..addEntries(modified));

  final IndexMap<K, V> _source;

  // a new IndexMap is optimized over a searchable List<MapEntry<K, V>>
  //   equal to preemptively allocating a fixed size _modified list
  //   if a non growable list is used, IndexMap allocates the same size buffer
  //   a growable list either allocates a larger buffer or invoke performance penalties
  final FixedMap<K, V?> _modified;

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
