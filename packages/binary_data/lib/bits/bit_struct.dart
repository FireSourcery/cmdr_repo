import 'package:meta/meta.dart';

import 'package:type_ext/enum_map.dart';
import 'package:type_ext/struct.dart';

import 'bits_map_base.dart';
export 'bits_map_base.dart';

////////////////////////////////////////////////////////////////////////////////
/// [Bits] with key access
/// [] Map operators, returning [int]
///
/// [BitStruct] Interface for extending with Subtypes
///   cannot be built directly, extend or use [BitsMap]
///   Struct must be extended with Keys
///   Partial Map implementation, with [Bits] as source
///   Can be constructed without Keys to be cast later
///   Although this could be implemented as a extension on BitsBase,
///     as a class is reusable as an interface,
///     extension type on bitsBase, or reuse as map implementation
///
/// [BitsMap] - a version of Map with [Bits] as source, should not be extended
////////////////////////////////////////////////////////////////////////////////
/// BitConstruct
abstract mixin class BitStruct<T extends BitField> implements BitsMapBase<T, int> {
  // const constructor cannot be defined in extension type
  // create a prototype object that can be copied with bits
  // const factory BitStruct.withType(List<T> keys, Bits bits) = ConstBitStructMap<T>;

  // create a general bitsMap that can be cast later.
  // factory BitStruct.generic(Bits bits) => ConstBitStructMap<Never>(const [], bits);

  // defined by child class
  List<T> get keys; // using Enum.values
  Bits get bits;

  // override to optimize
  @override
  int get width => keys.bitmasks.totalWidth;

  // Map operators
  @override
  int operator [](covariant T key) => bits.getBits(key.bitmask);
  @override
  void operator []=(covariant T key, int value) => bits = bits.withBits(key.bitmask, value);

  @override
  int remove(T key) {
    final value = this[key];
    this[key] = 0;
    return value;
  }

  // Unconstrained type keys
  @protected
  int get(BitField key) => bits.getBits(key.bitmask);
  @protected
  void set(BitField key, int value) => setBits(key.bitmask, value);
  @protected
  bool testBounds(BitField key) => key.bitmask.shift + key.bitmask.width <= width;
  @protected
  int? getOrNull(BitField key) => testBounds(key) ? bits.getBits(key.bitmask) : null;
  @protected
  bool setOrNot(BitField key, int value) {
    if (testBounds(key)) {
      bits = bits.withBits(key.bitmask, value);
      return true;
    }
    return false;
  }

  int field(T key) => get(key);
  void setField(T key, int value) => set(key, value);
  int? fieldOrNull(T key) => getOrNull(key);
  bool setFieldOrNot(T key, int value) => setOrNot(key, value);

  // move to map
  @override
  Iterable<({T key, bool value})> get fieldsAsBool => keys.map((e) => (key: e, value: (this[e] != 0)));
  @override
  Iterable<({T key, int value})> get fieldsAsBits => keys.map((e) => (key: e, value: this[e]));

  @override
  BitStruct<T> copyWithBits(Bits value) => ConstBitStructMap<T>(keys, value);
  @override
  BitStruct<T> copyWith() => copyWithBits(bits);

  // alternatively implement in BitsMap, if bits.withBits<V> is implemented, where V is int or bool
  @override
  BitStruct<T> withField(T key, int value) => copyWithBits(bits.withBits(key.bitmask, value));
  @override
  BitStruct<T> withEntries(Iterable<MapEntry<T, int>> entries) => copyWithBits(bits.withEach(entries.map((e) => (e.key.bitmask, e.value))));
  @override
  BitStruct<T> withAll(Map<T, int> map) => withEntries(map.entries);

  // // as map with Bits based implementation
  // Map<T, int> asMap() => ConstBitStructMap(keys, bits);
}

////////////////////////////////////////////////////////////////////////////////
/// Keyed/Field Access
////////////////////////////////////////////////////////////////////////////////
// extension type BitStructView<K extends _BitField>(BitsBase bits) implements StructView<K, int>, BitsBase {
//   int get(K key) => bits.getBits(key.bitmask);
//   void set(K key, int value) => bits.setBits(key.bitmask, value);
//   bool testBoundsOf(K key) => key.bitmask.shift + key.bitmask.width <= width;
// }

