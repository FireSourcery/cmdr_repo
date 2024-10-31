// import 'dart:collection';

// import 'package:cmdr/common/basic_types.dart';
// import 'package:meta/meta.dart';
// import 'package:flutter/foundation.dart';

// /// [EnumMap] - A simplified map implementation
// ///   A [Map] with the additional constraint that Keys are a `fixed set`, via Enum.
// ///     guarantees all keys are present
// ///     can guarantee non null return - if V is defined as non nullable
// ///   Keys inherit from Enum -
// ///     index via Enum.index -> create a parallel array map by default
// ///     String name via Enum.name -> directly use for serialization
// /// `abstract mixin class` combines interface and implemented methods
// abstract mixin class EnumMap<K extends Enum, V> implements Map<K, V> {
//   const EnumMap();

//   @override
//   List<K> get keys; // Enum.values
//   @override
//   V operator [](covariant K key);
//   @override
//   void operator []=(covariant K key, V value);
//   @override
//   void clear();
//   @override
//   V? remove(covariant K key) => throw UnsupportedError('EnumMap does not support remove operation');

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Convenience methods
//   ////////////////////////////////////////////////////////////////////////////////
//   Iterable<({String name, V value})> get nameValues => keys.map((e) => (name: e.name, value: this[e]));

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Immutable Case
//   ////////////////////////////////////////////////////////////////////////////////
//   /// Overridden the in child class to call the child class constructor, returning a instance of the child class type
//   @mustBeOverridden
//   EnumMap<K, V> copyWith() => this;

//   /// default implementation -> copy to a new buffer, then pass to child constructor
//   /// an child class can override to skip buffering

//   // analogous to operator []=, but returns a new instance
//   EnumMap<K, V> withField(K key, V value) => (EnumMapProxy<K, V>(this)..[key] = value).copyWith();
//   EnumMap<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => (EnumMapProxy<K, V>(this)..addEntries(newEntries)).copyWith();
//   // A general values map representing external input, may be a partial map
//   EnumMap<K, V> withAll(Map<K, V> map) => (EnumMapProxy<K, V>(this)..addAll(map)).copyWith();

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Mutable Case -
//   ///   only if child class is implemented as mutable
//   ///   i.e. []= is defined
//   ////////////////////////////////////////////////////////////////////////////////

//   // fill values from json
//   void addJson(Map<String, Object?> json) {
//     if (json is Map<String, V>) {
//       // handle mixed types case, V is Object
//       if (keys is List<TypedEnumKey>) {
//         for (final TypedEnumKey key in keys as List<TypedEnumKey>) {
//           if (!key.compareType(json[key.name])) throw FormatException('$runtimeType: ${key.name} is not of type ${key.type}');
//         }
//       }
//       // homogeneous V case
//       addAllByName(json);
//     } else {
//       throw FormatException('$runtimeType: $json is not of type Map<String, V>');
//     }
//   }

//   // from jsonMap
//   void addAllByName(Map<String, V> map) => addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)));

//   Map<String, V> toMapByName() => {for (final key in keys) key.name: this[key]};

//   Map<String, Object?> toJson() => toMapByName();
// }

// // combine mixins
// abstract class EnumMapBase<K extends Enum, V> = MapBase<K, V> with EnumMap<K, V>;

// /// auto typing return as child class.
// mixin EnumMapAsSubtype<S extends EnumMap<K, V>, K extends Enum, V> on EnumMap<K, V> {
//   @override
//   S withField(K key, V value) => super.withField(key, value) as S;
//   @override
//   S withEntries(Iterable<MapEntry<K, V>> entries) => super.withEntries(entries) as S;
//   @override
//   S withAll(Map<K, V> map) => super.withAll(map) as S;
// }

// typedef EnumKey = Enum;

// // only necessary for mixed V type keys
// abstract mixin class TypedEnumKey<V> implements Enum, TypeKey<V> {}

