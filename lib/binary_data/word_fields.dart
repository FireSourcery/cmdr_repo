import 'dart:collection';
import 'package:meta/meta.dart';

import '../common/fixed_map.dart';
import 'typed_field.dart';
import 'bitfield.dart';
import 'bits_map.dart';
import 'bits.dart';
import 'word.dart';

/// BitField enforcing byte aligned fields
///
/// [Bits] + operators <WordField, int> + [Bytes] up to 8 bytes
///
/// [Word] with named fields, associated keys
///
/// Implementation centric DataMap, up to 8 bytes, int values only
///   a special case where the data struct is known, does not need child constructor
///
abstract mixin class WordFields<T extends WordField> implements BitField<T> {}

// /// a field within a Word, unlike BitField
// for user to define map operator and name
/// interface for including [TypedField<T>], [Enum]
/// type ensure bitmask is power of 2
abstract mixin class WordField<V extends NativeType> implements TypedField<V>, BitFieldMember, Enum {
  // alternatively store the bitmask
  @override
  Bitmask get bitmask => Bitmask.bytes(offset, size);

  // static Bitmask bitmaskOf<T extends NativeType>(int offset) => Bitmask.bytes(offset, sizeOf<T>());
  // TypedField<V> get typedField; // alternatively compose so it does not need to be implemented
}

/// Must extend Word for const constructor, until const expressions are supported
/// Keep as bodyless to passthrough [Word] constructors
abstract class WordFieldsBase<T extends WordField> = Word with MapBase<T, int>, BitsMap<T, int>, BitFieldMixin<T>, UnmodifiableBitsMixin implements WordFields<T>;

// need additional shared constructor
// WordFieldsBase.createWith( BitField < T> state) : super.init(state.bits);  
// WordFieldsBase.createWith( BitsMap<T, int> state) : super.init( BitFieldBits.ofValuesMap(state));