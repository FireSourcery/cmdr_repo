import 'package:type_ext/struct.dart';

import 'bits.dart';
export 'bits.dart';

////////////////////////////////////////////////////////////////////////////////
/// A Bit-field is a class data `member` with explicit size, in bits.
/// https://en.cppreference.com/w/cpp/language/bit_field
/// https://learn.microsoft.com/en-us/cpp/c-language/c-bit-fields?view=msvc-170
///
/// A collection of `Bit-fields`, in a primitive type variable, e.g int, should be known as Bit-Fields, or Bits Field, Bit Struct, Bit-Field Struct
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// Key for [BitStruct] and [BitFieldMap]
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitField /* , Field<int>  */ {
  Bitmask get bitmask;
}

abstract mixin class BitIndexField implements BitField {
  int get index;
  Bitmask get bitmask => Bitmask.index(index);

  // int get defaultValue => 0;
}

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

typedef BitFieldEntry<K extends BitField, V> = FieldEntry<K, V>;
typedef BitFieldEntries = Iterable<({BitField fieldKey, int fieldValue})>;

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
