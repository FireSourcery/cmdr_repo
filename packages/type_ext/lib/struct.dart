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
// abstract mixin class Structure<S extends Structure, K extends Field>
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

  // user may overwrite once a subclass constructor is defined
  // immutable `with` copy operations, via IndexMap
  // analogous to operator []=, but returns a new instance
  Structure<K, V> withField(K key, V value) => StructMap<K, V>(this)..[key] = value;
  //
  Structure<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => StructMap<K, V>(this)..addEntries(newEntries);
  // A general values map representing external input, may be a partial map
  Structure<K, V> withMap(Map<K, V> map) => StructMap<K, V>(this)..addAll(map);

  // @override
  // int get hashCode => keys.fold(0, (prev, key) => prev ^ this[key].hashCode);

  // @override
  // bool operator ==(Object other) {
  //   if (identical(this, other)) return true;
  //   if (other is! Structure<K, V>) return false;
  //   if (keys != other.keys) return false; // keys are const, so compare with ==
  //   for (final key in keys) {
  //     if (this[key] != other[key]) return false;
  //   }
  //   return true;
  // }
}

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
  bool testBoundsOf(covariant Object struct);

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

/// typedefs
typedef FieldEntry<K, V> = ({K key, V value});

/// implement Structure using parallel arrays
class StructMap<K extends Field, V> extends IndexMap<K, V> with Structure<K, V> {
  StructMap(Structure<K, V> struct) : super.of(struct.keys, struct.valuesOf(struct.keys));
  StructMap._(super.keys, super.values) : super.of();
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
}
