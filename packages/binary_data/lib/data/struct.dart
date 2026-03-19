import 'dart:typed_data';

import 'package:binary_data/binary_data.dart';
import 'package:meta/meta.dart';

import 'index_map.dart';

export 'index_map.dart';

/// [Structure] — zero-cost keyed view over an existing object.
///
/// `DataObject`, type bound keys
/// Handle key implementations mapping to data
/// Provide common `data` interface.
///
/// Provides `operator[]` access via [Field] keys without allocation.
/// The wrapped object's memory layout is unchanged; all dispatch goes
/// through [Field.getIn]/[Field.setIn].
///
/// Contraint provided by type markers `K extends Field` ensures that only valid keys can be used
///
/// ```dart
/// final view = Structure<PersonField, Object>(personInstance);
/// print(view[PersonField.name]); // delegates to PersonField.name.getIn(person)
/// ```
/// keep V for some heterogenous cases
/// Field `V` may use a type parameter other than Structure's `V`
extension type const Structure<K extends Field, V>(Object _data) implements Object {
  const factory Structure.cast(Map<K, V> map) = CoStructure<K, V>;

  V operator [](K key) => key.getIn(_data);
  void operator []=(K key, V value) => key.setIn(_data, value);

  // alternatively, and use [] for diirect access
  // FieldEntry<K, V> field(K key) => (key: key, value: this[key]);

  // `field` referring to the field value
  // V field(K key) => key.getIn(_data);
  // void setField(K key, V value) => key.setIn(_data, value);

  V? fieldOrNull(K key) => key.testAccess(_data) ? key.getIn(_data) : null;
  bool trySetField(K key, V value) {
    if (!key.testAccess(_data)) return false;
    key.setIn(_data, value);
    return true;
  }

  FieldEntry<K, V> fieldEntry(K key) => (key: key, value: this[key]);
  // iterative operations need context of keys
  Iterable<V> fields(Iterable<K> keys) => keys.map((key) => this[key]);
  Iterable<FieldEntry<K, V>> fieldEntries(Iterable<K> keys) => keys.map((key) => fieldEntry(key));

  // accepts base Field type for internal/generic dispatch, wrapper override contraints
  // only Field<V> keeps type parameter
  // Object operator [](Field key) => key.getIn(_data);
  // void operator []=(Field key, Object value) => key.setIn(_data, value);
  // FieldEntry field(Field key) => (key: key, value: this[key]);
  // FieldEntry<K, V> field(K key) => (key: key, value: this[key]);
}

/// [Field] — key to a value in a host struct, carrying accessor logic and type scope
/// Virtualized Field / Descriptor
/// _interface_ common between Structure and Map
///
/// Although the containing class with full context of relationships between fields
/// By defining accessors on the key rather than the struct, the struct itself can remain a plain object (or extension type wrapper).
/// The key maintains the type scope of `V`.
///
/// When `K extends Enum` & `K implements Field`, serialization comes for free via [EnumMapByName] on `Map<Enum, V>`.
abstract interface class Field<V> {
  /// Read this field's value from [struct].
  @protected
  V getIn(covariant Object struct); // getWithin

  /// Write [value] into this field of [struct].
  @protected
  void setIn(covariant Object struct, V value); //setWithin

  /// Whether this field is present/valid for [struct].
  /// Defaults to `true` (fixed-schema). Override for optional/sparse fields.
  bool testAccess(covariant Object struct) => true; //isWithin

  /// Optional default; enables `Map<K, V?>` patterns and `clear()`.
  // V? get defaultValue => null;

  // int get index; // for index map by default

  // FieldEntry<Field<V>, V> call(covariant Object struct) => (key: this, value: getIn(struct));
}

/// [StructForm]
/// Structure TypeClass
/// Common viewer interface
/// handle creation, creation here gurantees all keys are 'Struct' keys are present
/// Conversion — bridge to Map (and therefore to serialization)
///
/// `List<Enum>` includes serialization
/// Combine with Structure extension type, satisfies common data interface and serialization
/// `Structure<PersonField, Object>(personA).fieldEntries(PersonField.values).toMap();`
///
/// Form(PersonField.values).cast()
// dont need subtype here its only for data viewing
extension type const StructForm<K extends Field, V>(List<K> fields) {
  Map<K, V> _createMap(Structure<K, V> struct) => {for (final key in fields) key: struct[key]};
  // keys must be Enum or have index
  // FixedMap<K, V> _createFixedMap(Structure<K, V> struct) => IndexMap<K, V>.of(fields, struct.fields(fields));
  StructBuffer<K, V> _createFixedMap(Structure<K, V> struct) => StructBuffer<K, V>._(fields, struct.fields(fields));

