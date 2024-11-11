import 'package:cmdr_common/enum_map.dart';

import 'bits.dart';
export 'bits.dart';
// export 'package:flutter/foundation.dart' hide BitField;

/// [BitsMap]
/// `Bits Struct Base` base. BitsBase constrained with [EnumMap] - typed, fixed set, keys.
/// Common interface for [BitStruct], [BoolStruct]. cast before use, analogous to num -> int, double
/// A special case of [EnumMap], all values retrieve from a [Bits] object
/// implementations assign V type, [] operators, whether accessor use bitmask; derived or defined etc.
/// T is Enum / Bitmask
/// V is bool / int
/// Cast with any sub type of the same K Key type
abstract mixin class BitsMap<K extends Enum, V> implements EnumMap<K, V>, BitsBase {
  const BitsMap();

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable
  int get width;

  // Map operators implemented by subclass depending on V type
  List<K> get keys;
  V operator [](covariant K key);
  void operator []=(covariant K key, V value);

  @override
  void clear() => bits = const Bits.allZeros();

  BitsMap<K, V> copyWithBits(Bits value);
  @override
  BitsMap<K, V> copyWith() => copyWithBits(bits);

  @override
  String toString() => toStringAsMap(); // toString should be mapToString EnumMap

  String toStringAsMap() => MapBase.mapToString(this); // {key: value, key: value}
  String toStringAsBinary() => bits.toRadixString(2); // 0b000
  String toStringAsValues() => values.toString(); // (0, 0, 0)

  String toStringAs(String Function(MapEntry<K, V> entry) stringifier) => entries.fold('', (previousValue, element) => previousValue + stringifier(element));
}

/// combined mixins
/// inheritable abstract constructors

// abstract class BitFieldsBase<K extends Enum, V> = EnumMapBase<K, V> with BitsBase, BitFields<K, V>;

abstract class MutableBitFieldsBase<T extends Enum, V> = MutableBitsBase with MapBase<T, V>, EnumMap<T, V>, BitsMap<T, V>;
abstract class ConstBitFieldsBase<T extends Enum, V> = ConstBitsBase with MapBase<T, V>, EnumMap<T, V>, BitsMap<T, V>;

abstract class MutableBitFieldsWithKeys<T extends Enum, V> extends MutableBitFieldsBase<T, V> {
  MutableBitFieldsWithKeys(this.keys, [super.bits]);
  MutableBitFieldsWithKeys.castBase(BitsMap<T, V> super.state)
      : keys = state.keys,
        super.castBase();

  @override
  final List<T> keys;
}

@immutable
abstract class ConstBitFieldsWithKeys<T extends Enum, V> extends ConstBitFieldsBase<T, V> {
  const ConstBitFieldsWithKeys(this.keys, [super.bits]);
  ConstBitFieldsWithKeys.castBase(BitsMap<T, V> super.state)
      : keys = state.keys,
        super.castBase();

  @override
  final List<T> keys;
}

// remove?
// typedef ConstBitFieldsInit<T extends Enum, V> = ConstEnumMapInit<T, V>;
// class ConstBitsMapInit<T extends Enum, V> extends ConstEnumMapInit<T, V> with BitsMap<T, V> implements BitsMap<T, V>


 

// mixin UnmodifiableBitsMixin<K extends Enum, V> on BitsMap<K, V> {
//   // @override
//   // set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");
//   // @override
//   // void operator []=(K key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
//   // @override
//   // void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");
// }
