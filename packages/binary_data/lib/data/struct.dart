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
/// `K` binds
/// keep V for some heterogenous cases
extension type const Structure<K extends Field<V>, V>(Object _data) implements Object {
  V operator [](K key) => key.getIn(_data);
  void operator []=(K key, V value) => key.setIn(_data, value);

  // StructField<V> field(K key) => (key: key, value: this[key]);
  StructField<V1> field<V1>(Field<V1> key) => (key: key, value: key.getIn(_data));

  V1 unmap<V1>(Field<V1> key) => key.getIn(_data); // handles user side casting

  V? fieldOrNull(K key) => key.testAccess(_data) ? key.getIn(_data) : null;
  bool trySetField(K key, V value) {
    if (!key.testAccess(_data)) return false;
    key.setIn(_data, value);
    return true;
  }

  Iterable<V> valuesAs(List<K> keys) => keys.map((k) => this[k]);
  Iterable<StructField<V>> fieldsAs(List<K> keys) => keys.map((k) => field(k));
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

  // Object copyWith(covariant Object struct, V value); //pass per key constructor

  /// Optional default; enables `Map<K, V?>` patterns and `clear()`.
  // V? get defaultValue => null;

  // int get index; // for index map by default
}

extension FieldMethods<V> on Field<V> {
  // FieldEntry<Field<V>, V> call(Structure<Field<V>, V> struct) => (key: this, value: getIn(struct));
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
extension type const StructForm<K extends Field<V>, V>(List<K> fields) {
  // Map<K, V> _createMap(Structure<K, V> struct) => {for (final key in fields) key: struct[key]};

  // keys must be Enum or have index
  // index map handling all keys present
  IndexMap<K, V> _structMap(Structure<K, V> struct) => IndexMap<K, V>.of(fields, struct.valuesAs(fields));

  Map<K, V> mapWithData(Structure<K, V> struct) => _structMap(struct);

  // handle non map related interface including completeness
  // Structure<K, V?> _validate(Structure<K, Object?> struct) {
  //   if (V == Object && null is V) return struct as Structure<K, V?>; // skip validation if nullable
  //   return
  // }

  /// `Form(PersonField.values)(personA).toMap();`
  // Iterable<StructField<V>> call(Structure<K, V> struct) => fields.map((key) => (key: key, value: struct[key]));

  // viewer
  // StructureBase<dynamic, K, V> call(Structure<K, V> struct) => StructPrototype<Never, K, V>(fields, struct);

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

typedef FieldEntry<K extends Field<V>, V> = ({K key, V value});
typedef StructField<V> = ({Field<V> key, V value});

/// [StructureBase] — abstract base user subtype
///
/// holds data and List keys TypeObject
/// provide toMap()
/// Handle User Subtype + [Serailizable] mixin
/// mixin for convience, applies to further abstract classes, until mixins can be combined
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
///
//  optionally make this structure Map implement Map let structMap handle enforcing all key are present. or merge with fixed map
//
mixin StructureBase<S extends StructureBase<S, K, V>, K extends Field<V>, V> {
  /// a method from its TypeObject
  /// The ordered list of keys — defines the schema.
  /// Typically returns `MyField.values` for an enum-based key type.
  @protected
  List<K> get keys; // Child class defines fixed keys

  /// Proxy to allow the same keys
  /// [Object] as [Structure<K, V>] data passed to Keys
  Structure<K, V> get data;

  V operator [](covariant K key) => data[key];
  void operator []=(covariant K key, V value) => data[key] = value;

  V? fieldOrNull(K key) => data.fieldOrNull(key);
  bool trySetField(K key, V value) => data.trySetField(key, value);

  StructField<V1> field<V1>(Field<V1> key) => data.field(key);

  // Interface extended Structure
  Iterable<V> get _values => keys.map((k) => this[k]);
  Iterable<StructField<V>> get fields => keys.map((k) => (key: k, value: this[k]));

  // ---------------------------------------------------------------------------
  // Conversion — bridge to Map (and therefore to serialization)
  // ---------------------------------------------------------------------------
  StructForm<K, V> get _type => StructForm<K, V>(keys);

  /// Snapshot as an [IndexMap]. If `K extends Enum`, call `.toJson()` on the
  /// result to serialise via [EnumMapByName].
  Map<K, V> toMap() => IndexMap.of(keys, _values);
  // Map<K, V> withFieldAsMap(K key, V value) => toMap()..[key] = value;
  // Map<K, V> withFieldsAsMap(Iterable<FieldEntry<K, V>> newEntries) => toMap()..addEntries(newEntries.map((e) => MapEntry(e.key, e.value)));
  // Map<K, V> withMapAsMap(Map<K, V> map) => toMap()..addAll(map);

  /// default implementation via Struct Map
  // Structure<K, V> toBase() => StructBuffer<K, V>._(keys, _values).data;

  // ---------------------------------------------------------------------------
  // Subtypes override copyWith via their own constructor.
  // ---------------------------------------------------------------------------
  // immutable `with` copy operations, via IndexMap
  // analogous to operator []=, but returns a new instance

  // toStringAsNamed() => '$S(${keys.map((k) => '$k: ${this[k]}').join(', ')})';
}

// typedef ClassStruct<S extends StructureBase<S, Field, Object?>> = StructureBase<S, Field, Object?>;
// typedef BinaryStruct<S extends StructureBase<S, Field<int>, int>> = StructureBase<S, Field<int>, int>;

// struct view
class StructPrototype<S extends StructureBase<S, K, V>, K extends Field<V>, V> with StructureBase<S, K, V> {
  const StructPrototype(this.keys, this.data);
  final List<K> keys;
  final Structure<K, V> data;

  // @override
  // S copyWithData(covariant Structure<K, V?> data);
}

 

// concrete base
/// implements [Structure] using parallel arrays
/// [List<K>]
// class StructBuffer<K extends Field<V>, V> extends IndexMap<K, V> implements StructureBase<StructBuffer<K, V>, K, V> {
//   StructBuffer._(super.keys, super.values) : super.of();

//   /// do not remove keys, only reset values to default or null
//   // @override
//   // void clear();
//   // @override
//   // V remove(K key) {
//   //   if (key.defaultValue != null) this[key] = key.defaultValue as V;
//   //   return this[key];
//   // }

//   @override
//   Structure<K, V> get data => throw UnimplementedError(); // routes accesssors through map inerface

//   @override
//   Map<K, V> toMap() => StructBuffer<K, V>._(keys, values);

//   @override
//   StructBuffer<K, V> copyWithData(Structure<K, V> data) => StructBuffer<K, V>._(keys, values);

//   @override
//   StructForm<K, V> get _type => throw UnimplementedError();

//   @override
//   Iterable<V> get _values => throw UnimplementedError();

//   @override
//   V? fieldOrNull(K key) => throw UnimplementedError();

//   @override
//   Iterable<StructField<V>> get fields => throw UnimplementedError();

//   @override
//   bool trySetField(K key, V value) => throw UnimplementedError();

//   // @override
//   // StructBuffer<K, V> copyWith() => StructBuffer<K, V>._(keys, values);
// }

// proxy over a map
// class StructInitializer<T extends StructureBase<T, K, V>, K extends Field, V> with StructureBase<T, K, V> {
//   const StructInitializer(this._init);

//   final Map<K, V> _init;

//   @override
//   Structure<K, V> get inner 
  
//   @override 
//   List<K> get keys => _init.keys.toList();
// } 
 
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