  Map<K, V> map(Structure<K, V> struct) => _createMap(struct);
  Structure<K, V> mapInv(Map<K, V> map) => CoStructure(IndexMap<K, V>.fromMap(fields, map));

  // Structure<K, V> mapInv(Map<K, V> map) => CoStructure(map); //includ validation

  // // handle non map related interface including completeness

  // /// `Form(PersonField.values)(personA).toMap();`
  // Iterable<FieldEntry> call(Structure<K, V> struct) => struct.fieldEntries(fields);

  // Structure<K, V> cast(Structure struct) => Structure<K, V>(struct); //   cast if the K,V match

  // // Structure<K, V?> create()
  // // operators with creation
  // Structure<K, V> createWith(Structure<K, V> struct, K key, V value) => CoStructure(IndexMap<K, V>.of(fields, struct.fields(fields))..[key] = value);

  // index map handles checking keys passed.
  //  inherit by serializable keys
  // CoStructure<K, V>? validate(Map<K, V> struct)
  // {
  //     fields.indexed.every((e) => e.$1 == e.$2.index)
  //     assert(_valuesBuffer.length == fields.length, 'Values buffer must match keys length');
  //     CoStructure.of(fields, fields.map((key) => struct[key] as V));
  // }
}

typedef FieldEntry<K, V> = ({K key, V value});

// CoStructure
/// represnted by Map, implements Structure -> consistent by constraint of K
// effectively implements the Structure as a interface
extension type const CoStructure<K extends Field, V>(Map<K, V> _map) implements Structure<K, V>, Map<K, V> {
  // factory CoStructure._valid(Map<K, V> map)
  CoStructure.of(List<K> keys, Iterable<V> values) : _map = IndexMap.of(keys, values);

  V operator [](K key) => _map[key] as V;
  void operator []=(K key, V value) => _map[key] = value;

  V? fieldOrNull(K key) => _map[key];
  bool trySetField(K key, V value) {
    _map[key] = value;
    return true;
  }

  Iterable<FieldEntry> get asFields => _map.entries.map((e) => (key: e.key, value: e.value));
}

/// Form(PersonField.values)(personA).toMap();
// extension StructFields on Iterable<FieldEntry> {
//   static Iterable<FieldEntry> fromMap<K, V>(Map<K, V> map) => map.entries.map((e) => (key: e.key, value: e.value));
//   Map<K, V> toMap<K, V>() => {for (final entry in this) entry.key: entry.value};
// alternatively as interface for use methods
// }

