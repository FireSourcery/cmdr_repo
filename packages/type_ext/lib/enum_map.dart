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
    // return EnumIndexMap<K, V>.fromBase(keys, EnumIndexMap<K, V?>.filled(keys, null)..addJson(json));
    return EnumIndexMap<K, V>.fromMap(keys, <K, V>{}..addJson(json));
  }

  List<K> get keys; // Enum.values
  // V operator [](covariant K key);
  // void operator []=(covariant K key, V value);
  // void clear();
  // V remove(covariant K key);
}

/// directly construct a Map<K, V> from Map<String, V>
// returning a regular HashMap, which is likely already index based in the case of Enum
// alternatively wrap with FixedMap constraints
extension type const EnumMapFactory<T extends Enum>(List<T> enums) implements List<T> {
  Map<T, V> fromJson<V>(Map<String, dynamic> json) {
    if (json case Map<String, V>()) {
      return _fromJson<V>(json);
    } else {
      return _fromJsonMixed(json) as Map<T, V>;
    }
  }

  // Iterable<(T, V)> mapByName<V>(Map<String, V> values) => values.entries.map((e) => (enums.byName(e.key), e.value));
  // Iterable<MapEntry<T, V>> mapByName<V>(Map<String, V> values) => values.entries.map((e) => MapEntry(enums.byName(e.key), e.value));
  // less iteration through enum list
  Iterable<(T, V)> mapByName<V>(Map<String, V> values) => enums.map((e) => e.name).map((e) => (values[e] != null) ? (enums.byName(e), values[e]!) : null).nonNulls;

  // fast path if types already match
  Map<T, V> _fromJson<V>(Map<String, Object?> json) {
    if (json is Map<String, V>) {
      return <T, V>{for (final entry in mapByName(json)) entry.$1: entry.$2};
    } else {
      throw FormatException('$enums: $json is not of type Map<String, $V>');
    }
  }

  // mixed types case, V is Object?
  Map<T, Object?> _fromJsonMixed(Map<String, Object?> json) {
    // assert(enums is List<TypeKey>, 'EnumType: $T must implement TypeKey for type checking');
    if (enums case List<SerializableKey>()) {
      return <T, Object?>{
        for (final (key, value) in mapByName(json))
          if ((key as SerializableKey).compareType(value)) key: value
      };
    } else {
      throw FormatException('EnumType: $T must implement TypeKey for type checking');
    }
  }
}

/// Serialization of [Map<Enum, V>] interface
/// Apply to all types of [Map<Enum, V>]
/// Enum.name base methods are applicable regardless of EnumMap FixedMap constraints
extension EnumMapByName<K extends Enum, V> on Map<K, V> {
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

//replacably with EnumMapFactory methods
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

  ////////////////////////////////////////////////////////////////////////////////
  /// Named Values
  ////////////////////////////////////////////////////////////////////////////////
  // String name, value pairs
  // Iterable<(String name, V value)> get namedValues => keys.map((e) => (e.name, this[e] as V));
}

extension EnumNamedValues<K extends Enum, V> on Iterable<MapEntry<K, V>> {
  // on entries better fit after selection
  Iterable<(String name, MapEntry<K, V> entry)> get named => map((e) => (e.key.name, e));
  Iterable<(String name, V value)> get namedValues => map((e) => (e.key.name, e.value));
}

class EnumIndexMap<K extends Enum, V> = IndexMap<K, V> with EnumMap<K, V>;
class EnumProxyMap<K extends Enum, V> = ProxyIndexMap<K, V> with EnumMap<K, V>;

// available as mixin
// homogeneous fields
typedef Serializable<K extends Enum, V> = MapBase<K, V>;

// only necessary for mixed V type keys
abstract interface class SerializableKey<V> implements Enum, TypeKey<V> {}

// typedef SerializableData = Map<SerializableKey<dynamic>, Object?>;
// typedef SerializableData = Serializable<SerializableKey<dynamic>, Object?>;
typedef SerializableData<K extends SerializableKey<Object?>> = Serializable<K, Object?>;

// abstract mixin class SerializableData<V> implements Map<Enum, V> {
//   const Serializable();
//   List<K> get keys; // Enum.values
//    V operator [](covariant K key);
//   void operator []=(covariant K key, V value);
// }

// abstract mixin class EnumSerializable {
//   // Subclass must provide the enum values (field IDs)
//   List<Enum> get fieldIds;
  
//   // Subclass must implement field setters/getters
//   void setField(Enum id, dynamic value);
//   dynamic getField(Enum id);
  
//   // Inheritable fromJson using enum pairing
//   void fromJson(Map<String, dynamic> json) {
//     for (final id in fieldIds) {
//       final key = id.name;  // Use enum.name as JSON key
//       if (json.containsKey(key)) {
//         setField(id, json[key]);
//       }
//     }
//   }
  
//   // Optional: toJson for completeness
//   Map<String, dynamic> toJson() {
//     return {for (final id in fieldIds) id.name: getField(id)};
//   }
// }

