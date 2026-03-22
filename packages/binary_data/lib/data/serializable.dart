import 'struct.dart';

import 'enum_map.dart';
export 'enum_map.dart';

/// [Serializable] -
/// mixin in 1 step for serialization
/// provide toMap or implements MapBase and duplicate code until combine mixin is support
/// mixin toMap<K extends Enum, V>
/// implmenting Map would require subclasses to mixin MapBase
mixin Serializable<S extends Serializable<S>> on Object implements StructureBase<S, SerializableKey, Object?> {
  List<SerializableKey<Object?>> get keys;
  Structure<SerializableKey, dynamic> get data => this as Structure<SerializableKey, dynamic>; // data passed to Keys

  // duplicate code until combine mixin is support
  Object? operator [](covariant SerializableKey key) => data[key];
  void operator []=(covariant SerializableKey key, Object? value) => data[key] = value;
  Object? fieldOrNull(SerializableKey key) => data.fieldOrNull(key);
  bool trySetField(SerializableKey key, Object? value) => data.trySetField(key, value);
  StructField<V> field<V>(covariant SerializableKey<V> key) => data.field(key);
  Iterable<Object?> get values => keys.map((k) => this[k]);
  Iterable<StructField<Object?>> get fields => keys.map((k) => (key: k, value: this[k]));
  StructForm<SerializableKey, Object?> get _type => StructForm<SerializableKey, Object?>(keys);

  SerializableData<SerializableKey, Object?> toMap() => _type.mapWithData(data);
  // S copyWithMap(covariant SerializableData<SerializableKey, Object?> data);

  // SerializableData<SerializableKey, Object?> _bufferCopy() => toMap();
  // // using index map by default
  // // optionally override each in the  child class,=
  // S withField<V>(covariant SerializableKey<V> key, V value) => copyWithMap(_bufferCopy()..[key] = value);
  // // tod copy non null only, let copyWithMap handle mapping only
  // S withFields(covariant Iterable<FieldEntry<SerializableKey, Object?>> newEntries) => copyWithMap(_bufferCopy()..addEntries(newEntries.map((e) => MapEntry(e.key, e.value))));
  // S withMap(covariant Map<SerializableKey, Object?> map) => copyWithMap(_bufferCopy()..addAll(map));

  // ---------------------------------------------------------------------------
  // Value equality
  // ---------------------------------------------------------------------------
  @override
  int get hashCode => keys.fold(0, (prev, key) => prev ^ this[key].hashCode);

  /// Value equality: two structures are equal if they share the same keys
  /// reference (same schema) and all corresponding field values are equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Serializable<S>) return false;
    // Keys lists for enum types are const singletons; identity means same schema.
    if (!identical(keys, other.keys)) {
      if (keys.length != other.keys.length) return false;
    }
    for (final key in keys) {
      if (this[key] != other[key]) return false;
    }
    return true;
  }

  @override
  String toString() => '$S(${keys.map((k) => '$k: ${this[k]}').join(', ')})';
}
// typedef _SerializableDef<S extends StructureBase<S, Field<Object>, Object>> = StructureBase<S, Field<Object>, Object>;
// typedef _SerializableNullable<S extends StructureBase<S, Field<Object?>, Object?>> = StructureBase<S, Field<Object?>, Object?>;
// mixin SerializableDef<S extends SerializableDef<S>> on Object implements _SerializableDef<S> {}

/// optional
// caller ahndle Object? if nullable
mixin Immutable<S extends Immutable<S>> {
  // ---------------------------------------------------------------------------
  // Subtypes override copyWith via their own constructor.
  // ---------------------------------------------------------------------------
  // immutable `with` copy operations, via IndexMap
  // analogous to operator []=, but returns a new instance

  S copyWithMap(Map<Field, Object?> data);
  Map<Field, Object?> toMap();
  Map<Field, Object?> _bufferCopy() => toMap();

  // using index map by default
  // optionally override each in the  child class,=
  S withField<V>(Field<V> key, V value) => copyWithMap(_bufferCopy()..[key] = value);

  // tod copy non null only, let copyWithMap handle mapping only
  S withFields(Iterable<FieldEntry<Field, Object?>> newEntries) => copyWithMap(_bufferCopy()..addEntries(newEntries.map((e) => MapEntry(e.key, e.value))));
  S withMap(Map<Field, Object?> map) => copyWithMap(_bufferCopy()..addAll(map));
}

// [NamedField]
abstract mixin class SerializableKey<V> implements Enum, Field<V> {
  V getIn(covariant Object struct);

  void setIn(covariant Object struct, V value);
  bool testAccess(covariant Object struct);

  bool compareType(Object? object) => object is V;
}

extension SerializableKeys<K extends SerializableKey<V>, V> on StructForm<K, V> {
  /// [fromJson] common implementation
  SerializableData<K, V> fromJson(Map<String, Object?> json) {
    return EnumMapFactory<K>(fields).fromJson<V>(json); // EnumMapFactory handles V type
  }

  ///
  Iterable<MapEntry<K, V>> unmapEntriesByName(Map<String, V> values) => fields.map((e) => MapEntry(e, values[e.name] as V));

  EnumMapFactory<K> get _asEnumType => EnumMapFactory<K>(fields);

  Iterable<MapEntry<K, V>> entriesFromJson(Map<String, Object?> json) {
    if (json case Map<String, V> validMap) {
      return unmapEntriesByName(validMap);
    } else {
      throw FormatException('Invalid JSON map for ${K.runtimeType}: $json');
    }
  }

  // handle non map related interface including completeness
  // Structure<K, V?> _validate(Structure<K, Object?> struct) {
  //   if (V == Object && null is V) return struct as Structure<K, V?>; // skip validation if nullable
  //   return
  // }

  // Structure<K, V> cast(Structure struct) => Structure<K, V>(struct); //   cast if the K,V match

  // operators with creation reuturn StructBase on IndexMap
  // StructBase<K, V> createWith(Structure<K, V> struct, Iterable<StructField<V>> fields) => CoStructure(IndexMap<K, V>.of(fields, struct.fields(fields))..[key] = value);
  // index map handles checking keys passed.
  //  inherit by serializable keys
  // StructBase<K, V>? validate(Map<K, V> struct)
  // {
  //     fields.indexed.every((e) => e.$1 == e.$2.index)
  //     assert(_valuesBuffer.length == fields.length, 'Values buffer must match keys length');
  //     CoStructure.of(fields, fields.map((key) => struct[key] as V));
  // }
}

extension SerializableKeysType<K extends SerializableKey<Object>> on StructForm<K, Object> {
  bool compareTypes(Iterable<Object?> objects) => objects.indexed.every((e) => fields[e.$1].compareType(e.$2));

  SerializableData<K, Object> fromJson(Map<String, Object?> json) {
    Map<K, Object> enumMap = EnumMapFactory<K>(fields).fromJson<Object>(json); // EnumMapFactory handles V type
    if (compareTypes(enumMap.values)) {
      return enumMap;
    } else {
      throw FormatException('Invalid JSON map for ${K.runtimeType}: $json - value types do not match expected types');
    }
    // per item message
    //  if (!key.compareType(json[(key as Enum).name])) throw FormatException('$runtimeType: ${(key as Enum).name} is not of type ${key.type}');
  }
}

extension SerializableMethods on Serializable<dynamic> {
  Map<String, Object?> toJson() => toMap().toJson();
}

typedef SerializableData<K extends SerializableKey<V>, V> = Map<K, V>;
