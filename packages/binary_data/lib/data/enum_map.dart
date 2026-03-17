import 'basic_types.dart';
import 'index_map.dart';

export 'index_map.dart';

/// directly construct a Map<K, V> from Map<String, V>
/// on creation ensure all fields are valid
// returning a regular HashMap, which is likely already index based in the case of Enum
// alternatively wrap with FixedMap constraints
extension type const EnumMapFactory<T extends Enum>(List<T> enums) implements List<T> {
  // V determined by keys
  IndexMap<T, V> _fixedMap<V>(Iterable<V> values) {
    if (values.length != length) throw ArgumentError('Values length must match keys length');
    return IndexMap.of(this, values);
  }

  Map<T, V> _hashMap<V>(Iterable<V> values) {
    if (values.length != length) throw ArgumentError('Values length must match keys length');
    return <T, V>{for (final e in this) e: values.elementAt(e.index)};
  }

  /// iterable values must be in order of each index
  Map<T, V> withValues<V>(Iterable<V> values) => _fixedMap(values);

  Map<T, V> fromJson<V>(Map<String, Object?> json) {
    if (json case Map<String, V>()) {
      return _fromJson<V>(json);
    } else {
      return _fromJsonMixed(json) as Map<T, V>;
    }
  }
  // check caller use cases to determine whether to return nullable

  // Iterable<MapEntry<T, V>>
  // less iteration, by going through enum list
  // without reverse by name lookup, string compare either way
  Iterable<(T, V)> mapByName<V>(Map<String, V> values) => map((e) => (e, values[e.name]!));

  Iterable<(T, V?)> mapByNameOrNull<V>(Map<String, V> values) => map((e) => (e, values[e.name]));

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
    if (enums case List<TypeKey>()) {
      return <T, Object?>{
        for (final (key, value) in mapByName(json))
          if ((key as TypeKey).compareType(value)) key: value,
      };
    } else {
      throw FormatException('EnumType: $T must implement TypeKey for type checking');
    }
  }

  // optionally partial if json only contains some keys,
  // or  then return nullable values or throw error if missing keys
}

// hold constructors
// V is determine dby keys
extension type EnumMap<K extends Enum, V>._(IndexMap<K, V> map) implements IndexMap<K, V> {
  factory EnumMap.fromJson(List<K> keys, Map<String, Object?> json) {
    return EnumMapFactory<K>(keys).fromJson(json) as EnumMap<K, V>;
  }
}

/// Serialization of [Map<Enum, V>] interface
/// Apply to all types of [Map<Enum, V>]
/// Enum.name base methods are applicable regardless of EnumMap FixedMap constraints
/// [add] fills existing Map only
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

  // fill values from json  // loadFromJson
  // return as object implemented in Factory class
  void addJson(Map<String, Object?> json) => addAllByName(_validateJson(json));

  // handle mixed types case, V is defined as Object?
  bool _validateTypes(Map<String, V> json) => (keys as List<TypeKey>).every((key) => key.compareType(json[(key as Enum).name]));

  // bool _validateV(Map<String, Object?> json) => (json is Map<String, V>);
  // bool _validateObject(Map<String, Object?> json) {}

  Map<String, V> _validateJson(Map<String, Object?> json) {
    if (json is Map<String, V>) {
      // handle mixed types case, V is defined as Object?
      if (keys case List<TypeKey> typedKeys) {
        for (final key in typedKeys) {
          //json[(key as Enum).name] return null matches key type if nullable
          if (!key.compareType(json[(key as Enum).name])) throw FormatException('$runtimeType: ${(key as Enum).name} is not of type ${key.type}');
        }
      }
      return json;
    }
    throw FormatException('$runtimeType: $json is not of type Map<String, $V>');
  }
}

extension EnumNamedValues<K extends Enum, V> on Iterable<MapEntry<K, V>> {
  // on Iterable entries better fit after selection
  Iterable<(String name, MapEntry<K, V> entry)> get named => map((e) => (e.key.name, e));
  Iterable<(String name, V value)> get namedValues => map((e) => (e.key.name, e.value));
}

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
// abstract mixin class EnumMap<K extends Enum, V> implements FixedMap<K, V> {
//   const EnumMap();
//   factory EnumMap.of(List<K> keys, Iterable<V> values) = EnumIndexMap.of;

//   /// keys => Enum.values which implement byName(String name)
//   // factory EnumMap.fromJson(List<K> keys, Map<String, Object?> json) {
//   //   // return EnumIndexMap<K, V>.fromBase(keys, EnumIndexMap<K, V?>.filled(keys, null)..addJson(json));
//   //   return EnumIndexMap<K, V>.fromMap(keys, <K, V>{}..addJson(json));
//   // }

//   @override
//   List<K> get keys; // Enum.values
//   // V operator [](covariant K key);
//   // void operator []=(covariant K key, V value);
//   // void clear();
//   // V remove(covariant K key);
// }

// class EnumIndexMap<K extends Enum, V> = IndexMap<K, V> with EnumMap<K, V>;
// class EnumProxyMap<K extends Enum, V> = ProxyIndexMap<K, V> with EnumMap<K, V>;
