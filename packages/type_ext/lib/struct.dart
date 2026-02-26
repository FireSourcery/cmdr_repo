import 'package:meta/meta.dart';

import 'index_map.dart';

export 'index_map.dart';

/// [Structure]
/// KeyedData, EnumData
/// Similar to a [Map]
///   fixed set of keys
///   getOrNull/setOrNot
///
/// Provides Key interface to an Object, for iterative field access, e.g. serialization
/// mixin for withX and serialization
///
/// subclass determines mutability
/// interface and implementation
///
// extend to fill class variables.
// Field may use a type parameter other than V, used to determine the value of V
abstract mixin class Structure<K extends Field, V> /* implements  FixedMap<K, V>  */ {
  const Structure();

  // Map

  // mixin for asMap()
  V operator [](covariant K key) => get(key);
  void operator []=(covariant K key, V value) => set(key, value);
  // with type constraint
  // `field` referring to the field value
  // V field(K key) => get(key);
  // void setField(K key, V value) => set(key, value);

  // mixin 2 additional for Map interface
  // void clear();
  // V remove(covariant K key);

  // Struct - implemented by Field key. keep Field<T> type withing local scope
  //alternatively
  // overwrite with key.callWithType()
  @protected
  V get(Field key) => key.getIn(this); // valueOf(Field key);
  @protected
  void set(Field key, V value) => key.setIn(this, value);
  @protected
  bool testBounds(Field key) => key.testBoundsOf(this);

  @protected
  V? getOrNull(Field key) => testBounds(key) ? get(key) : null;
  @protected // trySet
  bool setOrNot(Field key, V value) {
    if (!testBounds(key)) return false;
    set(key, value);
    return true;
  }

  V? fieldOrNull(K key) => getOrNull(key);
  bool setFieldOrNot(K key, V value) => setOrNot(key, value); // trySetField

  FieldEntry<K, V> fieldEntry(K key) => (key: key, value: this[key]);

  Iterable<V> valuesOf(Iterable<K> keys) => keys.map((key) => this[key]);
  Iterable<FieldEntry<K, V>> entriesOf(Iterable<K> keys) => keys.map((key) => fieldEntry(key));

  /// Iteration over all keys — mirrors Map.forEach without requiring MapBase
  // void forEach(void Function(K key, V value) action) {
  //   for (final key in keys) {
  //     action(key, this[key]);
  //   }
  // }

  /// with context of this.keys
  // @override
  List<K> get keys; // a method that is the meta contents, fieldsList
  // Iterable<K> get keys;
  // List<K> get fields;

  // IndexMap<K, V> asMap() => IndexMap<K, V>._(keys, valuesOf(keys));
  // Map<K, V> toMap() => IndexMap<K, V>.of(keys, valuesOf(keys));

  // default implementation for copyWith, base operation for the same keys
  // factory Structure.cast(Structure<K, V> fields) = StructMap.new;

  // Structure<K, V> copyWith() /// override in child class, using index map by default

// overwrite copyWith to cast after buffered build, or leave abstract.
  Structure<K, V> withFields(Structure<K, V?> fields) {
    // return StructMap.ofMap({for (var key in keys) key: fields.field(key) ?? field(key)} as FixedMap<K, V?>);
    return StructMap<K, V>(this)
      ..forEach((key, value) {
        if (fields[key] case V newValue) this[key] = newValue;
      });
  }

  /// Returns a copy of this structure with non-null fields from [fields] applied.
  /// Overwrite [copyWith] in [StructAsSubtype] to return the concrete subtype.
  // Structure<K, V> withFields(Structure<K, V?> fields) {
  //   final copy = StructMap<K, V>(this);
  //   for (final key in keys) {
  //     if (fields[key] case final V newValue) copy[key] = newValue;
  //   }
  //   return copy;
  // }

  // user may overwrite once a subclass constructor is defined
  // immutable `with` copy operations, via IndexMap
  // analogous to operator []=, but returns a new instance
  Structure<K, V> withField(K key, V value) => StructMap<K, V>(this)..[key] = value;
  //
  Structure<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => StructMap<K, V>(this)..addEntries(newEntries);
  // A general values map representing external input, may be a partial map
  Structure<K, V> withMap(Map<K, V> map) => StructMap<K, V>(this)..addAll(map);

  // @mustBeOverridden
  // S copyWithBase([Structure<K, Object?>? fields]);

  // @override
  // S withField(K key, Object? value) => copyWithBase(_withField(key, value));
  // @override
  // S withEntries(Iterable<MapEntry<K, Object?>> newEntries) => copyWithBase(_withEntries(newEntries));
  // @override
  // S withMap(Map<K, Object?> map) => copyWithBase(_withMap(map));

  @override
  int get hashCode => keys.fold(0, (prev, key) => prev ^ this[key].hashCode);

  /// Value equality: two structures are equal if they share the same keys reference
  /// (i.e. same type schema) and all corresponding field values are equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Structure<K, V>) return false;
    if (!identical(keys, other.keys)) return false; // keys are const lists; identity means same schema
    for (final key in keys) {
      if (this[key] != other[key]) return false;
    }
    return true;
  }

  @override
  String toString() => '{${keys.map((k) => '$k: ${this[k]}').join(', ')}}';
}

// abstract class Structure<S extends Structure<S, K>, K extends Field> extends _Structure<K, Object?> {
//   const Structure();
// }

