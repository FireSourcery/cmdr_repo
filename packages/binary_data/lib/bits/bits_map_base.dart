import 'package:meta/meta.dart';
import 'package:type_ext/enum_map.dart';

import 'bits.dart';
// import 'bits_map.dart';
export 'bits.dart';
// export 'package:flutter/foundation.dart' hide BitField;

/// [BitsMapBase]
/// `Bits Struct Base` base. BitsBase constrained with [EnumMap] - typed, fixed set, keys.
/// Common interface for [BitStruct], [BoolStruct]. cast before use, analogous to num -> int, double
/// A special case of [EnumMap], all values retrieve from a [Bits] object
/// implementations assign V type, [] operators, whether accessor use bitmask; derived or defined etc.
/// T is Enum / Bitmask
/// V is bool / int
/// Cast with any sub type of the same K Key type
abstract mixin class BitsMapBase<K extends Enum, V> implements EnumMap<K, V>, BitsBase {
  const BitsMapBase();

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable

  int get width;

  // Map operators implemented by subclass depending on V type
  List<K> get keys;
  V operator [](covariant K key);
  void operator []=(covariant K key, V value);

  @override
  void clear() => bits = const Bits.allZeros();

  @override
  V remove(covariant K key);

  Iterable<({K key, bool value})> get fieldsAsBool;
  Iterable<({K key, int value})> get fieldsAsBits;
  // Iterable<int> get valuesAsBits;
  // Iterable<bool> get valuesAsBools;

  // as a special case for BitsMap, override this function for withX function to return as child type
  // by default, EnumMap would allocate a new array buffer and copy each value
  BitsMapBase<K, V> copyWithBits(Bits value);
  @override
  BitsMapBase<K, V> copyWith() => copyWithBits(bits);

  @override
  String toString() => toStringAsMap();

  String toStringAsMap() => MapBase.mapToString(this); // {key: value, key: value}
  String toStringAsValues() => values.toString(); // (0, 0, 0)

  String toStringAs(String Function(MapEntry<K, V> entry) stringifier) => entries.fold('', (previousValue, element) => previousValue + stringifier(element));
}

/// combined mixins
/// inheritable abstract constructors

// abstract class BitsMapBase<K extends Enum, V> = BitsBase with MapBase<K, V>, EnumMap<K, V>, BitsMapMixin<K, V>;
// internal use only, todo split struct and map
abstract class MutableBitsStructBase<T extends Enum, V> = MutableBits with MapBase<T, V>, EnumMap<T, V>, BitsMapBase<T, V>;
abstract class ConstBitsStructBase<T extends Enum, V> = ConstBits with MapBase<T, V>, EnumMap<T, V>, BitsMapBase<T, V>;

/// Maps contain Keys as final field
abstract class MutableBitsMap<T extends Enum, V> extends MutableBits with MapBase<T, V>, EnumMap<T, V>, BitsMapBase<T, V> {
  MutableBitsMap(this.keys, [super.bits]);
  MutableBitsMap.castBase(BitsMapBase<T, V> super.state)
      : keys = state.keys,
        super.castBase();

  @override
  final List<T> keys;
}

@immutable
abstract class ConstBitsMap<T extends Enum, V> extends ConstBits with MapBase<T, V>, EnumMap<T, V>, BitsMapBase<T, V> {
  const ConstBitsMap(this.keys, super.bits);
  ConstBitsMap.castBase(BitsMapBase<T, V> super.state)
      : keys = state.keys,
        super.castBase();

  // const ConstBitsMap.index(List<IndexField> this.keys, super.bits);

  @override
  final List<T> keys;
}

// remove?
// typedef ConstBitFieldsInit<T extends Enum, V> = ConstBitsMapInit<T, V>;
// class ConstBitsMapInit<T extends Enum, V> extends ConstEnumMapInit<T, V> with BitsMap<T, V> implements BitsMap<T, V>

// mixin UnmodifiableBitsMixin<K extends Enum, V> on BitsMap<K, V> {
//   // @override
//   // set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");
//   // @override
//   // void operator []=(K key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
//   // @override
//   // void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");
// }
