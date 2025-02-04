import 'package:meta/meta.dart';

import 'package:type_ext/type_ext.dart';
import 'basic_types.dart';
export 'basic_types.dart';
import 'index_map.dart';
export 'index_map.dart';

/// [EnumMap]
///   A [Map] with the additional constraint that Keys are a `fixed set`, via [Enum].
///   implements [FixedMap]/[IndexMap] constraints
///   factory constructors build [IndexMap] by default
///
///   Adds Serialization using Enum.name to a [Map],
///   Keys inherit from Enum -
///     index via Enum.index -> create a parallel array map by default
///     String name via Enum.name -> directly use for serialization
///
/// `abstract mixin class` combines interface and implemented methods
abstract mixin class EnumMap<K extends Enum, V> implements FixedMap<K, V> {
  const EnumMap();

  factory EnumMap.of(List<K> keys, Iterable<V> values) = EnumIndexMap.of;

  /// keys => Enum.values which implement byName(String name)
  factory EnumMap.fromJson(List<K> keys, Map<String, Object?> json) {
    return EnumIndexMap<K, V>.fromBase(EnumIndexMap<K, V?>.filled(keys, null)..addJson(json));
  }

  static Map<V, K> buildReverse<K extends Enum, V>(List<K> keys, [V Function(K)? valueOf]) {
    if (valueOf != null) {
      return keys.asReverseMap(valueOf);
    } else {
      assert(V == int, 'EnumMap: $V must be defined for reverseMap');
      return keys.asMap() as Map<V, K>; // index by default
    }
  }

  List<K> get keys; // Enum.values
  V operator [](covariant K key);
  void operator []=(covariant K key, V value);
  void clear();
  V remove(covariant K key);
}

/// Apply to [EnumMap<K, V>] as well as [Map<Enum, V>]
/// Enum.name base methods are applicable regardless of EnumMap FixedMap constraints
extension EnumMapByName<K extends Enum, V> on Map<K, V> {
  ////////////////////////////////////////////////////////////////////////////////
  /// Named Values
  ////////////////////////////////////////////////////////////////////////////////
  // String name, value pairs
  Iterable<(String name, V value)> get namedValues => keys.map((e) => (e.name, this[e] as V));

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
      // handle mixed types case, V is defined as Object?
      if (keys case List<TypeKey> typedKeys) {
        // can types be implemented separately?
        for (final key in typedKeys) {
          if (!key.compareType(json[(key as Enum).name])) throw FormatException('$runtimeType: ${(key as Enum).name} is not of type ${key.type}');
        }
      }
      return json;
    }
    throw FormatException('$runtimeType: $json is not of type Map<String, $V>');
  }
}

extension EnumNamedValues<K extends Enum, V> on Iterable<MapEntry<K, V>> {
  Iterable<(String name, V value)> get named => map((e) => (e.key.name, e.value));
  // Iterable<(String name, MapEntry<K, V> entry)> get named => map((e) => (e.key.name, e));
}

// only necessary for mixed V type keys
// abstract interface class TypedEnumKey<V> implements Enum, TypeKey<V> {}

class EnumIndexMap<K extends Enum, V> = IndexMap<K, V> with EnumMap<K, V>;
class EnumProxyMap<K extends Enum, V> = ProxyIndexMap<K, V> with EnumMap<K, V>;

// extension type const EnumIdFactory<K extends Enum, V>._(Map<V, K> reverseMap) {
//   EnumIdFactory.of(List<K> keys) : reverseMap = EnumMap.buildReverseMap<K, V>(keys);
//   K? idOf(V mappedValue) => reverseMap[mappedValue];
// }

// if inheriting factory constructors is needed
// extension type const EnumMapFactory<K extends Enum, V>(List<K> keys) {
//   // EnumMap fromJson(Map<String, Object?> json) {
//   //   return EnumIndexMap<K, V>.castBase(EnumIndexMap<K, V?>.filled(keys, null)..addJson(json));
//   // }
// }
