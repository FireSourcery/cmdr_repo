import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'index_map.dart';

export 'index_map.dart';

/// [Structure] — zero-cost keyed view over an existing object.
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
extension type const Structure<K extends Field, V>(Object _this) implements Object {
  V operator [](K key) => key.getIn(_this);
  void operator []=(K key, V value) => key.setIn(_this, value);

  // `field` referring to the field value
  V field(K key) => key.getIn(_this);
  void setField(K key, V value) => key.setIn(_this, value);

  V? fieldOrNull(K key) => key.testBoundsOf(_this) ? key.getIn(_this) : null;

  bool trySetField(K key, V value) {
    if (!key.testBoundsOf(_this)) return false;
    key.setIn(_this, value);
    return true;
  }

  FieldEntry<K, V> fieldEntry(K key) => (key: key, value: field(key));

  // copy operations need context of keys

  /// optionally keep in keys class
  Iterable<V> fields(Iterable<K> keys) => keys.map((key) => field(key)); //valuesOf

  Iterable<FieldEntry<K, V>> fieldEntries(Iterable<K> keys) => keys.map((key) => fieldEntry(key)); //entriesOf

  Iterable<MapEntry<K, V>> map(Iterable<K> keys) => keys.map((key) => MapEntry(key, this[key]));

  /// optionally — accepts base Field type for internal/generic dispatch
  @protected
  V get(Field key) => key.getIn(_this);
  @protected
  void set(Field key, V value) => key.setIn(_this, value);
  @protected
  bool testBounds(Field key) => key.testBoundsOf(_this); //contains

  @protected
  V? getOrNull(Field key) => testBounds(key) ? get(key) : null;
  @protected
  bool setOrNot(Field key, V value) {
    if (!testBounds(key)) return false;
    set(key, value);
    return true;
  }
}

/// [StructureType]
/// TypeClass
/// Common viewer interface
/// `List<Enum>` includes serialization
/// Combine with Structure extension type, satisfies common data interface and serialization
// dont need subtype here its only for data viewing
extension type const StructureType<K extends Field, V>(List<K> fields) {
  Structure<K, V> cast(StructureBase<dynamic, K, V> struct) => struct.data; // can cast if the K,V match

  Map<K, V> createMap(Structure<K, V> struct) => {for (final key in fields) key: key.getIn(struct)};
  // keys must be Enum or have index
  FixedMap<K, V> createFixedMap(Structure<K, V> struct) => IndexMap<K, V>.of(fields, fields.map((key) => key.getIn(struct)));

  // Iterable<V> fieldsOf(Structure<K, V> struct) => fields.map((key) => struct[key]); //valuesOf
  // Iterable<FieldEntry<K, V>> fieldEntries(Structure<K, V> struct) => fields.map((key) => struct.fieldEntry(key)); //entriesOf
  // Iterable<MapEntry<K, V>> map(Iterable<K> keys) => keys.map((key) => MapEntry(key, this[key]));
}

/// [Field] — key to a value in a host struct, carrying accessor logic and type scope
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
  bool testBoundsOf(covariant Object struct) => true; //isWithin

  /// Optional default; enables `Map<K, V?>` patterns and `clear()`.
  // V? get defaultValue => null;

  // int get index; // for index map by default
}

typedef FieldEntry<K, V> = ({K key, V value});

/// User Subtype handling + [Serailizable] mixin

