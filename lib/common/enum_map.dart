import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart';

/// [EnumMap] - A simplified map implementation
///   optimized for small fixed set of keys
///   using Enum for keys provides -
///     index via Enum.index - creates a parallel array map by default
///     String name via Enum.name
///   guarantees all keys are present via constrain on input type
///   can guarantee non null return if V is defined as non nullable
///   optionally using a direct mapping function, e.g. a provided switch expression on Keys
///
/// `abstract mixin class` combines interface and implemented methods
abstract mixin class EnumMap<K extends Enum, V> implements Map<K, V> {
  const EnumMap();

  @override
  List<K> get keys; // Enum.values
  @override
  V operator [](covariant K key);
  @override
  void operator []=(covariant K key, V value); // should this accept V? as a way of setting a default?
  @override
  void clear(); // deferring clear simplifies implementation of immutable case

  // V? get nil; child class may implement when a non null default is available. e.g. 0, false or ''
  // void clear() => updateAll((key, value) => fill);
  // if this V accepts null then, clear can call to reset, or icnlud fill
  // bool isType<Vx>() => V == Vx;
  // bool get isNullable => isType<V?>();
  // @override
  // void clear() {
  //   if (isType<V?>()) {
  //     for (var i = 0; i < keys.length; i++) {
  //       this[keys[i]] = null;
  //     }
  //   } else {
  //     throw UnsupportedError('EnumMap does not support clear operation');
  //   }
  // }

  @override
  V? remove(covariant K key) => throw UnsupportedError('EnumMap does not support remove operation');

  @override
  String toString() => '$runtimeType: $values';

  ////////////////////////////////////////////////////////////////////////////////
  /// Convenience methods
  ////////////////////////////////////////////////////////////////////////////////
  // String name, value pairs
  Iterable<(String name, V value)> get labeled => entries.map((e) => (e.key.name, e.value));
  Iterable<({String name, V value})> get nameValues => keys.map((e) => (name: e.name, value: this[e]));
  Iterable<({String name, K key, V value})> get triplets => keys.map((e) => (name: e.name, key: e, value: this[e]));

  // MapEntries as Records
  Iterable<(K, V)> get pairs => keys.map((e) => (e, this[e]));

  ////////////////////////////////////////////////////////////////////////////////
  /// Immutable Case
  ////////////////////////////////////////////////////////////////////////////////
  // override in child class, parameterized by child class field names
  // copyWith will refer to the child class constructor
  @mustBeOverridden
  EnumMap<K, V> copyWith() => this;
  // EnumMap<K, V> copyWith() => EnumMapProxy<K, V>(this);

  // // EnumMap representing internal state
  // EnumMap<K, V> copyWithBase(covariant EnumMap<K, V> source) => EnumMapProxy<K, V>.cast(source);

  /// default implementation copy to new buffer use shared child constructor
  /// an child class with optimized copyWith can override to skip buffering
  // analogous to operator []=, but returns a new instance
  EnumMap<K, V> withField(K key, V value) => (EnumMapProxy<K, V>(this)..[key] = value).copyWith();
  EnumMap<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => (EnumMapProxy<K, V>(this)..addEntries(newEntries)).copyWith();
  // A general values map representing external input, may be a partial map
  EnumMap<K, V> withAll(Map<K, V> map) => (EnumMapProxy<K, V>(this)..addAll(map)).copyWith();

  ////////////////////////////////////////////////////////////////////////////////
  /// Mutable Case -
  ///   only if child class is implemented as mutable
  ///   i.e. []= is defined
  ////////////////////////////////////////////////////////////////////////////////

  // fill values from json
  void addJson(Map<String, Object?> json) {
    if (json is Map<String, V>) {
      if (keys is List<TypedEnumKey>) {
        // typed keys case
        // for (final key in keys) {
        //   if (key.compareType(json[key.name])) this[key] = json[key.name];
        // }
        for (final TypedEnumKey key in keys as List<TypedEnumKey>) {
          if (!key.compareType(json[key.name])) throw FormatException('$runtimeType: ${key.name} is not of type ${key.type}');
        }
      }
      // homogeneous V case
      addAllByName(json);
    } else {
      throw FormatException('$runtimeType: $json is not of type Map<String, V>');
    }
  }

  // from jsonMap
  void addAllByName(Map<String, V> map) => addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)));

  Map<String, V> toMapByName() => {for (final key in keys) key.name: this[key]};

  Map<String, Object?> toJson() => toMapByName();
}

// combine mixins
abstract class EnumMapBase<K extends Enum, V> = MapBase<K, V> with EnumMap<K, V> implements EnumMap<K, V>;

