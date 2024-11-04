import 'package:cmdr_common/enum_map.dart';

import 'bits.dart';
export 'bits.dart';
// export 'package:flutter/foundation.dart' hide BitField;

/// [BitField] - key to BitFields
/// A List of [BitField], can be cast to either struct subtype
/// BitsKey
// mixin class BitFieldKey implements Bitmask {
abstract mixin class BitField implements Enum {
  Bitmask get bitmask;

//   // this allows BitMap to be use independently of BitField and BoolStruct
//   // V valueFrom(covariant BitsMap<BitsMapKey<V>, V> map);
  // int valueOf(BitsBase byteData) =>  ;
  // void setValueOf(BitsBase byteData, int value) =>  ;
  // int? valueOrNullOf(BitsBase byteData) =>  ;
}

// alternatively as key and entry
// typedef BitFieldEntry<K extends BitField> = MapEntry<K, int>;
// typedef BitField<K extends BitsKey> = MapEntry<K, int>;

// mixin for creation with 1 set of keys
abstract mixin class BoolField implements BitField {
  Bitmask get bitmask => Bitmask.index(index);
}

/// alternatively BitFieldKey implements Bitmask
extension BitFieldTypeMethods on Iterable<BitField> {
  Bitmasks get bitmasks => map((e) => e.bitmask) as Bitmasks;
}

extension BitFieldMapMethods on Map<BitField, int> {
  Iterable<MapEntry<Bitmask, int>> get bitsEntries => entries.map((e) => MapEntry(e.key.bitmask, e.value));
}

// // Type/Class/Factory
// extension type const BitFieldsClass<T extends BitField>(List<T> keys) implements List<BitField> {}

/// [BitFields]
/// `Bits Struct Base` base. BitsBase constrained with [EnumMap] - typed, fixed set, keys.
/// Common interface for [BitStruct], [BoolStruct]
/// A special case of [EnumMap], all values retrieve from a [Bits] object
/// implementations assign V type, [] operators, whether accessor use bitmask; derived or defined etc.
/// T is Enum / Bitmask
/// V is bool / int
/// Cast with any sub type of the same K Key type
abstract mixin class BitFields<K extends Enum, V> implements EnumMap<K, V>, BitsBase {
  const BitFields();

  // create a general bitsMap that can be cast later.
  // Map operators must not be accessed before casting
  // const factory BitFields([Bits bits]) = BitStruct;

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable
  int get width;

  // Map operators implemented by subclass depending on V type
  // alternatively use generic switch
  List<K> get keys;
  V operator [](covariant K key);
  void operator []=(covariant K key, V value);

  @override
  void clear() => bits = const Bits.allZeros();

  // @override
  BitFields<K, V> copyWithBits(Bits value);
  @override
  BitFields<K, V> copyWith() => copyWithBits(bits);

  @override
  String toString() => toStringAsMap(); // toString should be mapToString EnumMap

  String toStringAsMap() => MapBase.mapToString(this); // {key: value, key: value}
  String toStringAsBinary() => bits.toRadixString(2); // 0b000
  String toStringAsValues() => values.toString(); //  (0, 0, 0)
}

/// inheritable abstract constructors
abstract class MutableBitFieldsBase<T extends Enum, V> = MutableBitsBase with MapBase<T, V>, EnumMap<T, V>, BitFields<T, V>;
abstract class ConstBitFieldsBase<T extends Enum, V> = ConstBitsBase with MapBase<T, V>, EnumMap<T, V>, BitFields<T, V>;

abstract class MutableBitFieldsWithKeys<T extends Enum, V> extends MutableBitFieldsBase<T, V> {
  MutableBitFieldsWithKeys(this.keys, [super.bits]);
  MutableBitFieldsWithKeys.castBase(BitFields<T, V> super.state)
      : keys = state.keys,
        super.castBase();

  @override
  final List<T> keys;
}

@immutable
abstract class ConstBitFieldsWithKeys<T extends Enum, V> extends ConstBitFieldsBase<T, V> {
  const ConstBitFieldsWithKeys(this.keys, [super.bits]);
  ConstBitFieldsWithKeys.castBase(BitFields<T, V> super.state)
      : keys = state.keys,
        super.castBase();

  @override
  final List<T> keys;
}

// remove?
typedef ConstBitFieldsInit<T extends Enum, V> = ConstEnumMapInit<T, V>;
// class ConstBitsMapInit<T extends Enum, V> extends ConstEnumMapInit<T, V> with BitsMap<T, V> implements BitsMap<T, V>

/// combined mixins
// abstract class BitFieldsBase<K extends Enum, V> = EnumMapBase<K, V> with BitsBase, BitFields<K, V>;

// abstract class MutableBitFieldsBase<T extends Enum, V> extends MutableBitsBase with EnumMap<T, V>, BitFields<T, V> {
//   MutableBitFieldsBase([this.bits = const Bits.allZeros()]);
//   MutableBitFieldsBase.castBase(BitsBase state) : this(state.bits);

//   @override
//   Bits bits;

//   // @override
//   // MutableBitFieldsBase<T, V> copyWithBits(Bits value);
// }

// @immutable
// abstract class ConstBitFieldsBase<T extends Enum, V> extends BitFieldsBase<T, V> {
//   const ConstBitFieldsBase([this.bits = const Bits.allZeros()]);
//   ConstBitFieldsBase.castBase(BitsBase state) : this(state.bits);

//   @override
//   final Bits bits;

//   @override
//   int get width => bits.bitLength;

//   // the map operator will depend on the setter
//   @override
//   set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");
// }


// mixin UnmodifiableBitsMixin<K extends Enum, V> on BitsMap<K, V> {
//   // @override
//   // set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");
//   // @override
//   // void operator []=(K key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
//   // @override
//   // void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");
// }
