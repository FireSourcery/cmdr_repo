import 'package:collection/collection.dart';
import 'package:type_ext/struct.dart';

import 'bits.dart';
export 'bits.dart';

////////////////////////////////////////////////////////////////////////////////
/// [BitField]
/// Key for [BitStruct] and [BitFieldMap]
/// as mixin, applicable to [enum]
////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
/// A Bit-field is a class data `member` with explicit size, in bits.
/// https://en.cppreference.com/w/cpp/language/bit_field
/// https://learn.microsoft.com/en-us/cpp/c-language/c-bit-fields?view=msvc-170
///
/// A collection of `Bit-fields`, in a primitive type variable, e.g int,
/// should be known as Bit-Fields, or Bits Field, Bit Struct, Bit-Field Struct
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitField /* implements Field<int> */ {
  Bitmask get bitmask;

  // implements Bitmask maintains all masks as as list
  // int get shift => bitmask.shift; // index of the first bit
  // int get width => bitmask.width; // number of bits in the field

  // int get valueMax => (1 << width) - 1);

  /* implements Field<int> */
  // @override
  // int getIn(BitsBase struct) => struct.getBits(bitmask);
  // @override
  // void setIn(BitsBase struct, int value) => struct.setBits(bitmask, value);
  // @override
  // bool testBoundsOf(BitsBase struct) => bitmask.shift + bitmask.width <= struct.width;

  // @override
  // int get defaultValue => 0; // default value for the type
}

/// BitIndexField special case
abstract mixin class BitIndexField implements BitField {
  int get index;
  Bitmask get bitmask => Bitmask.index(index);
}

// as record
typedef BitFieldEntry<K extends BitField> = FieldEntry<K, int>;

////////////////////////////////////////////////////////////////////////////////
/// Bitmask accessors
////////////////////////////////////////////////////////////////////////////////
// alternatively BitField implements Bitmask,
// this way, less mixin redundancy, for now
extension BitKeysMethods on Iterable<BitField> {
  Bitmasks get bitmasks => map((e) => e.bitmask) as Bitmasks;
  int get totalWidth => bitmasks.totalWidth;

  Bits mapValues(List<int> values) {
    if (length != values.length) throw ArgumentError('Values length ${values.length} does not match BitFields length $length');

    return Bits.ofPairs(mapIndexed((index, e) => (e.bitmask, values[index])));
  }
}

extension BitsMapMethods on Map<BitField, int> {
  Iterable<MapEntry<Bitmask, int>> get bitsEntries => keys.map((e) => MapEntry(e.bitmask, this[e]!));
}

extension BitsEntrysMethods on Iterable<MapEntry<BitField, int>> {
  Iterable<MapEntry<Bitmask, int>> get bitsEntries => map((e) => MapEntry(e.key.bitmask, e.value));
}

extension BitIndexKeysMethods on Iterable<BitIndexField> {
  int get totalWidth => length;
}

// alternatively derive at runtime from only width defined at compile time
// abstract mixin class EnumBitField implements BitField, Enum {
//   int get width; 
//   int get index; 
//   List<BitField> get bitFields; // Enum.values
//   Bitmasks get bitmasks =>  bitFields.map((e) => Bitmask.bits(e.index, e. width)); 
//   Bitmask get bitmask => bitmasks.take(index).sum, width ;
// }
