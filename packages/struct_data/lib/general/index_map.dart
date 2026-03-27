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
  List<K> get keys;

  @override
  V operator [](covariant K key);
  @override
  void operator []=(covariant K key, V value);

  /// do not remove keys, only reset values to default or null
  @override
  void clear();
  @override
  V remove(covariant K key);
}

/// [IndexMap]
/// Default implementation using parallel arrays
///
/// buffer a struct list of values
///
/// K must have .index property
class IndexMap<K extends dynamic, V> with MapBase<K, V>, FixedMap<K, V> {
  // default by assignment, initialize const using list literal
  const IndexMap._(this._keysReference, this._valuesBuffer) : assert(_keysReference.length == _valuesBuffer.length);

  // ignore: unused_element
  IndexMap._assert(this._keysReference, this._valuesBuffer)
    : assert(_keysReference.indexed.every((e) => e.$1 == e.$2.index), 'Keys must have index property'),
      assert(_valuesBuffer.length == _keysReference.length, 'Values buffer must match keys length');

  /// constructors pass original keys, do not derive from Map.keys
  // a new values buffer list is allocated for a new map

  // values enfoce List to indcate matched length
  IndexMap.of(List<K> keys, Iterable<V> values) : this._(keys, List<V>.of(values, growable: false));

  IndexMap.filled(List<K> keys, V fill) : this._(keys, List<V>.filled(keys.length, fill, growable: false));

  IndexMap.fromEntries(List<K> keys, Iterable<MapEntry<K, V>> entries)
    : assert(keys.every((key) => entries.map((entry) => entry.key).contains(key))),
      _keysReference = keys,
      _valuesBuffer = List.from((IndexMap<K, V?>.filled(keys, null)..addEntries(entries))._valuesBuffer);

  IndexMap.fromBase(IndexMap<K, V> state) : this._(state.keys, List<V>.from(state.values, growable: false));

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
    // else if (defaultValue != null) // throws via noSuchMethod
    // {}
    throw UnsupportedError('IndexMap default remove operation not defined');
  }
}