// /// Class/Type/Factory
// /// Effectively inheritable factory constructors
// extension type const EnumMapFactory<S extends EnumMap<K, V>, K extends EnumKey, V>(List<K> keys) {
//   // only this needs to be redefined in child class
//   // or castFrom
//   S castBase(EnumMap<K, V> state) => state as S;

//   EnumMap<K, V> _fromEntries(Iterable<MapEntry<K, V>> entries) => EnumMapDefault<K, V>.fromEntries(keys, entries);

//   S fromEntries(Iterable<MapEntry<K, V>> entries) => castBase(_fromEntries(entries));
//   S fromMap(Map<K, V> map) => castBase(_fromEntries(map.entries));

//   // parseJson()
//   // by default allocate new list buffer
//   EnumMap<K, V> _fromJson(Map<String, Object?> json) {
//     final filled = EnumMapDefault<K, V?>.filled(keys, null)..addJson(json);
//     return EnumMapDefault._fromValues(keys, filled._values.cast<V>());
//   }

//   S fromJson(Map<String, Object?> json) => castBase(_fromJson(json));
// }

// /// Default implementation using parallel arrays
// class EnumMapDefault<K extends Enum, V> extends EnumMapBase<K, V> implements EnumMap<K, V> {
//   /// default by assignment. a new list should always be allocated
//   const EnumMapDefault._(this._keys, this._values) : assert(_keys.length == _values.length);

//   EnumMapDefault._fromValues(List<K> keys, Iterable<V> values) : this._(keys, List<V>.of(values, growable: false));

//   EnumMapDefault.filled(List<K> keys, V fill) : this._(keys, List<V>.filled(keys.length, fill, growable: false));

//   // pass original keys, do not derive from Map.keys
//   // possible with nullable V, if key is contains default value
//   EnumMapDefault.fromEntries(List<K> keys, Iterable<MapEntry<K, V>> entries)
//       : assert(keys.every((key) => entries.map((entry) => entry.key).contains(key))),
//         _keys = keys,
//         _values = (EnumMapDefault<K, V?>.filled(keys, null)..addEntries(entries))._values.cast<V>(),
//         super();

//   // default copyFrom implementation
//   EnumMapDefault.castBase(EnumMap<K, V> state) : this._(state.keys, List<V>.of(state.values, growable: false));

//   final List<K> _keys;
//   final List<V> _values;

//   @override
//   List<K> get keys => _keys;
//   @override
//   V operator [](K key) => _values[key.index]!;
//   @override
//   void operator []=(K key, V value) => _values[key.index] = value;
// }

// /// EnumMapWith -
// /// default copyWith implementation via replacement/override
// /// a builder surrogate optimized for case replacing a single, or few entries
// /// create a new view with an additionally allocated buffer for replacements.
// /// necessary before the subtype memory layout is known
// ///
// // ignore: missing_override_of_must_be_overridden
// class EnumMapProxy<K extends Enum, V> extends EnumMapBase<K, V> implements EnumMap<K, V> {
//   const EnumMapProxy._(this._source, this._modified);
//   EnumMapProxy(EnumMap<K, V> source) : this._(source, EnumMapDefault<K, V?>.filled(source.keys, null));

//   final EnumMap<K, V> _source;

//   // a new EnumMap is preferable over a searchable List<MapEntry<K, V>> in most cases
//   //   equal to preemptively allocating a fixed size list
//   //   if a fixed size list is used, EnumMap allocates the same size buffer
//   //   a growable list either allocates a larger buffer or invoke performance penalties
//   final EnumMapDefault<K, V?> _modified;

//   @override
//   List<K> get keys => _source.keys;

//   @override
//   V operator [](K key) => _modified[key] ?? _source[key];

//   // optimized for multiple replacements, may not notify listeners until copyWith is called
//   @override
//   void operator []=(K key, V value) => _modified[key] = value;

//   @override
//   void clear() => throw UnsupportedError("Cannot modify unmodifiable");
// }
