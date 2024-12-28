import 'package:collection/collection.dart';
import 'package:type_ext/struct.dart';

import 'bits.dart';
export 'bits.dart';

////////////////////////////////////////////////////////////////////////////////
/// A Bit-field is a class data `member` with explicit size, in bits.
/// https://en.cppreference.com/w/cpp/language/bit_field
/// https://learn.microsoft.com/en-us/cpp/c-language/c-bit-fields?view=msvc-170
///
/// A collection of `Bit-fields`, in a primitive type variable, e.g int,
/// should be known as Bit-Fields, or Bits Field, Bit Struct, Bit-Field Struct
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// Key for [BitStruct] and [BitFieldMap]
/// mixin to apply to [enum]
//  todo add Field<int>
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitField /* implements Field<int> */ {
  Bitmask get bitmask;
  // int get defaultValue => 0;

  // alternatively derive at runtime from only width defined at compile time
  // List<BitField> get bitFields; // Enum.values
  // int get width;
  // Bitmask get bitmask => Bitmask.bits(bitFields.map((e) => e.width).take(bitFields.indexOf(this)).sum, width);
}

abstract mixin class BitIndexField implements BitField {
  int get index;
  Bitmask get bitmask => Bitmask.index(index);
  // int get defaultValue => 0;
}

// alternatively BitsKey implements Bitmask
// then these are not needed
extension BitKeysMethods on Iterable<BitField> {
  Bitmasks get bitmasks => map((e) => e.bitmask) as Bitmasks;
  // Bitmasks get bitmasks => Bitmasks.fromWidths(map((e) => e.width));
  int get totalWidth => map((e) => e.bitmask.width).sum;
}

extension BitIndexKeysMethods on Iterable<BitIndexField> {
  int get totalWidth => length;
}

extension BitsMapMethods on Map<BitField, int> {
  Iterable<MapEntry<Bitmask, int>> get bitsEntries => keys.map((e) => MapEntry(e.bitmask, this[e]!));
}

extension BitsEntrysMethods on Iterable<MapEntry<BitField, int>> {
  Iterable<MapEntry<Bitmask, int>> get bitsEntries => map((e) => MapEntry(e.key.bitmask, e.value));
}

typedef BitFieldEntry<K extends BitField, V> = FieldEntry<K, V>;

/// constructor compile time constant by wrapping Map.
/// alternatively use final and compare using value
///
/// for cast of compile time const definition using map literal
/// BitStruct<EnumType> example = BitsInitializer({
///   EnumType.name1: 2,
///   EnumType.name2: 3,
/// });
///
typedef BitsInitializer<T extends BitField> = Map<T, int>;

extension BitsInitializerMethods on BitsInitializer {
  int get width => keys.totalWidth;
  Bits get bits => Bits.ofEntries(bitsEntries); // in order to init using const Map, bits must be derived at run time
}

//todo
extension type BitStructView<K extends BitField_>(BitsBase _this) implements StructView<K, int>, BitsBase {
  int get(K key) => _this.getBits(key.bitmask);
  void set(K key, int value) => _this.setBits(key.bitmask, value);
  bool testBoundsOf(K key) => key.bitmask.shift + key.bitmask.width <= width;
}

abstract mixin class BitField_ implements Field<int> {
  Bitmask get bitmask;
  @override
  int getIn(BitsBase struct) => struct.getBits(bitmask);
  @override
  void setIn(BitsBase struct, int value) => struct.setBits(bitmask, value);
  @override
  bool testBoundsOf(BitsBase struct) => bitmask.shift + bitmask.width <= struct.width;

  @override
  int get defaultValue => 0;
}
