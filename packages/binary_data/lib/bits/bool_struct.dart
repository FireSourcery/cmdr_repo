// import 'package:flutter/foundation.dart' as foundation show BitField;

import 'bits_map_base.dart';
export 'bits_map_base.dart';

////////////////////////////////////////////////////////////////////////////////
/// [Bits] + [] Map operators returning [bool]
///   `Bit Index Map`
///
/// A Bit-field is a class data `member` with explicit size, in bits.
/// https://en.cppreference.com/w/cpp/language/bit_field
/// https://learn.microsoft.com/en-us/cpp/c-language/c-bit-fields?view=msvc-170
///
/// A collection of `Bit-fields`, in a primitive type variable, e.g int, should be known as Bit-Fields, or Bits Field, Bit Struct, Bit-Field Struct
///
/// Use BitStruct for a general case.
///   BoolStruct will accept BitField Enum keys, and return bool values.
///   BoolStruct provides a constraint on the value type, bool, and slight optimization for bitmask operations.
///
////////////////////////////////////////////////////////////////////////////////
// implements foundation.BitField<T>,
abstract mixin class BoolStruct<T extends Enum> implements BitsMapBase<T, bool> {
  const BoolStruct();

  // factory BoolStruct(List<T> keys, [int bits = 0, bool mutable = true]) {
  //   assert(bits.bitLength < keys.length);
  //   return switch (mutable) {
  //     true => MutableBoolStructWithKeys<T>(keys, Bits(bits)),
  //     false => ConstBoolStructWithKeys<T>(keys, Bits(bits)),
  //   };
  // }

  // const factory BoolStruct.constant(int width, Bits bits) = ConstBoolStructWithKeys;
  // const factory BoolStruct.constInit(Map<T, bool> values) = ConstBoolStructMap;

  // factory BoolStruct.fromFlags(Iterable<bool> flags, [bool mutable = true]) => BoolStruct.from(flags.length, Bits.ofBools(flags), mutable);
  // factory BoolStruct.fromMap(Map<T, bool> map, [bool mutable = true]) => BoolStruct.from(map.length, Bits.ofIndexMap(map), mutable);

  // factory BoolStruct.cast(BoolStruct boolStruct, [bool mutable = true]) => BoolStruct.from(boolStruct.width, boolStruct.bits, mutable);

  List<T> get keys;
  Bits get bits;

  @override
  int get width => keys.length; // override in from values case

  @override
  bool operator [](T key) {
    // if(key is BitFieldKey) return  ;
    // if(key is Enum) return bits.boolAt(key.index);

    assert(key.index < width);
    return bits.boolAt(key.index);
  }

  @override
  void operator []=(T key, bool value) {
    assert(key.index < width);
    bits = bits.withBoolAt(key.index, value);
  }

  @override
  bool remove(T key) {
    final value = this[key];
    this[key] = false;
    return value;
  }

  @override
  Iterable<({T key, int value})> get fieldsAsBits => keys.map((e) => (key: e, value: this[e] ? 1 : 0));
  @override
  Iterable<({T key, bool value})> get fieldsAsBool => fields;

  Iterable<int> get valuesAsBits => values.map((e) => e ? 1 : 0);
  Iterable<MapEntry<T, int>> get entriesAsBits => keys.map((key) => MapEntry(key, this[key] ? 1 : 0));

  @override
  BoolStruct<T> copyWithBits(Bits bits) => ConstBoolMap<T>(keys, bits);
  @override
  BoolStruct<T> copyWith() => copyWithBits(bits);

  @override
  BoolStruct<T> withField(T key, bool value) => copyWithBits(bits.withBoolAt(key.index, value));
  @override
  BoolStruct<T> withEntries(Iterable<MapEntry<T, bool>> entries) => copyWithBits(bits.withEachBool(entries.map((e) => (e.key.index, e.value))));
  @override
  BoolStruct<T> withAll(Map<T, bool> map) => withEntries(map.entries);
}

// typedef BoolKey = BitsIndexKey;
// abstract mixin class IndexField implements BitField {
//   int get index;
//   Bitmask get bitmask => Bitmask.index(index);
// }

////////////////////////////////////////////////////////////////////////////////
/// extendable
////////////////////////////////////////////////////////////////////////////////
abstract class MutableBoolStruct<T extends Enum> = MutableBitsStructBase<T, bool> with BoolStruct<T>;
abstract class ConstBoolStruct<T extends Enum> = ConstBitsStructBase<T, bool> with BoolStruct<T>;

// ignore: missing_override_of_must_be_overridden
class MutableBoolMap<T extends Enum> = MutableBitsMap<T, bool> with BoolStruct<T>;
// ignore: missing_override_of_must_be_overridden
class ConstBoolMap<T extends Enum> = ConstBitsMap<T, bool> with BoolStruct<T>;

// abstract class ConstBoolStructInit<T extends Enum> extends ConstBitFieldsInit<T, bool> with BoolStruct<T> {
//   const ConstBoolStructInit(super.source);

//   @override
//   Bits get bits => Bits.ofIndexValues(source.entries.map((e) => (e.key.index, e.value)));

//   @override
//   set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");

//   @override
//   BoolStruct<T> copyWith() => this;
// }
