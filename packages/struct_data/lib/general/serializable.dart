// ignore_for_file: annotate_overrides

import 'struct.dart';
import 'enum_map.dart';

export 'enum_map.dart';

/// [Serializable] -
/// mixin in 1 step for serialization
/// provide toMap or implements MapBase and duplicate code until combine mixin is support
/// mixin toMap
/// implmenting Map would require subclasses to mixin MapBase

// if K parameter is included.
// mixin Serializable<S extends Serializable<S>, K extends Field<Object?>> on Object implements StructBase<S, K, Object?>
// class definition becomes slightly more verbose -> class Person with  Serializable<Person, PersonField>
// however access can use dot notation -> person[.age] instead of person[PersonField.age]
//   person.withField(.age, 31) instead of person.withField(PersonField.age, 31)

mixin Serializable<S extends Serializable<S>> on Object implements StructBase<S, SerializableField, Object?> {
  List<SerializableField<Object?>> get keys;
  StructData<SerializableField, dynamic> get data => this as StructData<SerializableField, dynamic>; // data passed to Keys

  // duplicate code until combine mixin is support
  Object? operator [](covariant SerializableField key) => data[key];
  void operator []=(covariant SerializableField key, Object? value) => data[key] = value;
  Object? fieldOrNull(SerializableField key) => data.fieldOrNull(key);
  bool trySetField(SerializableField key, Object? value) => data.trySetField(key, value);
  SerializableEntry<Object?> field(covariant SerializableField key) => data.field(key);
  SerializableEntry<R> fieldAs<R>(covariant SerializableField<R> key) => data.fieldAs<R>(key) as SerializableEntry<R>;
  Iterable<Object?> get values => keys.map((k) => this[k]);
  Iterable<SerializableEntry<Object?>> get fields => keys.map((k) => (key: k, value: this[k]));
  StructForm<SerializableField, Object?> get _type => StructForm<SerializableField, Object?>(keys);

  FieldMap<SerializableField, Object?> toMap() => _type.mapWithData(data);

  // Value equality
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

typedef SerializableEntry<V> = ({SerializableField<V> key, V value});

/// [SerializableField<V>]/[NamedField]
/// a key to each field, an type parameter, with an generated string, use as json key;
/// effectively describe the memory allocation requirements
/// maps entirety of the struct
abstract mixin class SerializableField<V> implements Enum, Field<V> {
  // a function using a known interface access the fields of the user's class, maps ids to getters
  V getIn(covariant Object struct);
  void setIn(covariant Object struct, V value);
  bool testAccess(covariant Object struct);

  bool isTypeOf(Object? object) => object is V;
}

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
  Iterable<MapEntry<K, V>> unmapEntriesByName(Map<String, V> values) => fields.map((e) => MapEntry(e, values[e.name] as V));

  Iterable<MapEntry<K, V>> entriesFromJson(Map<String, Object?> json) {
    if (json case Map<String, V> validMap) {
      return unmapEntriesByName(validMap);
    } else {
      throw FormatException('Invalid JSON map for ${K.runtimeType}: $json');
    }
  }

  bool compareTypes(Iterable<Object?> objects) => objects.indexed.every((e) => fields[e.$1].isTypeOf(e.$2));

  Map<K, V>? validate(Map<K, V> struct) {
    if (compareTypes(struct.values)) return struct;
    return null;
  }
}

// V is object
extension SerializableKeysType<K extends SerializableField<Object>> on StructForm<K, Object> {
  FieldMap<K, Object> fromJson(Map<String, Object?> json) {
    Map<K, Object> enumMap = EnumMapFactory<K>(fields).fromJson<Object>(json); // EnumMapFactory handles V type
    if (compareTypes(enumMap.values)) {
      return enumMap;
    } else {
      throw FormatException('Invalid JSON map for ${K.runtimeType}: $json - value types do not match expected types');
    }
    // per item message
    //  if (!key.isTypeOf(json[(key as Enum).name])) throw FormatException('$runtimeType: ${(key as Enum).name} is not of type ${key.type}');
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
  S withFields(Iterable<StructField<Field, Object?>> newEntries) => copyWithMap(_bufferCopy()..addEntries(newEntries.map((e) => MapEntry(e.key, e.value))));
  S withMap(Map<Field, Object?> map) => copyWithMap(_bufferCopy()..addAll(map));
}