/// auto typing return as child class.
mixin EnumMapAsSubtype<S extends EnumMap<K, V>, K extends Enum, V> on EnumMap<K, V> {
  @override
  S withField(K key, V value) => super.withField(key, value) as S;
  @override
  S withEntries(Iterable<MapEntry<K, V>> entries) => super.withEntries(entries) as S;
  @override
  S withAll(Map<K, V> map) => super.withAll(map) as S;
}

typedef EnumKey = Enum;

// only necessary for non heterogeneous V typed keys
abstract mixin class TypedEnumKey<V> implements Enum {
  R callTyped<R>(R Function<G>() callback) => callback<V>();
  // type checking is more simply implemented internally
  Type get type => V;
  bool compareType(Object? object) => object is V;

  // or should get/set implementation be here? and redirect operators?
  // probably better to do so in the map class with context of mutable or immutable
  // V call(covariant EnumMap<TypedEnumKey<V>, V> map) => map[this] as V;
}

/// Keys list effectively define EnumMap type and act as factory
/// inheritable constructors
/// this way all factory constructors are related by a single point of interface.
///   otherwise each factory in the child must wrap the parent factory.
///   e.g. Child factory fromJson(Map<String, Object?> json) => Child.fromBase(Super.fromJson(json));
/// additionally
/// no passing keys as parameter
/// partial/nullable return
extension type const EnumMapFactory<S extends EnumMap<K, V>, K extends EnumKey, V>(List<K> keys) {
  // only this needs to be redefined in child class
  S fromBase(EnumMap<K, V> state) => state as S;

  // alternatively use copyWith.
  // or allow user end to maintain 2 separate routines?
  // also separates cast as subtype from EnumMap class

  // EnumMap<K, V?> create({EnumMap<K, V>? state, V? fill}) {
  //   if (state == null) {
  //     return EnumMapDefault<K, V?>.filled(keys, null);
  //   } else {
  //     return fromBase(state);
  //   }
  // }

  // EnumMap<K, V?> filled(V? fill) => EnumMapDefault<K, V?>.filled(keys, null);
  // EnumMap<K, V?> fromValues([List<V>? values, V? fill]) => EnumMapDefault<K, V?>._fromValues(keys, values);

  EnumMap<K, V> _fromEntries(Iterable<MapEntry<K, V>> entries) {
    assert(keys.every((key) => entries.map((entry) => entry.value).contains(key)));
    // fill then add to ensure all values are mapped by index
    return (EnumMapDefault<K, V?>.filled(keys, null)..addEntries(entries)) as EnumMapDefault<K, V>;
  }

  // assert all keys are present
  S fromEntries(Iterable<MapEntry<K, V>> entries) => fromBase(_fromEntries(entries));
  S fromMap(Map<K, V> map) => fromBase(_fromEntries(map.entries));

  // parseJson()
  // by default allocate new list buffer
  EnumMap<K, V> _fromJson(Map<String, Object?> json) {
    if (json is Map<String, V>) {
      if (keys is List<TypedEnumKey>) {
        for (final key in keys as List<TypedEnumKey>) {
          if (!key.compareType(json[key.name])) throw FormatException('DataMap.fromJson: ${key.name} is not of type ${key.type}');
        }
      }
      // return EnumMapDefault.filled(keys, null)..addJson(json);
      return _fromEntries(json.entries.map((e) => MapEntry(keys.byName(e.key), e.value)));
    } else {
      throw FormatException('DataMap.fromJson: $json is not of type Map<String, V>');
    }
  }

  S fromJson(Map<String, Object?> json) => fromBase(_fromJson(json));
}

/// Default implementations concerning optimizing data structure without child class details

/// Default implementation using parallel arrays
///   mutable
// ignore: missing_override_of_must_be_overridden
class EnumMapDefault<K extends Enum, V> extends EnumMapBase<K, V> implements EnumMap<K, V> {
  // default by assignment, initialize const using list literal
  // a new list should always be allocated
  const EnumMapDefault._(this._keys, this._values) : assert(_keys.length == _values.length);
  EnumMapDefault._fromValues(List<K> keys, Iterable<V> values) : this._(keys, List<V>.of(values, growable: false));

  /// constructors always pass original keys, concrete class cannot use getter, do not derive from Map.keys
  EnumMapDefault.filled(List<K> keys, V fill) : this._(keys, List<V>.filled(keys.length, fill, growable: false));

