import 'dart:collection';

import 'package:meta/meta.dart';

import 'enum_map.dart';
import 'index_map.dart';

/// Similar to a [Map]
///   fixed set of keys
///   getOrNull/setOrNot
///   immutable `with` copy operations, via IndexMap
///
/// interface and implementation
///
// extension type cannot include abstract methods, or implement interfaces
// cannot define copyWith without context of Keys
extension type StructView<K extends Field, V>(Object _this) {
  V operator [](K key) => get(key);
  void operator []=(K key, V value) => set(key, value);

  @protected
  V get(Field key) => key.getIn(_this); // valueOf(Field key);
  @protected
  void set(Field key, V value) => key.setIn(_this, value);

  @protected
  bool testBounds(Field key) => key.testBounds(_this);

  @protected
  V? getOrNull(Field key) => testBounds(key) ? get(key) : null;
  @protected
  bool setOrNot(Field key, V value) {
    if (testBounds(key)) {
      set(key, value);
      return true;
    }
    return false;
  }

  // `field` referring to the field value
  V field(K key) => get(key);
  void setField(K key, V value) => set(key, value);
  V? fieldOrNull(K key) => getOrNull(key);
  bool setFieldOrNot(K key, V value) => setOrNot(key, value);

  FieldEntry<K, V> fieldEntry(K key) => (key: key, value: field(key));

  // @protected
  // StructView<T, V> newWith(  Field key, V value);

  // analogous to operator []=, but returns a new instance
  // StructView<K, V> withField(K key, V value) => IndexMapStruct<K, V>.cast(this)..[key] = value;
}

extension type IndexMapStruct<K extends Field, V>(TypedMap<K, V> _this) implements StructView<K, V> {
  // IndexMapStruct.cast(StructView<K, V> struct) : _this = IndexMap.of(base, values);
  // IndexMapStruct.of(List<K> keys, Iterable<V> values) : _this = IndexMap.of(keys, values);

  V operator [](K key) => _this[key];
  void operator []=(K key, V value) => set(key, value);

  // analogous to operator []=, but returns a new instance
  StructView<K, V> withField(K key, V value) => (ProxyIndexMap<K, V>(_this)..[key] = value) as StructView<K, V>;
  //
  StructView<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => (ProxyIndexMap<K, V>(_this)..addEntries(newEntries)) as StructView<K, V>;
  // A general values map representing external input, may be a partial map
  StructView<K, V> withAll(Map<K, V> map) => (ProxyIndexMap<K, V>(_this)..addAll(map)) as StructView<K, V>;
}

// abstract mixin class StructView<K extends Field<V>, V> {}

/// [Field] - key to a value in a [StructView], with type
/// define accessors on the struct within key, to keep type withing local scope
/// although implementation of operators may be preferable in the containing class
/// with full context of relationships between fields
/// the key maintains scope of V

/// may implement on enum
///
/// effectively allows StructView to be abstract
abstract mixin class Field<V> {
  int get index;

  @protected
  V getIn(covariant Object struct); // valueOf(covariant Object struct);
  @protected
  void setIn(covariant Object struct, V value);

  // not yet replaceable
  // @protected
  bool testBounds(covariant Object struct);

  @protected
  V? getInOrNull(covariant Object struct) {
    return testBounds(struct) ? getIn(struct) : null;
  }

  @protected
  bool setInOrNot(covariant Object struct, V value) {
    if (testBounds(struct)) {
      setIn(struct, value);
      return true;
    }
    return false;
  }

  V? get defaultValue => null; // allows additional handling of Map<K, V?>
}

typedef FieldEntry<K, V> = ({K key, V value});

abstract interface class EnumField<V> implements Enum, Field<V> {}

/// [Construct]
// handler with class variables,
// struct view with Map and handler
//
// potentially implement the map interface directly
//  - Map interface
//    - Enum keys auto implement EnumMap and
//  - Factory
//  - StructView interface
//  - withX copy methods
// class Construct<T extends StructView<K, V>, K extends Field<V>, V> with MapBase<K, V>, TypedMap<K, V> {
class Construct<K extends Field<V>, V> with MapBase<K, V>, TypedMap<K, V> {
  Construct({
    required this.struct,
    required this.keys,
    // required this.lengthMax,
  });

  // factory Construct.fromJson(List<K> keys, Map<String, Object?> json) {
  //   // if (keys is List<EnumField<V>>) {
  //   //   return Construct<K, V>(
  //   //     keys: keys,
  //   //     struct: IndexMapStruct(EnumMap<K, V>.fromJson(keys, json)),
  //   //   );
  //   // }
  //   // throw UnsupportedError('Only EnumField is supported');
  // }

  // fromEntries

  // final T Function(StructView) caster;
  // final T Function( ) constructor;
  final List<K> keys;
  // final int lengthMax;
  final StructView<K, V> struct; // or object

  Iterable<FieldEntry<K, V>> get fieldEntries => keys.map((e) => (key: e, value: this[e]));

  Construct<K, V> withField(K key, V value) {
    return Construct<K, V>(
      struct: IndexMapStruct(ProxyIndexMap<K, V>(this)..[key] = value),
      keys: keys,
    );
  }

  // StructView<T, V> withFields(Iterable<Fields> fields);
  // StructView<T, V> withAll(StructView<K, V> struct);
  // StructView<T, V> withMap(StructView<K, V> struct);
  // Iterable<K> get keys;
  // Iterable<FieldEntry<K, V>> get fields => keys.map((e) => (key: e, value: this[e]));

  // StructView<K, V> copyWith();
  // Map<K, V> toMap(List<K> keys) => IndexMap.of(keys, keys.map((key) => this[key]));
  // StructView<K, V> Function(Map<K, V>) get caster;

  // StructView<K, V> withField(K key, V value);
  // StructView<K, V> withFields(Iterable<(T, V)> fields);

  // StructView<K, V> withField(K key, V value) => caster(asMap()..[key] = value);
  // StructView<K, V> withEntries(Iterable<MapEntry<K, V>> entries);
  // StructView<K, V> withAll(Map<T, V> map);

  // Construct<StructView<K, V>, K, V> withKeys(List<K> keys) => Construct<StructView<K, V>, K, V>(struct: this, keys: keys);

  Map<K, V> toMap() {
    assert(keys.first.index == keys.first.index); // ensure if index does not throw
    return IndexMap.of(keys, keys.map((key) => key.getIn(struct._this)));
  }

  @override
  void operator []=(K key, V value) => struct[key] = value;
  @override
  V operator [](K key) => struct[key];

  @override
  void clear() {
    throw UnimplementedError();
  }

  @override
  V remove(K key) {
    throw UnimplementedError();
  }
}

mixin ConstructAsSubtype<S extends Construct<K, V>, K extends Field<V>, V> on Construct<K, V> {
  // Overridden the in child class
  //  calls the child class constructor
  //  return an instance of the child class type
  //  passing empty parameters always copies all values
  @override
  @mustBeOverridden
  S copyWith();

  @override
  S withField(K key, V value) => (super.withField(key, value) as ConstructAsSubtype<S, K, V>).copyWith();
  // @override
  // S withEntries(Iterable<MapEntry<K, V>> entries) => (super.withEntries(entries)).copyWith();
  // @override
  // S withAll(Map<K, V> map) => (super.withAll(map)).copyWith();
}
