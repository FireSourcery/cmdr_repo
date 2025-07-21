import 'basic_types.dart';
import 'index_map.dart';

export 'basic_types.dart';
export 'index_map.dart';

/// [EnumMap]
/// A [Map] with the additional constraint that Keys are a `fixed set`, via [Enum].
/// implements [FixedMap]/[IndexMap] constraints
/// factory constructors build [IndexMap] by default

/// Adds Serialization using Enum.name to a [Map],
/// Keys inherit from Enum -
///   index via Enum.index -> create a parallel array map by default
///   String name via Enum.name -> directly use for serialization
///
/// effectively mixin [List<K> keys] for serialization
///
/// `abstract mixin class` combines interface and implemented methods
abstract mixin class EnumMap<K extends Enum, V> implements FixedMap<K, V> {
  const EnumMap();

  factory EnumMap.of(List<K> keys, Iterable<V> values) = EnumIndexMap.of;

  /// keys => Enum.values which implement byName(String name)
  factory EnumMap.fromJson(List<K> keys, Map<String, Object?> json) {
    return EnumIndexMap<K, V>.fromBase(keys, EnumIndexMap<K, V?>.filled(keys, null)..addJson(json));
  }

  List<K> get keys; // Enum.values
  // V operator [](covariant K key);
  // void operator []=(covariant K key, V value);
  // void clear();
  // V remove(covariant K key);
}

/// Apply to all types of [Map<Enum, V>]
/// Enum.name base methods are applicable regardless of EnumMap FixedMap constraints
extension EnumMapByName<K extends Enum, V> on Map<K, V> {
  ////////////////////////////////////////////////////////////////////////////////
  /// Named Values
  ////////////////////////////////////////////////////////////////////////////////
  // String name, value pairs
  // Iterable<(String name, V value)> get namedValues => keys.map((e) => (e.name, this[e] as V));

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
  // loadFromJson
  // fill values from json
  void addJson(Map<String, Object?> json) => addAllByName(validateJson(json));

  // handle mixed types case, V is defined as Object?
  bool _validateTypes(Map<String, V> json) {
    if (keys case List<TypeKey> typedKeys) {
      for (final key in typedKeys) {
        if (!key.compareType(json[(key as Enum).name])) return false;
      }
    }
    return true;
  }

  Map<String, V> validateJson(Map<String, Object?> json) {
    if (json is Map<String, V>) {
      // handle mixed types case, V is defined as Object?
      if (keys case List<TypeKey> typedKeys) {
        // typedKeys.compareTypes(json.values)
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
  // on entries better fit after selection
  Iterable<(String name, MapEntry<K, V> entry)> get named => map((e) => (e.key.name, e));
  Iterable<(String name, V value)> get namedValues => map((e) => (e.key.name, e.value));
}

class EnumIndexMap<K extends Enum, V> = IndexMap<K, V> with EnumMap<K, V>;
class EnumProxyMap<K extends Enum, V> = ProxyIndexMap<K, V> with EnumMap<K, V>;

// homogeneous fields
// typedef Serializable<V> = Map<Enum, V>;

// only necessary for mixed V type keys
// abstract interface class SerializableKey<V> implements Enum, TypeKey<V> {}

// typedef SerializableData = Map<SerializableKey<dynamic>, Object?>;

// abstract mixin class Serializable<V> implements Map<Enum, V> {
//   const Serializable();
  // List<K> get keys; // Enum.values
//    V operator [](covariant K key);
//   void operator []=(covariant K key, V value);
// }