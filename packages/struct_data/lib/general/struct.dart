import 'package:meta/meta.dart';
import '../binary_data.dart';

/// [StructData] — zero-cost keyed view over an existing object.
///
/// Handle key implementations, mapping to data
/// Provide common `data` interface.
///
/// Provides `operator[]` access via [Field] keys without allocation.
/// The wrapped object's memory layout is unchanged; all dispatch goes
/// through [Field.getIn]/[Field.setIn].
///
/// Contraint provided by type markers `K extends Field` ensures that only valid keys can be used
///
/// ```dart
/// final view = StructData<PersonField, Object>(personInstance);
/// print(view[PersonField.name]); // delegates to PersonField.name.getIn(person)
/// ```
///
/// `K` binds type safety
/// `V` applies to some heterogeneous structs, but can be `Object` for generality
extension type const StructData<K extends Field<V>, V>(Object _data) implements Object {
  V operator [](K key) => key.getIn(this);
  void operator []=(K key, V value) => key.setIn(this, value);

  StructField<K, V> field(K key) => (key: key, value: this[key]);

  V? fieldOrNull(K key) => key.testAccess(this) ? key.getIn(this) : null;
  bool trySetField(K key, V value) {
    if (!key.testAccess(this)) return false;
    key.setIn(this, value);
    return true;
  }

  StructField<Field<R>, R> fieldAs<R>(Field<R> key) => (key: key, value: this[key as K] as R); // handles user side casting

  // implementation handled by Form
  Iterable<V> valuesAs(StructForm<K, V> type) => type(this).values;
  Iterable<StructField<K, V>> fieldsAs(StructForm<K, V> type) => type(this).fields;
  Map<K, V> toMapWith(StructForm<K, V> type) => type.mapWithData(this);
}

/// [Field] — key to a value in a host struct, carrying accessor logic and type scope
///
/// Virtualized Field / Descriptor
/// _interface_ common between StructData and Map
/// When `K extends Enum & Field`, serialization comes for free via [EnumMapByName] on `Map<Enum, V>`.
///
/// Although the containing class with full context of relationships between fields
/// By defining accessors on the key rather than the struct, the struct itself can remain a plain object (or extension type wrapper).
/// The key maintains the type scope of `V`.
///
/// Object struct as StructData or StructBase
abstract interface class Field<V> {
  /// Read this field's value from [struct].
  @protected
  V getIn(covariant Object struct);

  /// Write [value] into this field of [struct].
  @protected
  void setIn(covariant Object struct, V value);

  /// Whether this field is present/valid for [struct].
  /// Defaults to `true` (fixed-schema). Override for optional/sparse fields.
  bool testAccess(covariant Object struct) => true;
}

// extension FieldExtension<K extends Field<V>, V> on K {
//   V of(StructData<K, V> struct) => getIn(struct);
// }

/// [StructForm]
/// StructData TypeClass
/// Common viewer interface
/// handle creation, creation here gurantees all keys are 'Struct' keys are present
/// Conversion — bridge to Map (and therefore to serialization)
///
/// `List<Enum>` includes serialization
/// In combination with [StructData], provides a common data interface and serialization
/// `StructData<PersonField, Object>(personA).valuesAs(PersonField.values).toMap();`
///
extension type const StructForm<K extends Field<V>, V>(List<K> fields) implements List<K> {
  // keys must be Enum or have index
  // index map handling all keys present
  IndexMap<K, V> _structMap(StructData<K, V> struct) => IndexMap<K, V>.of(fields, fields.map((k) => struct[k]));
  // Map<K, V> _hashMap(StructData<K, V> struct) => {for (final key in fields) key: struct[key]};

  Map<K, V> mapWithData(StructData<K, V> struct) => _structMap(struct);

  ({StructForm<K, V> form, StructData<K, V> data}) call(StructData<K, V> struct) => (form: this, data: struct);
}

/// return context with both keys and data
/// `StructForm(PersonField.values)(personA).toMap();`
/// iterative operations
extension TypedStructReference<K extends Field<V>, V> on ({StructForm<K, V> form, StructData<K, V> data}) {
  Map<K, V> toMap() => form.mapWithData(data);
  Iterable<V> get values => form.fields.map((k) => data[k]);

  Iterable<StructField<K, V>> get fields => form.fields.map((k) => data.field(k));
  set fields(Iterable<StructField<K, V>> newValues) {
    for (final element in newValues) {
      data[element.key] = element.value;
    }
  }
}