/// [StructureBase] — abstract base user subtype
///
/// mixin for convience, applies to further abstract classes, until mixins can be combined
/// holds data and TypeObject
/// provide toMap()
/// Handle User Subtype + [Serailizable] mixin
///
/// Unlike [Structure] (which wraps an _external_ object), subclasses of
/// [StructureBase] hold data directly in their own fields. [Field.getIn] /
/// [Field.setIn] receive `this` as the host object.
///
/// [StructureBase] provides opt-in value equality via [keys]. When `K` also
/// extends [Enum], the existing `EnumMapByName` extension on `Map<Enum, V>`
/// gives serialization for free — just call `toMap().toJson()`.
///
/// `StructureBase` cannot implement `Structure` (an extension type). Instead,
/// [data] returns `Structure<K, V>(this)` — a zero-cost wrapper around `this`
/// — so that all keyed access delegates through the same [Field]-based dispatch.
/// This also allows `inner` to be passed to APIs that accept `Structure<K, V>`.
///
///   make this structure Map
//  optionally implement Map
// let structMap handle enforcing all key are present. or merge with fixed map
//
mixin StructureBase<S extends StructureBase<S, K, V>, K extends Field, V> /* implements Map<K, V> */ {
  // static Structure<K, V> dataInitailizer<K extends Field, V>(Map<K, V> map) => CoStructure(map);

  /// a method from its TypeObject
  /// The ordered list of keys — defines the schema.
  /// Typically returns `MyField.values` for an enum-based key type.
  @protected
  List<K> get keys; // Child class defines fixed keys
  /// Proxy to allow the same keys
  /// [Object] as [Structure<K, V>] data passed to Keys
  Structure<K, V> get data;

  // mixin 2 additional for Map interface
  // void clear();
  // V remove(covariant K key);
  // @override
  // void clear() {}

  // @override
  // V  remove(K key) {
  //   return null;
  // }

  V operator [](covariant K key) => data[key];
  void operator []=(covariant K key, V value) => data[key] = value;

  V? fieldOrNull(K key) => data.fieldOrNull(key);
  bool trySetField(K key, V value) => data.trySetField(key, value);

  FieldEntry<K, V> fieldEntry(K key) => (key: key, value: this[key]);

  //
  // Interface extended Structure
  // Iterable<V> get values => data.fields(keys);
  Iterable<V> get fields => data.fields(keys);
  Iterable<FieldEntry<K, V>> get fieldEntries => data.fieldEntries(keys);

  // ---------------------------------------------------------------------------
  // Conversion — bridge to Map (and therefore to serialization)
  // ---------------------------------------------------------------------------
  StructForm<K, V> get _type => StructForm<K, V>(keys);

  /// Snapshot as an [IndexMap]. If `K extends Enum`, call `.toJson()` on the
  /// result to serialise via [EnumMapByName].
  Map<K, V> toMap() => _type.map(data);

  // ---------------------------------------------------------------------------
  // Immutable copy helpers — return [StructMap] by default.
  // Subtypes override copyWith via their own constructor.
  // ---------------------------------------------------------------------------
  // immutable `with` copy operations, via IndexMap
  // analogous to operator []=, but returns a new instance

  /// Override in child class to return a subtype.
  /// wraps the contructor. alternative to user registry
  S copyWithData(covariant Structure<K, V?> data);

  S copyWithMap(Map<K, V> map) => copyWithData(_type.mapInv(map));
  // S copyWithData(covariant Structure<K, V> data) => this as S;   // may satisfies typedef use
  //S copyWithFields(Iterable<FieldEntry<K, V>?> data);

  /// default implementation via Struct Map
  //_type.createWith(this.data, e.key, e.value);
  StructBuffer<K, V> _bufferCopy() => StructBuffer<K, V>._(keys, fields);

  StructureBase<dynamic, K, V> _withField(K key, V value) => _bufferCopy()..[key] = value;
  StructureBase<dynamic, K, V> _withFields(Iterable<FieldEntry<K, V>> newEntries) => _bufferCopy()..addEntries(newEntries.map((e) => MapEntry(e.key, e.value)));
  StructureBase<dynamic, K, V> _withMap(Map<K, V> map) => _bufferCopy()..addAll(map);

  //optionall override each in the  child class, using index map by default
  S withField(K key, V value) => copyWithData(_withField(key, value).data);
  S withFields(Iterable<FieldEntry<K, V>> newEntries) => copyWithData(_withFields(newEntries).data);
  S withMap(Map<K, V> map) => copyWithData(_withMap(map).data);

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
    if (other is! StructureBase<S, K, V>) return false;
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

// enforce data passing
// let subtype bound Field, Object?
abstract class DataStructure<S extends DataStructure<S>> with StructureBase<S, Field, Object?> {
  const DataStructure(this._data);
  final Structure<Field, Object?> _data;
  Structure<Field, Object?> get data => _data;
}

// concrete base
/// implements [Structure] using parallel arrays
/// [List<K>]
class StructBuffer<K extends Field, V> extends IndexMap<K, V> with StructureBase<StructBuffer<K, V>, K, V> {
  StructBuffer._(super.keys, super.values) : super.of();

  /// do not remove keys, only reset values to default or null
  // @override
  // void clear();
  // @override
  // V remove(K key) {
  //   if (key.defaultValue != null) this[key] = key.defaultValue as V;
  //   return this[key];
  // }

  @override
  Structure<K, V> get data => Structure.cast(this); // routes accesssors through map inerface

  @override
  Map<K, V> toMap() => StructBuffer<K, V>._(keys, values);

  @override
  StructBuffer<K, V> copyWithData(Structure<K, V> data) => StructBuffer<K, V>._(keys, values);
  // @override
  // StructBuffer<K, V> copyWith() => StructBuffer<K, V>._(keys, values);
}

// proxy over a map
// class StructInitializer<T extends StructureBase<T, K, V>, K extends Field, V> with StructureBase<T, K, V> {
//   const StructInitializer(this._init);

//   final Map<K, V> _init;

//   @override
//   Structure<K, V> get inner 
  
//   @override 
//   List<K> get keys => _init.keys.toList();
// } 
///
/// [StructFactory] — schema + typed constructor for a struct subtype.
///
/// Decouples the key schema (a const [List<K>]) from the concrete [S] constructor,
/// enabling generic factory methods (fill, fromEntries, fromMap, copy) that return
/// the concrete subtype without requiring [S] to expose parametric constructors.
// class StructFactory<S extends Structure<K, V>, K extends Field, V> {
//   const StructFactory(this.fields, {this.constructor});
//   final List<K> fields;
//   final S Function([List<V>?])? constructor;

//   Structure<K, V> createBase([List<V>? values]) => StructMap<K, V>._(fields, values ?? List.filled(fields.length, null as V));
// }

