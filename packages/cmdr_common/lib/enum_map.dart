import 'dart:collection';
import 'package:meta/meta.dart';

import 'basic_types.dart';

export 'dart:collection';
export 'package:meta/meta.dart';

/// [EnumMap] - A simplified map implementation
///   A [Map] with the additional constraint that Keys are a `fixed set`, via Enum.
///   optimized for small fixed set of keys
///     guarantees all keys are present
///     can guarantee non null return - if V is defined as non nullable
///   Keys inherit from Enum -
///     index via Enum.index -> create a parallel array map by default
///     String name via Enum.name -> directly use for serialization
///
/// `abstract mixin class` combines interface and implemented methods
abstract mixin class EnumMap<K extends Enum, V> implements Map<K, V> {
  const EnumMap();

  // factory EnumMap.ofValues(List<K> keys, List<V> values) = EnumMapDefault<K, V>._fromValues;

  @override
  List<K> get keys; // Enum.values
  @override
  V operator [](covariant K key);
  @override
  void operator []=(covariant K key, V value);
  @override
  void clear();

  // @override
  // void clear() {
  //   if (TypeKey<V>().isNullable) {
  //     updateAll((key, value) => null as V);
  //   }
  //   // if Key contains default value
  //   // else if (TypeKey<K>().isSubtype<TypeKey>()) {
  //   //   updateAll((key, value) => (key as TypeKey).defaultValue as V);
  //   // }
  //   // alternatively V? get nil => null; // child class may implement when a non null default is available. e.g. 0, false or ''
  //   // or []= accepts V? as a way of setting a default?
  //   throw UnsupportedError('EnumMap does not support clear operation');
  // }

  @override
  V? remove(covariant K key) => throw UnsupportedError('EnumMap does not support remove operation');

  // @override
  // String toString() => MapBase.mapToString(this);

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
  // Overridden the in child class to call the child class constructor, returning a instance of the child class type
  // copyWith will refer to the child class constructor
  //   copyWith empty parameters always returns itself
  @mustBeOverridden
  EnumMap<K, V> copyWith() => this;
  // EnumMap<K, V> copyWith() => EnumMapProxy<K, V>(this);

  /// default implementation copy to a new buffer, then pass to child constructor
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
      // handle mixed types case, V is Object
      if (keys is List<TypedEnumKey>) {
        for (final TypedEnumKey key in keys as List<TypedEnumKey>) {
          if (!key.compareType(json[key.name])) throw FormatException('$runtimeType: ${key.name} is not of type ${key.type}');
        }
      }
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
abstract class EnumMapBase<K extends Enum, V> = MapBase<K, V> with EnumMap<K, V>;

// define an interface for constructors?
// abstract class EnumMapBase<K extends Enum, V> extends MapBase<K, V> with EnumMap<K, V> {
//   EnumMapBase.castFrom(EnumMap<K, V> state);
// }

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

// only necessary for mixed V type keys
abstract mixin class TypedEnumKey<V> implements Enum, TypeKey<V> {
  //  V? get defaultValue => null; allows additional handling of Map<K, V?>

  // although implementation of operators may be preferable in the containing class
  // with full context of relationships;  mutable or immutable.
  // this may simplify some cases
  V valueOf(covariant EnumMap map);
}

/// Class/Type/Factory
/// Keys list effectively define EnumMap type and act as factory
/// inheritable constructors
/// this way all factory constructors are related by a single point of interface.
///   otherwise each factory in the child must wrap the parent factory.
///   e.g. Child factory fromJson(Map<String, Object?> json) => Child.castBase(Super.fromJson(json));
/// additionally
/// no passing keys as parameter
/// partial/nullable return
extension type const EnumMapFactory<S extends EnumMap<K, V>, K extends EnumKey, V>(List<K> keys) {
  // only this needs to be redefined in child class
  // or castFrom
  S castBase(EnumMap<K, V> state) => state as S;

  // alternatively use copyWith.
  // or allow user end to maintain 2 separate routines?
  // also separates cast as subtype from EnumMap class

  // EnumMap<K, V?> create({EnumMap<K, V>? state, V? fill}) {
  //   if (state == null) {
  //     return EnumMapDefault<K, V?>.filled(keys, null);
  //   } else {
  //     return castBase(state);
  //   }
  // }

  // EnumMap<K, V?> filled(V? fill) => EnumMapDefault<K, V?>.filled(keys, null);
  // EnumMap<K, V?> fromValues([List<V>? values, V? fill]) => EnumMapDefault<K, V?>._fromValues(keys, values);

  EnumMap<K, V> _fromEntries(Iterable<MapEntry<K, V>> entries) => EnumMapDefault<K, V>.fromEntries(keys, entries);

  // assert all keys are present
  S fromEntries(Iterable<MapEntry<K, V>> entries) => castBase(_fromEntries(entries));
  S fromMap(Map<K, V> map) => castBase(_fromEntries(map.entries));

  // parseJson()
  // by default allocate new list buffer
  EnumMap<K, V> _fromJson(Map<String, Object?> json) {
    if (json is Map<String, V>) {
      // field of mixed types case, check type
      if (keys is List<TypedEnumKey>) {
        for (final key in keys as List<TypedEnumKey>) {
          if (!key.compareType(json[key.name])) throw FormatException('EnumMap.fromJson: ${key.name} is not of type ${key.type}');
        }
      }
      return _fromEntries(json.entries.map((e) => MapEntry(keys.byName(e.key), e.value)));
    } else {
      throw FormatException('EnumMap.fromJson: $json is not of type Map<String, V>');
    }
  }

  S fromJson(Map<String, Object?> json) => castBase(_fromJson(json));
}

/// Default implementations concerning optimizing data structure without child class details

/// Default implementation using parallel arrays
///   mutable
// ignore: missing_override_of_must_be_overridden
class EnumMapDefault<K extends Enum, V> extends EnumMapBase<K, V> implements EnumMap<K, V> {
  // default by assignment, initialize const using list literal
  // a new list should always be allocated
  const EnumMapDefault._(this._keysReference, this._valuesBuffer) : assert(_keysReference.length == _valuesBuffer.length);
  EnumMapDefault._fromValues(List<K> keys, Iterable<V> values) : this._(keys, List<V>.of(values, growable: false));

  /// constructors always pass original keys, concrete class cannot use getter, do not derive from Map.keys
  EnumMapDefault.filled(List<K> keys, V fill) : this._(keys, List<V>.filled(keys.length, fill, growable: false));

  // possibly with nullable entries value V checking key for default value first
  EnumMapDefault.fromEntries(List<K> keys, Iterable<MapEntry<K, V>> entries)
      : assert(keys.every((key) => entries.map((entry) => entry.key).contains(key))),
        _keysReference = keys,
        _valuesBuffer = (EnumMapDefault<K, V?>.filled(keys, null)..addEntries(entries))._valuesBuffer as List<V>,
        // _values = [for (final key in keys) entries.singleWhere((element) => element.key == key).value], // increased time complexity although includes assertion
        super();

  // placeholder for holding values, when type is known, cast with keys later
  EnumMapDefault.keyless(Iterable<V> values) : this._(const [], List<V>.of(values, growable: false));

  // default copyFrom implementation
  // withState -> with on constructors is better reserved for defining attribute of the 'class' as oppose to the object instance, in the case of abstract class
  // copyWithState -> longer, although refers to compatibility with copyWith
  // copyFrom -> 2 verbs, less meaning projected
  // fromState -> castBase more precise
  EnumMapDefault.castBase(EnumMap<K, V> state) : this._(state.keys, List<V>.of(state.values, growable: false));

  final List<K> _keysReference;
  final List<V> _valuesBuffer;

  @override
  List<K> get keys => _keysReference;
  @override
  V operator [](K key) => _valuesBuffer[key.index]!;
  @override
  void operator []=(K key, V value) => _valuesBuffer[key.index] = value;

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
  //   equal to preemptively allocating a fixed size _modified list
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
  void clear() => throw UnsupportedError("Cannot modify unmodifiable");
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
// ignore: missing_override_of_must_be_overridden
// may need to be mixin
class ConstEnumMapInit<K extends Enum, V> extends EnumMapBase<K, V> implements EnumMap<K, V> {
  const ConstEnumMapInit(this.source);

  @protected
  final Map<K, V> source;

  @override
  V operator [](covariant K key) => source[key]!;

  @override
  void operator []=(K key, V value) => throw UnsupportedError("Cannot modify unmodifiable");

  @override
  void clear() => throw UnsupportedError("Cannot modify unmodifiable");

  // @override
  // EnumMap<K, V> copyWith() => this;

  @override
  List<K> get keys {
    if (source is EnumMap<K, V>) return (source as EnumMap<K, V>).keys; // only step to generalize for EnumMap as source
    return UnmodifiableListView(source.keys);
  }
}

// ignore: missing_override_of_must_be_overridden
// class ConstEnumMapInitWithKeys<K extends Enum, V> extends ConstEnumMapInit<K, V> implements EnumMap<K, V> {
//   const ConstEnumMapInitWithKeys(this.keys, super.source);
//   @override
//   final List<K> keys;
// }