// abstract mixin class _BitField implements Field<int> {
//   Bitmask get bitmask;
//   @override
//   int getIn(BitsBase struct) => struct.getBits(bitmask);
//   @override
//   void setIn(BitsBase struct, int value) => struct.setBits(bitmask, value);
//   @override
//   bool testBoundsOf(BitsBase struct) => bitmask.shift + bitmask.width <= struct.width;

//   @override
//   int? getInOrNull(BitsBase struct) => (this as Field<int>).getInOrNull(struct);
//   @override
//   bool setInOrNot(BitsBase struct, int value) => (this as Field<int>).setInOrNot(struct, value);

//   @override
//   int get defaultValue => 0;
// }

/// [BitField] - key to BitFields
/// A List of [BitField], can be cast to either struct subtype
// alternatively BitsKey implements Bitmask, build with Bitmask constructor
abstract mixin class BitField implements Enum /* , Field<int>  */ {
  Bitmask get bitmask;
}

abstract mixin class BitIndexField implements BitField {
  int get index;
  Bitmask get bitmask => Bitmask.index(index);

  // int get defaultValue => 0;
}

// typedef BitFieldEntry<K extends BitField, V> = FieldEntry<K, V>;
// typedef BitFieldEntries = Iterable<({BitField fieldKey, int fieldValue})>;

// alternatively BitsKey implements Bitmask
// then these are not needed
extension BitsKeysMethods on Iterable<BitField> {
  Bitmasks get bitmasks => map((e) => e.bitmask) as Bitmasks;
}

extension BitsMapMethods on Map<BitField, int> {
  Iterable<MapEntry<Bitmask, int>> get bitsEntries => entries.map((e) => MapEntry(e.key.bitmask, e.value));
}

extension BitsEntrysMethods on Iterable<MapEntry<BitField, int>> {
  Iterable<MapEntry<Bitmask, int>> get bitsEntries => map((e) => MapEntry(e.key.bitmask, e.value));
}

/// Subtype considerations:
/// to return a subtype of [BitStruct], :
///   provide the constructor of the subtype
///   use a prototype object .copyWithBits()

mixin BitStructAsSubtype<S extends BitStruct<K>, K extends BitField> on BitStruct<K> {
  @override
  S withField(K key, int value) => super.withField(key, value) as S;
  @override
  S withEntries(Iterable<MapEntry<K, int>> entries) => super.withEntries(entries) as S;
  @override
  S withAll(Map<K, int> map) => super.withAll(map) as S;
}

////////////////////////////////////////////////////////////////////////////////
/// Struct without Map methods
/// extendable, with Enum.values
////////////////////////////////////////////////////////////////////////////////
abstract class MutableBitStruct<T extends BitField> = MutableBitsStructBase<T, int> with BitStruct<T>;
abstract class ConstBitStruct<T extends BitField> = ConstBitsStructBase<T, int> with BitStruct<T>;

/// separate struct and map need to split enumStruct
// abstract class MutableBitStruct<T extends BitField> = MutableBits with BitStruct<T>;
// abstract class ConstBitStruct<T extends BitField> = ConstBits with BitStruct<T>;

// class MutableBitStruct<T extends BitField> extends MutableBitsStructBase<T, int> with BitStruct<T> {
//   MutableBitStruct(super.bits);
//     MutableBitStruct.castBase(BitsMapBase<T, V> super.state)
//       : keys = state.keys,
//         super.castBase();

//   @override
//   MutableBitStruct<T> copyWith() => MutableBitStruct<T>(bits);

//   @override
//   List<T> get keys => const []; // this can be removed later, split struct and map
// }

// class ConstBitStruct<T extends BitField> extends ConstBitsStructBase<T, int> with BitStruct<T> {
//   const ConstBitStruct(super.bits);
//   ConstBitStruct.castBase(BitsMapBase<T, V> super.state)
//       : keys = state.keys,
//         super.castBase();

//   @override
//   ConstBitStruct<T> copyWith() => ConstBitStruct<T>(bits);

