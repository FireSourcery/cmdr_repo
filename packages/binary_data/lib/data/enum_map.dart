import 'index_map.dart';

export 'index_map.dart';

/// construct a Map<K, V> from Map<String, V>
/// on creation ensure all fields are valid
extension type const EnumMapFactory<T extends Enum>(List<T> enums) implements List<T> {
  /// iterable values must be in order of each index
  Map<T, V> mapWithValues<V>(Iterable<V> values) => IndexMap.of(this, values);

  // Iterable<MapEntry<T, V>>
  // less iteration, by going through enum list
  // without reverse by name lookup
  Iterable<(T, V)> unmapByName<V>(Map<String, V> values) => map((e) => (e, values[e.name]!));
  Iterable<(T, V?)> unmapByNameOrNull<V>(Map<String, V?> values) => map((e) => (e, values[e.name]));
  Iterable<MapEntry<T, V>> unmapEntriesByName<V>(Map<String, V> values) => map((e) => MapEntry(e, values[e.name]!));

  // complete map only. partial can use addMapByName
  Map<T, V> fromMapByName<V>(Map<String, V> map) {
    if (enums.every((e) => map.containsKey(e.name))) {
      return {for (final e in enums) e: map[e.name] as V};
    } else {
      throw FormatException('$enums: $map keys must match enum names');
    }
  }

  // serializable handl Object? cases
  Map<T, V> fromJson<V>(Map<String, Object?> json) {
    if (json case Map<String, V> map) {
      return fromMapByName<V>(map);
    } else {
      throw FormatException('$enums: $json is not of type Map<String, $V>');
    }
  }

  // optionally partial if json only contains some keys,
  // or  then return nullable values or throw error if missing keys
}

/// [EnumMap]
/// A [Map] with the additional constraint that Keys are a `fixed set`, via [Enum].
/// creation implements [FixedMap]/[IndexMap] constraints
/// factory constructors build [IndexMap] by default

/// Adds Serialization using Enum.name to a [Map],
/// Keys inherit from Enum -
///   index via Enum.index -> create a parallel array map by default
///   String name via Enum.name -> directly use for serialization
///
/// effectively mixin [List<K> keys] for serialization
// hold constructors
extension type EnumMap<K extends Enum, V>._(Map<K, V> map) implements Map<K, V> {
  factory EnumMap.fromJson(List<K> keys, Map<String, Object?> json) {
    return EnumMapFactory<K>(keys).fromJson(json) as EnumMap<K, V>;
  }
}

/// Serialization of [Map<Enum, V>] interface
/// Methods on loose contraints [Map<Enum, V>]
/// Enum.name base methods are applicable regardless of EnumMap FixedMap constraints
/// [add] fills existing Map only
extension EnumMapByName<K extends Enum, V> on Map<K, V> {
  ////////////////////////////////////////////////////////////////////////////////
  /// Buffer Case -
  ////////////////////////////////////////////////////////////////////////////////
  // Map<String, V> toMapByName() => {for (final key in keys) key.name: this[key] as V};
  Map<String, V> toMapByName() => map((k, v) => MapEntry(k.name, v));

  void fromMapByName(Map<String, V> map) => addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)));
  void addMapByName(Map<String, V> map) {
    for (final key in keys.where((k) => map.containsKey(k.name))) {
      if (map[key.name] case V value when value != null) this[key] = value;
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Json -
  ///   only if child class is implemented as mutable
  ///   i.e. []= is defined
  ////////////////////////////////////////////////////////////////////////////////
  Map<String, V> toJson() => toMapByName();

  void addJson(Map<String, Object?> json) {
    // if (null is V) return; // need Field to check type. eg this[key] is null, json[key.name] is valid,
    for (final key in keys.where((k) => json.containsKey(k.name))) {
      if (json[key.name] case V value when value != null) this[key] = value;
    }
  }
}

extension EnumNamedValues<K extends Enum, V> on Iterable<MapEntry<K, V>> {
  // on Iterable entries better fit after selection
  Iterable<(String name, MapEntry<K, V> entry)> get named => map((e) => (e.key.name, e));
  Iterable<(String name, V value)> get namedValues => map((e) => (e.key.name, e.value));
}
