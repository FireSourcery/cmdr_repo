// ignore_for_file: annotate_overrides

import 'struct.dart';
import 'enum_map.dart';

export 'enum_map.dart';

/// [Serializable] — a [StructBase] keyed by [SerializableField], whose `Enum.name` is the JSON key.
/// JSON side: [SerializableMethods.toJson] on the struct, `fromJson` on the key list ([StructForm]).
/// Keyed by `K` rather than the class, so access can use dot notation -> person[.age]
typedef Serializable<K extends SerializableField<Object?>> = StructBase<K, Object?>;

// mixin ImmutableSerializable<S,  K extends Field<Object?>> on Object implements StructBase<K, Object?>

/// [SerializableField<V>]/[NamedField]
/// a key to each field, an type parameter, with an generated string, use as json key;
/// effectively describe the memory allocation requirements
/// maps entirety of the struct
abstract mixin class SerializableField<V>() implements Enum, Field<V> {
  // a function using a known interface access the fields of the user's class, maps ids to getters
  // within scope of V, for auto type checking. otherwise data class map
  // V getIn(covariant Serializable struct);
  V getIn(covariant Object struct);
  void setIn(covariant Object struct, V value);
  bool testAccess(covariant Object struct);

  // V? validateType(Serializable data) => data[this] is V ? data[this] as V : null;

  bool isTypeOf(Object? value) => value is V;
  V? validateType(Object? value) => ((value is V) ? value : null);

  Type get type => V;
}

// named Key
extension SerializableKeys<K extends SerializableField<V>, V> on StructForm<K, V> {
  /// [fromJson] common implementation
  /// returrns a Map buffer to caller. necessary before the Serializable subtype memory layout is known
  /// double buffers, however it should only be a small number of field reference
  ///
  // the user side class provides a function to map the values of a known memory layout/interface to the user's class' memory layout
  // one point of interface to the base class
  // SerializablePerson.fromMap(Map<SerializableField, Object?> base)
  //   : id = base[SerializablePersonField.id] as int,
  //     name = base[SerializablePersonField.name] as String,
  //     age = base[SerializablePersonField.age] as int;
  //
  // function composition, go through a intermediary step of jsonMap -> known memory layout/interface -> user's class, at runtime.
  // Form.fromJson(json) -> StructMap -> PersonB.cast(StructMap) -> PersonB, at runtime.
  // factory SerializablePerson.fromJson(Map<String, Object?> json) => SerializablePerson.fromMap(const StructForm(SerializablePersonField.values).fromJson(json));
  //
  // code gen can directly map jsonMap -> user class, which is most direct during runtime.
  // however the code for mapping json directly to the user class, unique to each user class, would also require additional code size

  FieldMap<K, V> fromJson(Map<String, Object?> json) {
    return EnumMapFactory<K>(fields).fromJson<V>(json); // EnumMapFactory handles V type
  }

  ///
  // Iterable<MapEntry<K, V>> unmapEntriesByName(Map<String, V> values) => fields.map((e) => MapEntry(e, values[e.name] as V));

  // Iterable<MapEntry<K, V>> entriesFromJson(Map<String, Object?> json) {
  //   if (json case Map<String, V> validMap) {
  //     return unmapEntriesByName(validMap);
  //   } else {
  //     throw FormatException('Invalid JSON map for ${K.runtimeType}: $json');
  //   }
  // }
}

// V is object, non nullable version
extension SerializableValueObjects<K extends SerializableField<Object>> on StructForm<K, Object> {
  bool compareTypes(Iterable<Object?> objects) => objects.indexed.every((e) => fields[e.$1].isTypeOf(e.$2));

  FieldMap<K, Object> fromJson(Map<String, Object?> json) {
    // Map<K, Object> enumMap = EnumMapFactory<K>(fields).fromJson<Object>(json);
    // if (compareTypes(enumMap.values)) {
    //   return enumMap;
    // } else {
    //   throw FormatException('Invalid JSON map for ${runtimeType}: $json - value types do not match expected types');
    // }

    return {
      for (final e in fields)
        // null as type error
        if (e.validateType(json[e.name]) case Object? value)
          e: value ?? (throw FormatException('Invalid JSON $json - value for key "${e.name}" is <${value.runtimeType}>$value but expected type is non-nullable ${e.type}')),
    };
  }
}

extension SerializableNullableType<K extends SerializableField<Object?>> on StructForm<K, Object?> {
  FieldMap<K, Object?> fromJson(Map<String, Object?> json) {
    return {for (final e in fields) e: e.validateType(json[e.name])};
  }
}

extension SerializableMethods on Serializable {
  Map<String, Object?> toJson() => toMap().toJson();
}

typedef FieldMap<K extends Field<V>, V> = Map<K, V>;

/// optional
// caller handle Object? if nullable
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
  S withField(Field key, Object? value) => copyWithMap(_bufferCopy()..[key] = value);

  // tod copy non null only, let copyWithMap handle mapping only
  S withFields(Iterable<FieldEntry<Field, Object?>> newEntries) => copyWithMap(_bufferCopy()..addEntries(newEntries.map((e) => MapEntry(e.key, e.value))));
  S withMap(Map<Field, Object?> map) => copyWithMap(_bufferCopy()..addAll(map));
}