//   @override
//   List<T> get keys => const []; // this can be removed later, split struct and map
// }

// todo combine with WithKeys
// Keys list effectively define type and act as factory
// Separates subtype `class variables` from instance
// extension type const BitStructClass<T extends BitStruct, K extends BitField>(List<T> keys) { as subtype
// extension type const BitStructClass<T extends BitField>(List<T> keys) {
//   // BitStruct<T> castBase(BitsBase base) {
//   //   return switch (base) {
//   //     MutableBitFieldsBase() => MutableBitStructWithKeys(keys, base.bits),
//   //     ConstBitFieldsBase() => ConstBitStructWithKeys(keys, base.bits),
//   //     BitsBase() => throw StateError(''),
//   //   };
//   // }

//   // BitStruct<T> castBits(int value) => ConstBitStructWithKeys(keys, Bits(value));

//   // alternatively default constructors can return partial implementation without Keys/MapOperator
//   BitStruct<T> create([int value = 0, bool mutable = true]) {
//     return switch (mutable) {
//       true => MutableBitStructWithKeys(keys, Bits(value)),
//       false => ConstBitStructWithKeys(keys, Bits(value)),
//     };
//   }

//   // Alternatively subclass directly call Bits constructors to derive Bits value
//   // enum map by default copies into an array
//   BitStruct<T> fromValues(Iterable<int> values, [bool mutable = true]) {
//     return create(Bits.ofIterables(keys.bitmasks, values), mutable);
//   }

//   BitStruct<T> fromMap(Map<T, int> map, [bool mutable = true]) {
//     return create(Bits.ofEntries(map.bitsEntries), mutable);
//   }
// }

/// Struct with Map Interface

// ignore: missing_override_of_must_be_overridden
class BitStructMap<T extends BitField> = MutableBitsMap<T, int> with BitStruct<T>;
// ignore: missing_override_of_must_be_overridden
class ConstBitStructMap<T extends BitField> = ConstBitsMap<T, int> with BitStruct<T>;

/// constructor compile time constant by wrapping Map.
/// alternatively use final and compare using value
///
/// for cast of compile time const definition using map literal
/// BitStruct<EnumType> example = BitsInitializer({
///   EnumType.name1: 2,
///   EnumType.name2: 3,
/// });
///
/// mixin on user class, which will already have all other methods implemented
///
/// can be implemented on Enum to give each const Bits an Enum Id and String name
/// enum must include each mixin separately
abstract mixin class BitsInitializer<T extends BitField> implements BitStruct<T> {
  Map<T, int> get initializer; // per instance

  List<T> get keys; // per class

  @override
  int get width => initializer.keys.map((e) => e.bitmask).totalWidth;
  @override
  Bits get bits => Bits.ofEntries(initializer.bitsEntries); // in order to initial using const Map, bits must be derived at run time
  @override
  set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");

  static Map<int, BitsInitializer> buildReverseMap(List<BitsInitializer> enumValues) {
    return Map.unmodifiable({for (final enumId in enumValues) enumId.bits: enumId});
  }

  // @override
  // BitField<T> copyWith() => this;

  // @override
  // List<T> get keys => source.keys;
}

/// optionally use BitsInitializer to simplfiy compile time const
abstract mixin class EnumBits<K extends BitField> implements Enum {
  Bits get bits; // per instance

  List<K> get keys; // per class

  // int get value => bits;
  BitStruct<K> asBitStruct() => ConstBitStructMap<K>(keys, bits);
  // BoolStruct asBoolStruct()  {assert(bitFieldKeys is List<BitsIndexKey>), BoolStruct.constant(bitFieldKeys as List<BitsIndexKey>, bits)};
}

// extension BitsInitializerMethods<K extends BitField> on BitsInitializer<K> {
//   BitStruct<K> asBitStruct() => ConstBitStructMap<K>(bitFieldKeys, bits);
//   // BoolStruct asBoolStruct()  {assert(bitFieldKeys is List<BitsIndexKey>), BoolStruct.constant(bitFieldKeys as List<BitsIndexKey>, bits)};
// }