  // alternatively keep in factory
  EnumMapDefault.fromEntries(List<K> keys, Iterable<MapEntry<K, V>> entries)
      : assert(keys.every((key) => entries.map((entry) => entry.value).contains(key))),
        _keys = keys,
        _values = ((EnumMapDefault<K, V?>.filled(keys, null)..addEntries(entries)) as EnumMapDefault<K, V>)._values,
        // _values = [for (final key in keys) entries.firstWhere((element) => element.key == key).value], // increased time complexity although includes assertion
        super();

  // default copyFrom implementation
  // withState -> with on constructors is better reserved for defining attribute of the 'class' as oppose to the object instance, in the case of abstract class
  // copyWithState -> longer, although refers to compatibility with copyWith
  // copyFrom -> 2 verbs, less meaning projected
  // fromState -> fromBase more precise
  EnumMapDefault.fromBase(EnumMap<K, V> state) : this._(state.keys, List<V>.of(state.values, growable: false));

  final List<K> _keys;
  final List<V> _values;
  // final V? _fill;

  @override
  List<K> get keys => _keys;
  @override
  V operator [](K key) => _values[key.index]!;
  @override
  void operator []=(K key, V value) => _values[key.index] = value;

  /// let fill throw if V is defined as non nullable and [fill] is null
  @override
  void clear() {
    // if (_fill == null) {
    //   throw UnsupportedError('EnumMap does not support clear operation');
    // } else {
    // _values.fillRange(0, _values.length, _fill);
    // }
  }

  // @override
  // EnumMap<K, V> copyWith() => this;
}

/// EnumMapWith -
/// default copyWith implementation via replacement/override List
/// a builder surrogate optimize for case replacing a single, or few entries
///
/// create a new view with an additionally allocated iterable or EnumMap for replacements.
/// necessary before the subtype memory layout is known
///
/// double buffers, however, it can optimize for multiple replacements before copying to the subtype object
///
/// same as cast + modified
///
/// does not need to wrap general maps, general maps are must be converted first to guarantee all keys are present
///
// ignore: missing_override_of_must_be_overridden
class EnumMapProxy<K extends Enum, V> extends EnumMapBase<K, V> implements EnumMap<K, V> {
  const EnumMapProxy._(this._source, this._modified);
  EnumMapProxy(EnumMap<K, V> source) : this._(source, EnumMapDefault<K, V?>.filled(source.keys, null));

  // EnumMapProxy.field(EnumMap<K, V> source, K key, V value) : this(source, [MapEntry(key, value)]);
  // EnumMapProxy.entry(EnumMap<K, V> source, MapEntry<K, V> modified) : this(source, [modified]);
  // EnumMapProxy.entries(EnumMap<K, V> source, Iterable<MapEntry<K, V>> modified) : this(source, [...modified]);

  final EnumMap<K, V> _source;

  // a new EnumMap is optimized over a searchable List<MapEntry<K, V>>
  //   equal preemptively to allocating a fixed size _modified list
  //   if a non growable list is used, EnumMap allocates the same size buffer
  //   a growable list either allocates a larger buffer or invoke performance penalties
  final EnumMapDefault<K, V?> _modified;

  @override
  List<K> get keys => _source.keys;

  @override
  V operator [](K key) => _modified[key] ?? _source[key];

  // optimize for multiple replacements, may not notify listeners until copyWith is called
  @override
  void operator []=(K key, V value) => _modified[key] = value;

  @override
  void clear() => throw UnsupportedError('EnumMap does not support clear operation');
}

// cast of general map - must have all keys
//
// compile time const definition using map literal
// EnumMap<EnumType> example = EnumMapCastMap(
//   EnumType.values,
//   {
//     EnumType.name1: 2,
//     EnumType.name2: 3,
//   },
// );
abstract class ConstEnumMapInit<K extends Enum, V> extends EnumMapBase<K, V> implements EnumMap<K, V> {
  const ConstEnumMapInit(this.source);
  const factory ConstEnumMapInit.withKeys(List<K> keys, Map<K, V> source) = ConstEnumMapInitWithKeys<K, V>;

  @protected
  final Map<K, V> source;

  @override
  V operator [](covariant K key) => source[key]!;

  @override
  void operator []=(K key, V value) => throw UnsupportedError("Cannot modify unmodifiable");

  @override
  void clear() => throw UnsupportedError("Cannot modify unmodifiable");
}

// ignore: missing_override_of_must_be_overridden
class ConstEnumMapInitWithKeys<K extends Enum, V> extends ConstEnumMapInit<K, V> implements EnumMap<K, V> {
  const ConstEnumMapInitWithKeys(this.keys, super.source);
  @override
  final List<K> keys;
}