/// [StructureBase] — abstract base user subtype
///
/// holds data and TypeObject
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
/// optionally implement Map
abstract mixin class StructureBase<S extends StructureBase<S, K, V>, K extends Field, V> /* implements FixedMap<K, V> */ {
  const StructureBase();

  /// a method from its TypeObject
  /// The ordered list of keys — defines the schema.
  /// Typically returns `MyField.values` for an enum-based key type.
  @protected
  List<K> get keys; // Child class defines fixed keys
  /// Proxy to allow the same keys
  Structure<K, V> get data; // data passed to Keys
  // Object get data; // data passed to Keys

  // mixin 2 additional for Map interface
  // void clear();
  // V remove(covariant K key);

  V operator [](covariant K key) => key.getIn(data);
  void operator []=(covariant K key, V value) => data[key] = value;

  // V field(K key) =>  inner[key];
  // void setField(K key, V value) => inner[key] = value;

  V? fieldOrNull(K key) => data.fieldOrNull(key);
  bool trySetField(K key, V value) => data.trySetField(key, value); // trySetField

  FieldEntry<K, V> fieldEntry(K key) => (key: key, value: this[key]);

  //
  // Interface extended Structure
  Iterable<V> get fields => data.fields(keys); //valuesOf
  Iterable<FieldEntry<K, V>> get fieldEntries => data.fieldEntries(keys); //entriesOf

  // ---------------------------------------------------------------------------
  // Conversion — bridge to Map (and therefore to serialization)
  // ---------------------------------------------------------------------------
  StructureType<K, V> get _type => StructureType<K, V>(keys);

  /// Snapshot as an [IndexMap]. If `K extends Enum`, call `.toJson()` on the
  /// result to serialise via [EnumMapByName].
  Map<K, V> toMap() => _type.createMap(data);
  // IndexMap<K, V> toMap() => IndexMap<K, V>.of(keys, valuesOf(keys));

  // /// iterativee access delegate to map
  // /// Map implements .values and .entries
  // Iterable<FieldEntry<K, V>> get fieldEntries => keys.map((key) => fieldEntry(key));

  // Iterable<V> valuesOf(Iterable<K> keys) => keys.map((key) => this[key]);
  // // Iterable<FieldEntry<K, V>> entriesOf(Iterable<K> keys) => keys.map((key) => fieldEntry(key));

  // ---------------------------------------------------------------------------
  // Immutable copy helpers — return [StructMap] by default.
  // Subtypes override copyWith via their own constructor.
  // ---------------------------------------------------------------------------
  S copyWith(); // override in child class, using index map by default

  // immutable `with` copy operations, via IndexMap
  // analogous to operator []=, but returns a new instance

  // StructMap<K, V> _bufferCopy() => StructMap<K, V>._(keys, List<V>.of(valuesOf(keys), growable: false));

  // //StructureBase
  // // overwrite copyWith to cast after buffered build
  // StructMap<K, V> _withField(K key, V value) => _bufferCopy()..[key] = value;
  // StructMap<K, V> _withEntries(Iterable<MapEntry<K, V>> newEntries) => _bufferCopy()..addEntries(newEntries);
  // StructMap<K, V> _withAll(Map<K, V> map) => _bufferCopy()..addAll(map);

  /// Override for non-null fields from [overlay] applied onto a copy of this.
  // StructMap<K, V> withFields(StructureBase<dynamic, K, V?> overlay) {
  //   // return StructMap.ofMap({for (var key in keys) key: fields.field(key) ?? field(key)} as FixedMap<K, V?>);
  //   return StructMap<K, V>(this)..forEach((key, value) {
  //     if (fields[key] case V newValue) this[key] = newValue;
  //   });
  // }

  // Structure<K, V> _bufferCopy() => StructMap<K, V>._(keys, List<V>.of(valuesOf(keys), growable: false)).inner;
  // Structure<K, V> _withField(K key, V value) => _bufferCopy()..[key] = value;
  // Structure<K, V> _withEntries(Iterable<MapEntry<K, V>> newEntries) {
  //   final copy = _bufferCopy();
  //   for (final entry in newEntries) {
  //     copy[entry.key] = entry.value;
  //   }
  //   return copy;
  // }

  // Structure<K, V> _withAll(Map<K, V> map) => _bufferCopy()..addAll(map);

  // @mustBeOverridden
  // S copyWithBase([Structure<K, Object?>? fields]);

  // @override
  // S withField(K key, Object? value) => copyWithBase(_withField(key, value));
  // @override
  // S withEntries(Iterable<MapEntry<K, Object?>> newEntries) => copyWithBase(withEntries(newEntries));
  // @override
  // S withMap(Map<K, Object?> map) => copyWithBase(withMap(map));

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

// simplifiy signiture for general class types.
typedef DataStruct<S extends StructureBase<S, K, Object>, K extends Field> = StructureBase<S, K, Object>;

/// allows the base layer to create a struct buffer
/// Base map for FromMap handling if needed
/// Map handles key via Map buffers
/// implements [Structure] using parallel arrays
// default for buffer
class StructMap<K extends Field, V> extends IndexMap<K, V> with StructureBase<StructMap<K, V>, K, V> {
  StructMap._(super.keys, super.values) : super.of();
  // StructMap(StructureBase<StructMap<K, V>, K, V> struct) : super.of(struct.keys, struct.data.fields(struct.keys));

  // /// Construct from an explicit entries iterable; all keys must be present.
  // StructMap.fromEntries(List<K> keys, Iterable<MapEntry<K, V>> entries) : super.fromEntries(keys, entries);

  // /// Construct filled with a single value (useful for nullable or default-value init).
  // StructMap.filled(List<K> keys, V fill) : super.filled(keys, fill);

  @override
  Structure<K, V> get data => throw StateError('StructMap is a buffer and does not have an inner data object');

  @override
  StructureType<K, V> get _type => throw StateError('StructMap is a buffer and does not have a type');

  @override
  Map<K, V> toMap() => StructMap<K, V>._(this.keys, this.values); // return a copy to prevent external mutation
  @override
  FieldEntry<K, V> fieldEntry(K key) => (key: key, value: this[key]);
  @override
  V? fieldOrNull(K key) => this[key];
  @override
  bool trySetField(K key, V value) {
    this[key] = value; // always succeeds since it's a buffer
    return true;
  }

  @override
  StructMap<K, V> copyWith() => this;

  // @override
  // // TODO: implement fieldEntries
  // Iterable<FieldEntry<K, V>> get fieldEntries => throw UnimplementedError();

  // @override
  // // TODO: implement fields
  // Iterable<V> get fields => throw UnimplementedError();
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



// 
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

// abstract class StructFactory<S extends StructureBase<S, K, V>, K extends Field, V> {
//   const StructFactory(this.keys);

//   /// The canonical ordered list of keys — defines the schema.
//   final List<K> keys;

//   /// User-supplied function that converts a generic [Structure<K, V>] buffer into [S].
//   S constructor([Structure<K, V>? buffer]);

//   /// Create [S] by copying all fields from [source].
//   S from(Structure<K, V> source) => constructor(StructMap<K, V>(source));

//   /// Create [S] with every field initialised to [fill].
//   S filled(V fill) => constructor(StructMap<K, V>.filled(keys, fill));

//   /// Create [S] from an explicit entries iterable; all [keys] must be represented.
//   S fromEntries(Iterable<MapEntry<K, V>> entries) => constructor(StructMap<K, V>.fromEntries(keys, entries));

//   /// Create [S] from a [Map<K, V>]; all [keys] must be present.
//   S fromMap(Map<K, V> map) => constructor(StructMap<K, V>.fromEntries(keys, map.entries));

//   /// Return an unfilled mutable [StructMap] buffer with [keys] set.
//   /// Useful for incremental construction before calling [constructor].
//   StructMap<K, V> buffer(V fill) => StructMap<K, V>.filled(keys, fill);
// }
