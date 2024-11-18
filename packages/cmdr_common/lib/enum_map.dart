import 'dart:collection';
export 'dart:collection';
import 'package:meta/meta.dart';
export 'package:meta/meta.dart';

import 'basic_types.dart';
export 'basic_types.dart';
import 'index_map.dart';

/// [EnumMap]
///   A [Map] with the additional constraint that Keys are a `fixed set`, via [Enum].
///   implements [TypedMap]/[IndexMap] constraints
///   optimized for small fixed set of keys
///     guarantees all keys are present
///     can guarantee non null return - if V is defined as non nullable
///   factory constructors build [IndexMap] by default
///
///   Adds Serialization using Enum.name to a [Map],
///   Keys inherit from Enum -
///     index via Enum.index -> create a parallel array map by default
///     String name via Enum.name -> directly use for serialization
///
/// `abstract mixin class` combines interface and implemented methods
abstract mixin class EnumMap<K extends Enum, V> implements TypedMap<K, V> {
  const EnumMap();

  factory EnumMap.of(List<K> keys, Iterable<V> values) = EnumIndexMap.of;

  factory EnumMap.fromJson(List<K> keys, Map<String, Object?> json) {
    return EnumIndexMap<K, V>.castBase(EnumIndexMap<K, V?>.filled(keys, null)..addJson(json));
  }

  List<K> get keys; // Enum.values
  V operator [](covariant K key);
  void operator []=(covariant K key, V value);
  void clear();
  V remove(covariant K key);

  // @override
  // String toString() => MapBase.mapToString(this);
  ////////////////////////////////////////////////////////////////////////////////
  /// Convenience methods
  ////////////////////////////////////////////////////////////////////////////////
  Iterable<(K, V)> get pairs => keys.map((e) => (e, this[e]));
  Iterable<({K key, V value})> get fields => keys.map((e) => (key: e, value: this[e]));

  ///  move to construct
  dynamic copyWith() => this;

  // analogous to operator []=, but returns a new instance
  EnumMap<K, V> withField(K key, V value) => (ProxyEnumMap<K, V>(this)..[key] = value);
  //
  EnumMap<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => (ProxyEnumMap<K, V>(this)..addEntries(newEntries));
  // A general values map representing external input, may be a partial map
  EnumMap<K, V> withAll(Map<K, V> map) => (ProxyEnumMap<K, V>(this)..addAll(map));
}

/// Apply to [EnumMap<K, V>] as well as [Map<Enum, V>]
// Enum.name base methods are applicable regardless of EnumMap constraints
extension EnumMapMethods<K extends Enum, V> on Map<K, V> {
  ////////////////////////////////////////////////////////////////////////////////
  /// Named Values
  ////////////////////////////////////////////////////////////////////////////////
  // String name, value pairs
  Iterable<(String name, V value)> get namedPairs => keys.map((e) => (e.name, this[e] as V));
  Iterable<({String name, V value})> get entriesByName => keys.map((e) => (name: e.name, value: this[e] as V));
  // Iterable<({String name, K key, V value})> get triplets => keys.map((e) => (name: e.name, key: e, value: this[e] as V));

  ////////////////////////////////////////////////////////////////////////////////
  /// Buffer Case -
  ////////////////////////////////////////////////////////////////////////////////
  Map<String, V> toMapByName() => {for (final key in keys) key.name: this[key] as V};
  void addAllByName(Map<String, V> map) => addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)));

  ////////////////////////////////////////////////////////////////////////////////
  /// Json -
  ///   only if child class is implemented as mutable
  ///   i.e. []= is defined
  ////////////////////////////////////////////////////////////////////////////////
  Map<String, Object?> toJson() => toMapByName();
  // fill values from json
  void addJson(Map<String, Object?> json) => addAllByName(validateJson(json));

  Map<String, V> validateJson(Map<String, Object?> json) {
    if (json is Map<String, V>) {
      // handle mixed types case, V is Object
      if (keys is List<TypedEnumKey>) {
        for (final TypedEnumKey key in keys as List<TypedEnumKey>) {
          if (!key.compareType(json[key.name])) throw FormatException('$runtimeType: ${key.name} is not of type ${key.type}');
        }
      }
      return json;
    }
    throw FormatException('$runtimeType: $json is not of type Map<String, V>');
  }
}