// FieldEntry, FieldValue, StructEntry
typedef StructField<K extends Field<V>, V> = ({K key, V value});
typedef StructFields<K extends Field<V>, V> = Iterable<StructField<K, V>>;

// typedef FieldEntry<K extends Field<V>, V> = MapEntry<K, V>;

/// [StructBase] — abstract base user subtype
///
/// TypedStruct holds data and List keys TypeObject
/// provide toMap()
/// Handle User Subtype + [Serializable] mixin
/// mixin for convenience, applies to further abstract classes
///
/// Unlike [StructData] (which wraps an _external_ object), subclasses of
/// [StructBase] hold data directly in their own fields. [Field.getIn] /
/// [Field.setIn] receive `this` as the host object.
///
/// [StructBase] provides opt-in value equality via [keys]. When `K` also
/// extends [Enum], the existing `EnumMapByName` extension on `Map<Enum, V>`
/// gives serialization for free — just call `toMap().toJson()`.
///
/// `StructureBase` cannot implement `StructData` (an extension type). Instead,
/// [data] returns `StructData<K, V>(this)` — a zero-cost wrapper around `this`
/// — so that all keyed access delegates through the same [Field]-based dispatch.
/// This also allows `inner` to be passed to APIs that accept `StructData<K, V>`.
///
mixin StructBase<S extends StructBase<S, K, V>, K extends Field<V>, V> {
  /// a method from its TypeObject
  /// The ordered list of keys — defines the schema.
  /// Typically returns `MyField.values` for an enum-based key type.
  @protected
  List<K> get keys; // Child class defines fixed keys
  // List<K> get T;
  // StructForm<K, V> get schema => StructForm<K, V>(keys);

  /// Proxy to allow the same keys
  /// [Object] as [StructData<K, V>] data passed to Keys
  StructData<K, V> get data;

  V operator [](covariant K key) => data[key];
  void operator []=(covariant K key, V value) => data[key] = value;
  V? fieldOrNull(K key) => data.fieldOrNull(key);
  bool trySetField(K key, V value) => data.trySetField(key, value);
  StructField<K, V> field(K key) => data.field(key);
  StructField<Field<R>, R> fieldAs<R>(Field<R> key) => data.fieldAs<R>(key);

  // Iterable view requiring Fields list
  Iterable<V> get values => StructForm(keys)(data).values;
  Iterable<StructField<K, V>> get fields => StructForm(keys)(data).fields;

  // Conversion — bridge to Map (and therefore to serialization)
  /// Snapshot as an [IndexMap]. If `K extends Enum`, call `.toJson()` on the
  /// result to serialise via [EnumMapByName].
  Map<K, V> toMap() => IndexMap.of(keys, values);
}

// mixin StructBase< K, V>, K extends Field<V>, V> {
// mixin ImmutableStructBase<S extends StructBase<S, K, V>, K extends Field<V>, V> {

// Utility
/// proxy over a map
class StructInitializer<T extends StructBase<T, K, V>, K extends Field<V>, V> implements StructBase<T, K, V> {
  const StructInitializer(this._init);

  final Map<K, V> _init;

  @override
  List<K> get keys => _init.keys.toList();

  @override
  StructData<K, V> get data => throw UnimplementedError();

  @override
  V operator [](covariant K key) => _init[key]!;
  @override
  void operator []=(covariant K key, V value) => _init[key] = value;

  @override
  StructField<K, V> field(K key) => (key: key, value: _init[key]!);
  @override
  V? fieldOrNull(K key) => _init[key];
  @override
  bool trySetField(K key, V value) {
    _init[key] = value;
    return true;
  }

  @override
  Iterable<V> get values => _init.values;
  @override
  Iterable<StructField<K, V>> get fields => _init.entries.map((e) => (key: e.key, value: e.value));

  @override
  Map<K, V> toMap() => _init;

  @override
  StructField<Field<R>, R> fieldAs<R>(Field<R> key) => (key: key, value: _init[key as K] as R);
}

// struct view
// class StructPrototype<S extends StructureBase<S, K, V>, K extends Field<V>, V> with StructureBase<S, K, V> {
//   const StructPrototype(this.keys, this.data);
//   final List<K> keys;
//   final StructData<K, V> data;
// }
