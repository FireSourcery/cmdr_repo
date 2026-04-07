import '../general/struct.dart';

import 'bit_struct.dart';
export 'bits.dart';

/// [BitField]
/// Key for [BitStruct] and [BitFieldMap]
/// as mixin, applicable to [enum]
///
// A Bit-field is a class data `member` with explicit size, in bits.
// https://en.cppreference.com/w/cpp/language/bit_field
// https://learn.microsoft.com/en-us/cpp/c-language/c-bit-fields?view=msvc-170
//
// A collection of `Bit-fields`, in a primitive type variable, e.g int,
// should be known as Bit-Fields, or Bits Field, Bit Struct, Bit-Field Struct
//
abstract mixin class BitField implements Field<int> {
  Bitmask get bitmask;

  @override
  int getIn(BitStruct<BitField> struct) => struct.getBits(bitmask);
  @override
  void setIn(BitStruct<BitField> struct, int value) => struct.setBits(bitmask, value);
  @override
  bool testAccess(BitStruct<BitField> struct) => bitmask.shift + bitmask.width <= struct.width;

  // implements Bitmask maintains all masks as as list
  // int get shift => bitmask.shift; // index of the first bit
  int get width => bitmask.width; // number of bits in the field

  int get valueMax => (1 << width) - 1;

  // @override
  // int get defaultValue => 0; // default value for the type
}

/// BitIndexField /// Special case: single-bit field addressed by index.
abstract mixin class BitIndexField implements BitField {
  int get index;
  Bitmask get bitmask => Bitmask.index(index);
  @override
  int getIn(BitStruct<BitField> struct) => struct.getBits(bitmask);
  @override
  void setIn(BitStruct<BitField> struct, int value) => struct.setBits(bitmask, value);
  @override
  bool testAccess(BitStruct<BitField> struct) => bitmask.shift + bitmask.width <= struct.width;
}

typedef BitFieldEntry<K extends BitField> = StructField<K, int>;

extension BitIndexKeysMethods on Iterable<BitIndexField> {
  int get totalWidth => length;
}
