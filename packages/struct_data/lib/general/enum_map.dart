import 'index_map.dart';

export 'index_map.dart';

/// construct a [Map<K extends Enum, V>] from [Map<String, V>]
/// on creation ensure all fields are valid
extension type const EnumMapFactory<T extends Enum>(List<T> enums) implements List<T> {
  /// iterable values must be in order of each index
  EnumMap<T, V> mapWithValues<V>(Iterable<V> values) => IndexMap.of(this, values) as EnumMap<T, V>;

  EnumMap<T, V> mapByName<V>(Map<String, V> map) => mapWithValues(enums.map((e) => map[e.name] as V));

  // complete map only. partial can use addMapByName
  // map can contain excess keys.
  Map<T, V> fromMapByName<V>(Map<String, V?> map) {
    if (null is V) return {for (final e in enums) e: map[e.name] as V};
    // handle case of Map<String, V?> while containing all values.
    return {for (final e in enums) e: map[e.name] ?? (throw FormatException('$enums: $map contains null value for key ${e.name} which is not of type $V'))};

    // Index map handling allocation List this way.
    // if (null is V) return mapWithValues(enums.map((e) => map[e.name] as V));
    // return mapWithValues(enums.map((e) => map[e.name] ?? (throw FormatException('$enums: $map contains null value for key ${e.name} which is not of type $V'))));
  }

  Map<T, V> fromJson<V>(Map<String, Object?> json) {
    if (json case Map<String, V?> map) {
      return fromMapByName<V>(map);
    } else {
      throw FormatException('$enums: $json is not of type Map<String, $V>');
    }
  }

  // less iteration, by going through enum list
  // without reverse by name lookup
  // Iterable<(T, V)> unmapByName<V>(Map<String, V> values) => map((e) => (e, values[e.name]!));
  // Iterable<(T, V?)> unmapByNameOrNull<V>(Map<String, V?> values) => map((e) => (e, values[e.name]));
  // Iterable<MapEntry<T, V>> unmapEntriesByName<V>(Map<String, V> values) => map((e) => MapEntry(e, values[e.name]!));
  // void fromMapByName(Map<String, V> map) => addEntries(map.entries.map((e) => MapEntry(keys.byName(e.key), e.value)));
}

/// [EnumMap]
/// A [Map] with the additional constraint that Keys are a `fixed set`, via [Enum].
/// creation implements [FixedMap]/[IndexMap] constraints
/// factory constructors build [IndexMap] by default
/// wrap String handling via .name around IndexMap.

/// Adds Serialization using Enum.name to a [Map],
/// Keys inherit from Enum -
///   index via Enum.index -> create a parallel array map by default
///   String name via Enum.name -> directly use for serialization
///
/// effectively mixin [List<K extends Enum> keys] for serialization
// hold constructors
extension type EnumMap<K extends Enum, V>._(Map<K, V> map) implements Map<K, V> {
  factory EnumMap.from(List<K> keys, Iterable<V> values) {
    return EnumMapFactory<K>(keys).mapWithValues(values);
  }
}

/// Serialization of [Map<Enum, V>] interface
/// Methods on loose contraints [Map<Enum, V>]
/// Enum.name base methods are applicable regardless of EnumMap FixedMap constraints
/// [add] fills existing Map only
extension EnumMapByName<K extends Enum, V> on Map<K, V> {
  Map<String, V> toMapByName() => map((k, v) => MapEntry(k.name, v));

  // does not add null even if V is nullable, unlike creatation
  void addMapByName(Map<String, V> map) {
    for (final key in keys) {
      if (map[key.name] case V value?) this[key] = value;
    }
  }

  Map<String, V> toJson() => toMapByName();

  Iterable<(String name, V value)> get namedValues => keys.map((e) => (e.name, this[e]!));
}

///
/// Extensions
extension EnumNamedValues<K extends Enum, V> on Iterable<MapEntry<K, V>> {
  // on Iterable entries better fit after selection
  Iterable<(String name, MapEntry<K, V> entry)> get named => map((e) => (e.key.name, e));
  Iterable<(String name, V value)> get namedValues => map((e) => (e.key.name, e.value));
}