extension EnumNamedValues<K extends Enum, V> on Iterable<MapEntry<K, V>> {
  Iterable<(String name, V value)> get named => map((e) => (e.key.name, e.value));
}

// only necessary for mixed V type keys
abstract interface class TypedEnumKey<V> implements Enum, TypeKey<V> {}

class EnumIndexMap<K extends Enum, V> = IndexMap<K, V> with EnumMap<K, V>;
class ProxyEnumMap<K extends Enum, V> = ProxyIndexMap<K, V> with EnumMap<K, V>;

// cast of general map - must have all keys
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
// class ConstEnumMapInit<K extends Enum, V> extends EnumMapBase<K, V> implements EnumMap<K, V> {
//   const ConstEnumMapInit(this.source);

//   @protected
//   final Map<K, V> source;

//   @override
//   V operator [](covariant K key) => source[key]!;

//   @override
//   void operator []=(K key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
//   @override
//   void clear() => throw UnsupportedError("Cannot modify unmodifiable");
//   @override
//   V remove(covariant K key) => throw UnsupportedError("Cannot modify unmodifiable");

//   @override
//   List<K> get keys {
//     if (source is EnumMap<K, V>) return (source as EnumMap<K, V>).keys; // only step to generalize for EnumMap as source
//     return UnmodifiableListView(source.keys);
//   }
// }

/// move to Construct

/// default implementation of immutable copy as subtype
/// auto typing return as Subtype class.
/// copy references to a new buffer, then pass to child constructor
///    Subtype class can override to optimize
mixin EnumMapAsSubtype<S extends EnumMap<K, V>, K extends Enum, V> on EnumMap<K, V> {
  // Overridden the in child class
  //  calls the child class constructor
  //  return an instance of the child class type
  //  passing empty parameters always copies all values
  @override
  @mustBeOverridden
  S copyWith();

  @override
  S withField(K key, V value) => (super.withField(key, value)).copyWith();
  @override
  S withEntries(Iterable<MapEntry<K, V>> entries) => (super.withEntries(entries)).copyWith();
  @override
  S withAll(Map<K, V> map) => (super.withAll(map)).copyWith();
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
// extension type const EnumMapFactory<S extends EnumMap<K, V>, K extends Enum, V>(List<K> keys) {
//   // only this needs to be redefined in child class
//   // or castFrom
//   S castBase(EnumMap<K, V> state) => state as S;

//   // alternatively use copyWith.
//   // or allow user end to maintain 2 separate routines?
//   // also separates cast as subtype from EnumMap class

//   // EnumMap<K, V?> create({EnumMap<K, V>? state, V? fill}) {
//   //   if (state == null) {
//   //     return EnumMapDefault<K, V?>.filled(keys, null);
//   //   } else {
//   //     return castBase(state);
//   //   }
//   // }

//   // EnumMap<K, V?> filled(V? fill) => EnumMapDefault<K, V?>.filled(keys, null);
//   // EnumMap<K, V?> fromValues([List<V>? values, V? fill]) => EnumMapDefault<K, V?>._fromValues(keys, values);

//   EnumMap<K, V> _fromEntries(Iterable<MapEntry<K, V>> entries) => EnumIndexMap<K, V>.fromEntries(keys, entries);

//   // assert all keys are present
//   S fromEntries(Iterable<MapEntry<K, V>> entries) => castBase(_fromEntries(entries));
//   S fromMap(Map<K, V> map) => castBase(_fromEntries(map.entries));

//   // parseJson()
//   // by default allocate new list buffer
//   EnumMap<K, V> _fromJson(Map<String, Object?> json) {
//     if (json is Map<String, V>) {
//       // field of mixed types case, check type
//       if (keys is List<TypedEnumKey>) {
//         for (final key in keys as List<TypedEnumKey>) {
//           if (!key.compareType(json[key.name])) throw FormatException('EnumMap.fromJson: ${key.name} is not of type ${key.type}');
//         }
//       }
//       return _fromEntries(json.entries.map((e) => MapEntry(keys.byName(e.key), e.value)));
//     } else {
//       throw FormatException('EnumMap.fromJson: $json is not of type Map<String, V>');
//     }
//   }

//   S fromJson(Map<String, Object?> json) => castBase(_fromJson(json));
// }