/// [Field] - key to a value in a [StructView], with type
/// although implementation of operators may be preferable in the containing class with full context of relationships between fields
/// define accessors on the struct within key, to keep type withing local scope
/// the key maintains scope of V
///
/// K as Enum for serialization
///
/// effectively allows StructView to be abstract
abstract mixin class Field<V> {
  @protected
  V getIn(covariant Object struct); // within(covariant Object struct);
  @protected
  void setIn(covariant Object struct, V value); // setWithin(covariant Object struct, V value);

  // not yet replaceable
  // @protected
  // isBounded
  /// Returns true if this field is in-bounds for [struct].
  /// Default assumes the field is always bounded (fixed-schema structs).
  /// Override for optional/sparse fields.
  bool testBoundsOf(covariant Object struct) => true;

  // @protected
  // V? getInOrNull(covariant Object struct) {
  //   return testBoundsOf(struct) ? getIn(struct) : null;
  // }

  // @protected
  // bool setInOrNot(covariant Object struct, V value) {
  //   if (testBoundsOf(struct)) {
  //     setIn(struct, value);
  //     return true;
  //   }
  //   return false;
  // }

  V? get defaultValue => null; // allows additional handling of Map<K, V?>
}

// class StructSchema<S extends Structure<K, V>, K extends Field, V> {
//   const StructSchema(this.fields, {this.constructor});
//   final List<K> fields;
//   final S Function([List<V>?])? constructor;

//   Structure<K, V> createBase([List<V>? values]) => StructMap<K, V>._(fields, values ?? List.filled(fields.length, null as V));
// }

//
// extension type const StructSchema<S extends Structure<K, V>, K extends Field, V>(List<K> fields) {
//   // StructSchema.withC(S Function([List<V>?]) constructor) : fields = constructor().keys;
// // extension type const StructFactory<S, K extends Field, V>(List<K> fields, S Function([List<V>?])? constructor)
//   StructMap<K, V> createBase([List<V>? values]) => StructMap<K, V>._(fields, values ?? List.filled(fields.length, null as V));
//   // Map.fromEntries(fields.map((key) => MapEntry(key, values[fields ])));
//   // S create([List<V>? values]) => createBase(values).copyWith() as S; // implicitly call constructor
//   // Structure<K, V> cast(Structure<Field, Object?> struct) {}
//   // S castMap(Map<K, V> map) => castBase(_fromEntries(map.entries));
// }

// extension type const StructSubtypeSchema<S extends Structure>(S Function([List? values]) constructor) {}

/// [StructFactory] — schema + typed constructor for a struct subtype.
///
/// Decouples the key schema (a const [List<K>]) from the concrete [S] constructor,
/// enabling generic factory methods (fill, fromEntries, fromMap, copy) that return
/// the concrete subtype without requiring [S] to expose parametric constructors.
///
/// Usage:
/// ```dart
/// class Point extends Structure<PointField, double> { ... }
/// const pointFactory = StructFactory(PointField.values, Point.fromBase);
/// final p = pointFactory.filled(0.0);
/// ```
class StructFactory<S extends Structure<K, V>, K extends Field, V> {
  const StructFactory(this.keys, this.constructor);

  /// The canonical ordered list of keys — defines the schema.
  final List<K> keys;

  /// User-supplied function that converts a generic [Structure<K, V>] buffer into [S].
  final S Function(Structure<K, V>) constructor;

  /// Create [S] by copying all fields from [source].
  S from(Structure<K, V> source) => constructor(StructMap<K, V>(source));

  /// Create [S] with every field initialised to [fill].
  S filled(V fill) => constructor(StructMap<K, V>.filled(keys, fill));

  /// Create [S] from an explicit entries iterable; all [keys] must be represented.
  S fromEntries(Iterable<MapEntry<K, V>> entries) => constructor(StructMap<K, V>.fromEntries(keys, entries));

  /// Create [S] from a [Map<K, V>]; all [keys] must be present.
  S fromMap(Map<K, V> map) => constructor(StructMap<K, V>.fromEntries(keys, map.entries));

  /// Return an unfilled mutable [StructMap] buffer with [keys] set.
  /// Useful for incremental construction before calling [constructor].
  StructMap<K, V> buffer(V fill) => StructMap<K, V>.filled(keys, fill);
}

/// typedefs
typedef FieldEntry<K, V> = ({K key, V value});

/// implement Structure using parallel arrays
class StructMap<K extends Field, V> extends IndexMap<K, V> with Structure<K, V> {
  StructMap(Structure<K, V> struct) : super.of(struct.keys, struct.valuesOf(struct.keys));
  StructMap._(super.keys, super.values) : super.of();

  /// Construct from an explicit entries iterable; all keys must be present.
  StructMap.fromEntries(List<K> keys, Iterable<MapEntry<K, V>> entries) : super.fromEntries(keys, entries);

  /// Construct filled with a single value (useful for nullable or default-value init).
  StructMap.filled(List<K> keys, V fill) : super.filled(keys, fill);
}

/// default implementation of immutable copy as subtype
/// auto typing return as Subtype class.
/// copy references to a new buffer, then pass to child constructor
mixin StructAsSubtype<S extends Structure<K, V>, K extends Field, V> on Structure<K, V> {
  // Overridden the in child class
  //  calls the child class constructor
  //  return an instance of the child class type
  //  passing empty parameters always copies all values
  @override
  @mustBeOverridden
  S copyWith();

  @override
  S withField(K key, V value) => (super.withField(key, value) as StructAsSubtype<S, K, V>).copyWith();
  @override
  S withEntries(Iterable<MapEntry<K, V>> newEntries) => (super.withEntries(newEntries) as StructAsSubtype<S, K, V>).copyWith();
  @override
  S withMap(Map<K, V> map) => (super.withMap(map) as StructAsSubtype<S, K, V>).copyWith();
  @override
  S withFields(Structure<K, V?> fields) => (super.withFields(fields) as StructAsSubtype<S, K, V>).copyWith();
}
