import 'dart:collection';
import 'package:cmdr/common/enum_map.dart';
import 'package:meta/meta.dart';

import 'bits.dart';

/// Special case of [EnumMap], all values retrieve from a [Bits] object
/// T is Enum for Flags, Bitmask for Field
/// V is bool for Flags, int for Field
abstract mixin class BitsMap<K extends Enum, V> implements EnumMap<K, V> {
  const BitsMap();

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable

  int get width;

  void setBits(Bitmask mask, int value) => bits = bits.withBits(mask, value);
  void setBitsAt(int offset, int width, int value) => bits = bits.withBitsAt(offset, width, value);
  void setBitAt(int index, int value) => bits = bits.withBitAt(index, value);
  void setBoolAt(int index, bool value) => bits = bits.withBoolAt(index, value);
  void setByteAt(int index, int value) => bits = bits.withByteAt(index, value);
  void setBytesAt(int index, int size, int value) => bits = bits.withBytesAt(index, size, value);
  void setEach(Iterable<(Bitmask mask, int value)> entries) => bits = bits.withEach(entries);

  void reset([bool fill = false]) => bits = fill ? const Bits.allOnes() : const Bits.allZeros();

  @override
  void clear() => bits = const Bits.allZeros();

  // as a special case for BitsMap, override this function for withX function to return as child type
  // if T includes Bitmask in this module, the optimized implementation with V as int can be defined here
  @protected
  BitsMap<K, V> copyWithBits(Bits value);

  @override
  BitsMap<K, V> copyWith() => copyWithBits(bits);

  @override
  String toString() => '$runtimeType: $values';

  @override
  bool operator ==(covariant BitsMap<K, V> other) {
    if (identical(this, other)) return true;
    return other.bits == bits;
  }

  @override
  int get hashCode => bits.hashCode;
}

/// combined mixins
/// implementations assign V type, [] operators, whether accessor use bitmask; derived or defined etc.
abstract class BitsMapBase<K extends Enum, V> = EnumMapBase<K, V> with BitsMap<K, V> implements BitsMap<K, V>;

// abstract interface class BitsMapKey implements Enum {}
typedef BitsMapKey = Enum;

/// inherited abstract constructors
abstract class MutableBitsMapBase<T extends BitsMapKey, V> extends BitsMapBase<T, V> implements BitsMap<T, V> {
  MutableBitsMapBase([this.bits = const Bits.allZeros()]);
  // copyFrom, withState, view
  MutableBitsMapBase.fromBase(BitsMap<T, V> state) : this(state.bits);

  @override
  Bits bits;
}

@immutable
abstract class ConstBitsMapBase<T extends BitsMapKey, V> extends BitsMapBase<T, V> implements BitsMap<T, V> {
  const ConstBitsMapBase([this.bits = const Bits.allZeros()]);
  ConstBitsMapBase.fromBase(BitsMap<T, V> state) : this(state.bits);

  @override
  final Bits bits;

  // the map operator will depend on the setter
  @override
  set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");
}

abstract class MutableBitsMapWithKeys<T extends BitsMapKey, V> extends MutableBitsMapBase<T, V> implements BitsMap<T, V> {
  MutableBitsMapWithKeys(this.keys, [super.bits]);
  MutableBitsMapWithKeys.fromBase(super.state)
      : keys = state.keys,
        super.fromBase();

  @override
  final List<T> keys;
}

@immutable
abstract class ConstBitsMapWithKeys<T extends BitsMapKey, V> extends ConstBitsMapBase<T, V> implements BitsMap<T, V> {
  const ConstBitsMapWithKeys(this.keys, [super.bits]);
  ConstBitsMapWithKeys.fromBase(super.state)
      : keys = state.keys,
        super.fromBase();

  @override
  final List<T> keys;
}

// mixin UnmodifiableBitsMixin<K extends Enum, V> on BitsMap<K, V> {
//   // @override
//   // set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");
//   // @override
//   // void operator []=(K key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
//   // @override
//   // void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");
// }

///// for cast of compile time const definition using map literal
/// BitField<EnumType> example = CastConstBitsMap({
///   EnumType.name1: 2,
///   EnumType.name2: 3,
/// });
// alternatively fold map use final instead of const

// // if T includes Bitmask in this module, bits can be defined here
// @override
// Bits get bits; //  by wrapping Map, this must be computed at run time
// @override
// int get width;
typedef ConstBitsMapInit<T extends Enum, V> = ConstEnumMapInit<T, V>;
// abstract class ConstBitsMapInit<T extends Enum, V> = ConstEnumMapInit<T, V> with BitsMap<T, V> implements BitsMap<T, V>;
