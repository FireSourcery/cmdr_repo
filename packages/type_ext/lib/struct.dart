import 'package:meta/meta.dart';

import 'index_map.dart';

export 'index_map.dart';

/// typedefs
typedef FieldEntry<K, V> = ({K key, V value});

/// General mixin for keyed data structures
/// K extends Enum for serialization
/// V as Object or Object?
typedef DataStruct<K extends Field, V extends Object?> = Structure<K, V>;

/// [Structure]
/// Similar to a [Map]
///   fixed set of keys
///   getOrNull/setOrNot
///
/// Provides Key interface to an Object
/// mixin for withX and serialization
///
/// subclass determines mutability
/// interface and implementation
///
// extend to fill class variables.
// Field may use a type parameter other than V, used to determine the value of V
// always wrap a single Object, can implement as extension type when better support of abstract methods/override is available
// paste map mixin for 1 part mixin

// notes: extension type StructView<K extends Field, V>(Object _this) more closely resembles direct memory mapping with associated methods,
// but does not allow implementation of additional interfaces, redeclare keys rather then override may cause complications.
abstract mixin class Structure<K extends Field, V> /* implements  FixedMap<K, V>  */ {
  const Structure();

  // @override
  List<K> get keys; // a method that is the meta contents, fieldsList
  // Iterable<K> get keys;
  // List<K> get fields;

  // Map

  // mixin for asMap()
  V operator [](covariant K key) => get(key);
  void operator []=(covariant K key, V value) => set(key, value);

  // or mixin 2 additional for Map interface
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

  // with type contraint
  // `field` referring to the field value
  V field(K key) => get(key);
  void setField(K key, V value) => set(key, value);

  V? fieldOrNull(K key) => getOrNull(key);
  // trySetField
  bool setFieldOrNot(K key, V value) => setOrNot(key, value);

  FieldEntry<K, V> fieldEntry(K key) => (key: key, value: field(key));

  Iterable<V> valuesOf(Iterable<K> keys) => keys.map((key) => field(key));
  Iterable<FieldEntry<K, V>> entriesOf(Iterable<K> keys) => keys.map((key) => fieldEntry(key));

  /// with context of this.keys
  // IndexMap<K, V> asMap() => IndexMap<K, V>._(keys, valuesOf(keys));
  // Map<K, V> toMap() => IndexMap<K, V>.of(keys, valuesOf(keys));

  // Structure<K, V> copyWith() /// override in child class, using index map by default

// overwrite copyWith to cast after buffered build, or leave abstract.
  Structure<K, V> withFields(Structure<K, V?> fields) {
    // return StructMap.ofMap({for (var key in keys) key: fields.field(key) ?? field(key)} as FixedMap<K, V?>);
    return StructMap<K, V>(this)
      ..forEach((key, value) {
        if (fields.field(key) case V newValue) {
          this[key] = newValue;
        }
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

  @override
  int get hashCode => keys.fold(0, (prev, key) => prev ^ field(key).hashCode);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Structure<K, V>) {
      if (keys != other.keys) return false; // keys are fixed, so compare with ==
      // if (keys.length != other.keys.length) return false;
      for (var i = 0; i < keys.length; i++) {
        if (field(keys[i]) != other.field(keys[i])) return false;
      }
      return true;
    }
    return false;
  }
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
  // int get index; //index map correspondance

  @protected
  V getIn(covariant Object struct); // valueOf(covariant Object struct);
  @protected
  void setIn(covariant Object struct, V value); // setValueOf(covariant Object struct, V value);

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

// extension on List<Field> {
//   // provide toMap
//   Structure view(Object struct) {}
// }

/// implement Structure using parallel arrays
class StructMap<K extends Field, V> extends IndexMap<K, V> with Structure<K, V> {
  StructMap(Structure<K, V> struct) : super.of(struct.keys, struct.valuesOf(struct.keys));
  // StructMap.ofMap(super.map) : super.fromBase();
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

///
//   inheriting factory constructors
//S extends Structure<K, V>,
// extension type const StructClass<K extends Field, V>(List<K> keys) {
//   Structure<K, V> castView(Obje) => state as S;

//   // only this needs to be redefined in child class
//   // or castFrom
//   Structure<K, V> castBase(Structure<K, V> state) => state as S;

//   // alternatively use copyWith.
//   // or allow user end to maintain 2 separate routines?
//   // also separates cast as subtype from Structure class

//   // Structure<K, V?> create({Structure<K, V>? state, V? fill}) {
//   //   if (state == null) {
//   //     return StructureDefault<K, V?>.filled(keys, null);
//   //   } else {
//   //     return castBase(state);
//   //   }
//   // }

//   // Structure<K, V?> filled(V? fill) => StructureDefault<K, V?>.filled(keys, null);
//   // Structure<K, V?> fromValues([List<V>? values, V? fill]) => StructureDefault<K, V?>._fromValues(keys, values);

//   Structure<K, V> _fromEntries(Iterable<MapEntry<K, V>> entries) => StructMap<K, V>.fromEntries(keys, entries);
//   // assert all keys are present
//   S fromEntries(Iterable<MapEntry<K, V>> entries) => castBase(_fromEntries(entries));
//   S fromMap(Map<K, V> map) => castBase(_fromEntries(map.entries));
// }

/// Struct Class/Type/Factory
/// create S using constructor, or Structure<K, V> using keys
// class StructFactory<S extends Structure<K, V>, K extends Field, V> {
//   const StructFactory(this.keys, this.constructor);
//   final List<K> keys;
//   final S Function(Structure<K, V>) constructor;
//   // final S Function(Structure<K, V>) caster;
//   // final S Function() constructor;
// }

// /// [Construct] Factory + Data
// ///   keys + meta as a data member. library side create a structview
// // can be created without extending
// // Scope with T so copyWith can return a consistent type
// // handler with class variables,
// // wrapper around struct with Map and handler
// //
// //  - Map interface
// //    - Enum keys auto implement EnumMap and
// //  - StructBase interface
// //  - Factory
// //  - StructView interface
// //  - withX copy methods
// // // T as StrutBase or StructView
// @immutable
// // class Construct<T extends Structure<K, V>, K extends Field, V> extends Structure<K, V> {
// // class Construct<K extends Field, V> with MapBase<K, V>, FixedMap<K, V> {
// class Construct<T extends Structure<K, V>, K extends Field, V> with MapBase<K, V>, FixedMap<K, V>, Structure<K, V> {
//   Construct({
//     required this.keys,
//     required this.structData,
//     this.constructor,
//   });

//   // Construct.generic({
//   //   required this.keys,
//   //   required this.structData,
//   // }); // T is Structure<K, V> base

//   // Construct.t({
//   //   required this.keys,
//   //   required this.structData,
//   //   this.constructor,
//   // });

//   // Construct.fromKeys({
//   //   required this.keys,
//   // }) : structData = StructMap<K, V>( EnumIndexMap<K, V>.filled(keys, null));

//   // a signature for user override
//   // Construct.castBase(StructBase<K, V> base) : this(struct: base, keys: const []);

//   Construct.castBase(Structure<K, V> base)
//       : this(
//           structData: base,
//           keys: base.keys,
//         );

//   Construct.copyFrom(Structure<K, V> base)
//       : this(
//           structData: StructMap<K, V>(base),
//           keys: base.keys,
//         );

//   // factory Construct.fromJson(List<K> keys, Map<String, Object?> json) {
//   //   // if (keys is List<EnumField<V>>) {
//   //   //   return Construct<K, V>(
//   //   //     keys: keys,
//   //   //     struct: MapStruct(EnumMap<K, V>.fromJson(keys, json)),
//   //   //   );
//   //   // }
//   //   // throw UnsupportedError('Only EnumField is supported');
//   // }

//   final List<K> keys;
//   final Structure<K, V> structData; // or object
//   final T Function(Structure<K, V>)? constructor;
//   // dynamic classVariables;
//   // final int lengthMax;

//   // T create() =>

//   // T constructor() => IndexMap<K, V>. of(keys, values);
//   // T constructor() => StructMap<K, V>(this);
//   // Structure<K, V> _constructor(Structure<K, V> base) => Construct<Structure<K, V>, K, V>(keys: keys, structData: base);

//   // T construct(Structure<K, V> base) => constructor?.call(base) ?? Construct<Structure<K, V>, K, V>.castBase(base) as T;
//   // T construct(Structure<K, V> base) => constructor?.call(base) ?? StructMap<K, V>(base) as T;

//   // Construct<T, K, V> copyWithBase(Structure<K, V> base) => Construct<T, K, V>.castBase(constructor?.call(base) ?? StructMap<K, V>(base));

//   Type get structType => T;

//   // @override
//   // String toString() => MapBase.mapToString(this);

//   @override
//   V operator [](K key) => structData[key];
//   // V operator [](K key) => key.getIn(structData as Object);
//   @override
//   void operator []=(K key, V value) => structData[key] = value;
//   // void operator []=(K key, V value) => key.setIn(structData as Object, value);

//   @override
//   void clear() {
//     throw UnimplementedError();
//   }

//   @override
//   V remove(K key) {
//     throw UnimplementedError();
//   }

//   // @override
//   // Construct<T, K, V> copyWith() => Construct<T, K, V>.castBase(this);

//   // Construct<T, K, V> copyWithBase(base) => Construct<T, K, V>.castBase(base);
//   // Construct<T, K, V> withField(K key, V value) => Construct<T, K, V>.castBase(StructMap<K, V>(this)..[key] = value);
//   // Construct<T, K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => Construct<T, K, V>.castBase(StructMap<K, V>(this)..addEntries(newEntries));
//   // Construct<T, K, V> withAll(Map<K, V> map) => Construct<T, K, V>.castBase(StructMap<K, V>(this)..addAll(map));

//   // Map<K, V> toMap() {
//   //   assert(keys.first.index == keys.first.index); // ensure if index does not throw
//   //   return IndexMap.of(keys, keys.map((key) => key.getIn(struct._this)));
//   // }
// }

/// remove for now, Structure is better suited for interface
/// extension type version
// extension type cannot include abstract methods, or implement interfaces
// cannot define copyWith without context of Keys
// extension type StructView<K extends Field, V>(Object _this) {
//   List<K> get keys => throw UnimplementedError(); // override in child class

//   @protected
//   V get(Field key) => key.getIn(_this); // valueOf(Field key);
//   @protected
//   void set(Field key, V value) => key.setIn(_this, value);
//   @protected
//   //containsField
//   bool testBounds(Field key) => key.testBoundsOf(_this);

//   @protected
//   V? getOrNull(Field key) => testBounds(key) ? get(key) : null;
//   @protected
//   bool setOrNot(Field key, V value) {
//     if (!testBounds(key)) return false;
//     set(key, value);
//     return true;
//   }

//   V operator [](K key) => get(key);
//   void operator []=(K key, V value) => set(key, value);

//   // `field` referring to the field value
//   V field(K key) => get(key);
//   void setField(K key, V value) => set(key, value);
//   V? fieldOrNull(K key) => getOrNull(key);
//   bool setFieldOrNot(K key, V value) => setOrNot(key, value);

//   FieldEntry<K, V> fieldEntry(K key) => (key: key, value: field(key));

//   Iterable<V> fieldValues(Iterable<K> keys) => keys.map((key) => field(key));
//   Iterable<FieldEntry<K, V>> fieldEntries(Iterable<K> keys) => keys.map((key) => fieldEntry(key));

//   // Construct< K, V> withKeys(List<K> keys) => Construct< K, V>(struct: this, keys: keys);
//   // Construct<K, V> asConstruct(List<K> keys, {dynamic meta}) => Construct<MapStruct,K, V>(structData: this, keys: keys);

//   //  copy operations need context of keys
// }

// // effectively extends StructView with FixedMap
// extension type MapStruct<K extends Field, V>(FixedMap<K, V> _this) implements StructView<K, V> {
//   MapStruct.cast(List<K> keys, StructView<K, V> struct) : _this = IndexMap.of(keys, struct.fieldValues(keys));
//   // MapStruct.of(List<K> keys, Iterable<V> values) : _this = IndexMap.of(keys, values);

//   @protected
//   V get(Field key) => _this[key as K]; // valueOf(Field key); // by map[index]
//   @protected
//   void set(Field key, V value) => _this[key as K] = value;

//   // immutable `with` copy operations, via IndexMap
//   // analogous to operator []=, but returns a new instance
//   StructView<K, V> withField(K key, V value) => (IndexMap<K, V>.fromBase(_this)..[key] = value) as StructView<K, V>;
//   //
//   StructView<K, V> withEntries(Iterable<MapEntry<K, V>> newEntries) => (IndexMap<K, V>.fromBase(_this)..addEntries(newEntries)) as StructView<K, V>;
//   // A general values map representing external input, may be a partial map
//   StructView<K, V> withAll(Map<K, V> map) => (IndexMap<K, V>.fromBase(_this)..addAll(map)) as StructView<K, V>;
// }
