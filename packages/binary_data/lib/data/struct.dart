import 'package:binary_data/binary_data.dart';
import 'package:meta/meta.dart';

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
  V operator [](K key) => key.getIn(this);
  void operator []=(K key, V value) => key.setIn(this, value);

  StructField<R> field<R>(Field<R> key) => (key: key, value: this[key as K] as R); // handles user side casting

  V? fieldOrNull(K key) => key.testAccess(this) ? key.getIn(this) : null;
  bool trySetField(K key, V value) {
    if (!key.testAccess(this)) return false;
    key.setIn(this, value);
    return true;
  }

  // implementatio handled by form
  Iterable<V> valuesAs(StructForm<K, V> type) => type(this).values;
  Iterable<StructField<V>> fieldsAs(StructForm<K, V> type) => type(this).fields;
  Map<K, V> toMapWith(StructForm<K, V> type) => type.mapWithData(this);
}

/// [Field] — key to a value in a host struct, carrying accessor logic and type scope
///
/// Virtualized Field / Descriptor
/// _interface_ common between Structure and Map
/// When `K extends Enum & Field`, serialization comes for free via [EnumMapByName] on `Map<Enum, V>`.
///
/// Although the containing class with full context of relationships between fields
/// By defining accessors on the key rather than the struct, the struct itself can remain a plain object (or extension type wrapper).
/// The key maintains the type scope of `V`.
///
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

  // Optional default; enables `Map<K, V?>`
  // V? get defaultValue => null;

  // int get index; // for index map by default
}

/// [StructForm]
/// Structure TypeClass
/// Common viewer interface
/// handle creation, creation here gurantees all keys are 'Struct' keys are present
/// Conversion — bridge to Map (and therefore to serialization)
///
/// `List<Enum>` includes serialization
/// Combine with Structure extension type, satisfies common data interface and serialization
/// `Structure<PersonField, Object>(personA).valuesAs(PersonField.values).toMap();`
///
extension type const StructForm<K extends Field<V>, V>(List<K> fields) {
  // keys must be Enum or have index
  // index map handling all keys present
  IndexMap<K, V> _structMap(Structure<K, V> struct) => IndexMap<K, V>.of(fields, struct.valuesAs(this));
  Map<K, V> _hashMap(Structure<K, V> struct) => {for (final key in fields) key: struct[key]};

  Map<K, V> mapWithData(Structure<K, V> struct) => _structMap(struct);

  /// `Form(PersonField.values)(personA).toMap();`
  ({StructForm<K, V> type, Structure<K, V> data}) call(Structure<K, V> struct) => (type: this, data: struct);

  // viewer
  // StructureBase<dynamic, K, V> view(Structure<K, V> struct) => StructPrototype<Never, K, V>(fields, struct);
}

// return context with both
extension TypedStruct<K extends Field<V>, V> on ({StructForm<K, V> type, Structure<K, V> data}) {
  Map<K, V> toMap() => type.mapWithData(data);
  Iterable<V> get values => type.fields.map((k) => data[k]);
  Iterable<StructField<V>> get fields => type.fields.map((k) => data.field(k));
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
  Iterable<V> get values => StructForm(keys)(data).values;
  Iterable<StructField<V>> get fields => StructForm(keys)(data).fields;

  // ---------------------------------------------------------------------------
  // Conversion — bridge to Map (and therefore to serialization)
  // ---------------------------------------------------------------------------
  /// Snapshot as an [IndexMap]. If `K extends Enum`, call `.toJson()` on the
  /// result to serialise via [EnumMapByName].
  Map<K, V> toMap() => IndexMap.of(keys, values);

  // toStringAsNamed() => '$S(${keys.map((k) => '$k: ${this[k]}').join(', ')})';
}

// typedef ClassStruct<S extends StructureBase<S, Field, Object?>> = StructureBase<S, Field, Object?>;
// typedef BinaryStruct<S extends StructureBase<S, Field<int>, int>> = StructureBase<S, Field<int>, int>;

// struct view
class StructPrototype<S extends StructureBase<S, K, V>, K extends Field<V>, V> with StructureBase<S, K, V> {
  const StructPrototype(this.keys, this.data);
  final List<K> keys;
  final Structure<K, V> data;
}

/// proxy over a map
class StructInitializer<T extends StructureBase<T, K, V>, K extends Field<V>, V> implements StructureBase<T, K, V> {
  const StructInitializer(this._init);

  final Map<K, V> _init;

  @override
  List<K> get keys => _init.keys.toList();

  @override
  Structure<K, V> get data => throw UnimplementedError();

  @override
  V operator [](covariant K key) => _init[key]!;
  @override
  void operator []=(covariant K key, V value) => _init[key] = value;

  @override
  StructField<V1> field<V1>(Field<V1> key) => (key: key, value: _init[key as K] as V1);
  @override
  V? fieldOrNull(K key) => _init[key];
  @override
  bool trySetField(K key, V value) {
    if (_init is UnmodifiableMapBase) return false;
    _init[key] = value;
    return true;
  }

  @override
  Iterable<V> get values => _init.values;
  @override
  Iterable<StructField<V>> get fields => _init.entries.map((e) => (key: e.key, value: e.value));

  @override
  Map<K, V> toMap() => _init;
}
