import 'dart:collection';
import 'package:meta/meta.dart';

import '../common/enum_map.dart';
import 'bit_struct.dart';
import 'bit_field.dart';
import 'bits.dart';
import 'word.dart';
import 'typed_field.dart';

///
/// [Bits]/[Word] + [] Map operators returning [int]
///
/// effectively,
/// [BitField] enforcing byte aligned fields, up to 8 bytes
///
/// Implementation centric DataMap, up to 8 bytes, int values only
abstract mixin class WordStruct<T extends WordField> implements BitStruct<T> {
  const WordStruct();

  int get byteLength => bits.byteLength;
}

// /// a field within a Word, unlike BitField
// for user to define map operator and name
/// interface for including [TypedField<T>], [Enum]

/// type ensure bitmask is power of 2
abstract mixin class WordField<V extends NativeType> implements TypedField<V>, BitField, Enum {
  // alternatively store the bitmask
  @override
  Bitmask get bitmask => Bitmask.bytes(offset, size);
}

// BitField with Word constructors
abstract class WordStructBase<T extends WordField> extends ConstBitStructBase<T> with WordStruct<T> {
  // const WordFieldsBase.bits(super.bits) : super();

  // re-implementation of Word constructors for const
  const WordStructBase(int bits) : super(bits as Bits);

  const WordStructBase.of32s(int ls32, [int ms32 = 0]) : this((ms32 << 32) | (ls32 & _mask32));

  const WordStructBase.of16s(int ls16, [int upperLs16 = 0, int lowerMs16 = 0, int ms16 = 0])
      : this.of32s(
          (upperLs16 << 16) | (ls16 & _mask16),
          (ms16 << 16) | (lowerMs16 & _mask16),
        );

  // assign with parameters in little endian order for byteLength
  const WordStructBase.of8s(int lsb, [int lsb1 = 0, int lsb2 = 0, int lsb3 = 0, int msb3 = 0, int msb2 = 0, int msb1 = 0, int msb = 0])
      : this.of16s(
          (lsb1 << 8) | (lsb & _mask8),
          (lsb3 << 8) | (lsb2 & _mask8),
          (msb2 << 8) | (msb3 & _mask8),
          (msb << 8) | (msb1 & _mask8),
        );

  static const int _mask8 = 0xFF;
  static const int _mask16 = 0xFFFF;
  static const int _mask32 = 0xFFFFFFFF;

  WordStructBase.castBase(super.state) : super.castBase();

  // WordFieldsBase.values(List<T> keys, Iterable<int> values, [bool mutable = true]) {
  //   return WordFieldsBaseWithKeys(keys, keys.bitmasks.apply(values), mutable);
  // }
}

// constructors passed through
class WordStructBaseWithKeys<T extends WordField> = ConstBitStructWithKeys<T> with WordStruct<T>;

/// alternatively
/// Must extend Word for const constructor, until const expressions are supported
///  cannot pass parameters to another constructor even if it is const, e.g. super(const Word.of8s(lsb, lsb1, lsb2, lsb3, msb3, msb2, msb1, msb));
/// Keep as bodyless to passthrough [Word] constructors
// abstract class WordFieldsBase<T extends WordField> = Word with MapBase<T, int>, BitsMap<T, int>, BitFieldMixin<T>, UnmodifiableBitsMixin implements WordFields<T>
