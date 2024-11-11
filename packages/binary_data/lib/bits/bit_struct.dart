import 'package:cmdr_common/enum_map.dart';

import 'bits_map.dart';
export 'bits_map.dart';

////////////////////////////////////////////////////////////////////////////////
/// [Bits] + [] Map operators returning [int]
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitStruct<T extends BitFieldKey> implements BitsMap<T, int> {
  // const constructor cannot be defined in extension type
  const factory BitStruct.constant(List<T> keys, Bits bits) = ConstBitStructWithKeys;
  // const factory BitField.constInit(Map<T, int> values) = ConstBitFieldMap;

  // create a general bitsMap that can be cast later.
  factory BitStruct.generic(Bits bits) => ConstBitStructWithKeys<Never>(const [], bits);
  const factory BitStruct.prototype(List<T> keys) = ConstBitStructWithKeys<T>;

  // defined by child class
  List<T> get keys; // using Enum.values
  Bits get bits;

  // override to optimize
  @override
  int get width => keys.bitmasks.totalWidth;

  // Map operators
  @override
  int operator [](T key) => bits.getBits(key.bitmask);
  @override
  void operator []=(T key, int value) => bits = bits.withBits(key.bitmask, value);

  Iterable<({T key, bool value})> get fieldsAsBool => keys.map((e) => (key: e, value: (this[e] != 0)));

  @override
  BitStruct<T> copyWithBits(Bits value) => ConstBitStructWithKeys<T>(keys, value);
  @override
  BitStruct<T> copyWith() => copyWithBits(bits);

  // by default, EnumMap would allocate a new array buffer and copy each value
  // alternatively implement in BitsMap, if bits.withBits<V> is implemented, where V is int or bool
  @override
  BitStruct<T> withField(T key, int value) => copyWithBits(bits.withBits(key.bitmask, value));
  @override
  BitStruct<T> withEntries(Iterable<MapEntry<T, int>> entries) => copyWithBits(bits.withEach(entries.map((e) => (e.key.bitmask, e.value))));
  @override
  BitStruct<T> withAll(Map<T, int> map) => withEntries(map.entries);
}

/// [BitFieldKey] - key to BitFields
/// A List of [BitFieldKey], can be cast to either struct subtype
abstract mixin class BitFieldKey implements Enum, BitsKey {}

abstract mixin class BitFieldIndexKey implements Enum, BitsIndexKey {}

typedef BitField<K extends BitFieldKey, V> = Field<K, V>;
typedef BitFieldEntry<K extends BitFieldKey> = MapEntry<K, int>;

/// Subtype considerations:
/// to return a subtype of [BitStruct], :
///   provide the constructor of the subtype
///   use a prototype object .copyWithBits()

// Keys list effectively define type and act as factory
// Separates subtype `class variables` from instance
// extension type const BitStructClass<T extends BitStruct, K extends BitField>(List<T> keys) { as subtype
extension type const BitStructClass<T extends BitFieldKey>(List<T> keys) {
  BitStruct<T> castBase(BitsBase base) {
    return switch (base) {
      MutableBitFieldsBase() => MutableBitStructWithKeys(keys, base.bits),
      ConstBitFieldsBase() => ConstBitStructWithKeys(keys, base.bits),
      BitsBase() => throw StateError(''),
    };
  }

  BitStruct<T> castBits(int value) => ConstBitStructWithKeys(keys, Bits(value));

  // alternatively default constructors can return partial implementation without Keys/MapOperator
  BitStruct<T> create([int value = 0, bool mutable = true]) {
    return switch (mutable) {
      true => MutableBitStructWithKeys(keys, Bits(value)),
      false => ConstBitStructWithKeys(keys, Bits(value)),
    };
  }

  // Alternatively subclass directly call Bits constructors to derive Bits value
  // enum map by default copies into an array
  BitStruct<T> fromValues(Iterable<int> values, [bool mutable = true]) {
    return create(Bits.ofIterables(keys.bitmasks, values), mutable);
  }

  BitStruct<T> fromMap(Map<T, int> map, [bool mutable = true]) {
    return create(Bits.ofEntries(map.bitsEntries), mutable);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// extendable, with Enum.values
////////////////////////////////////////////////////////////////////////////////
// abstract class BitFieldBase<T extends BitFieldKey> = BitsMapBase<T, int> with BitField<T>;
abstract class MutableBitStructBase<T extends BitFieldKey> = MutableBitFieldsBase<T, int> with BitStruct<T>;
abstract class ConstBitStructBase<T extends BitFieldKey> = ConstBitFieldsBase<T, int> with BitStruct<T>;
// ignore: missing_override_of_must_be_overridden
class MutableBitStructWithKeys<T extends BitFieldKey> = MutableBitFieldsWithKeys<T, int> with BitStruct<T>;
// ignore: missing_override_of_must_be_overridden
class ConstBitStructWithKeys<T extends BitFieldKey> = ConstBitFieldsWithKeys<T, int> with BitStruct<T>;

/// A BitsMap that also has an Enum Id
/// constructor compile time constant by wrapping Map.
abstract mixin class EnumBits<K extends BitFieldKey> implements Enum {
  Map<K, int> get initializer; // per enum instance

  static Map<int, EnumBits> buildReverseMap(List<EnumBits> enumValues) {
    return Map.unmodifiable({for (final enumId in enumValues) enumId.bits: enumId});
  }

  List<K> get bitFieldKeys; // per class

  BitStruct asBitStruct() => BitStruct.constant(bitFieldKeys, bits);
  // BoolStruct asBoolStruct()  {assert(bitFieldKeys is List<BitsIndexKey>), BoolStruct.constant(bitFieldKeys as List<BitsIndexKey>, bits)};
  Bits get bits => Bits.ofEntries(initializer.bitsEntries);
  int get value => bits;
}


// user combines mixins
// ignore: missing_override_of_must_be_overridden
// class ConstBitStructInit<T extends BitField> = Object with ConstBitsBaseInit, MapBase<T, int>, EnumMap<T, int>, BitFields<T, int>;

/// constructor compile time constant by wrapping Map.
/// alternatively use final and compare using value
// abstract class ConstBitStructInit<T extends BitField> extends ConstBitFieldsInit<T, int> with BitStruct<T> {
//   const ConstBitStructInit(super.source);

//   @override
//   int get width => source.keys.map((e) => e.bitmask).totalWidth;
//   @override
//   Bits get bits => Bits.ofEntries(source.bitsEntries);

//   @override
//   set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");

//   // @override
//   // BitField<T> copyWith() => this;

//   // @override
//   // List<T> get keys => source.keys;
// }

