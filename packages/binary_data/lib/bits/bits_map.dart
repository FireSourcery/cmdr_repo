import 'package:cmdr_common/enum_map.dart';

import "bit_struct.dart";
import "bool_struct.dart";

// export 'package:flutter/foundation.dart' hide BitField;

// EnumMapFactory<S extends EnumMap<K, V>, K extends EnumKey, V>

// union of BitStruct and BoolStruct
// extension type const BitFieldClass<S extends BitsMapMixin<K, V>, K extends BitField, V>(List<K> keys) implements EnumMapFactory<S, K, V> {
//   // BitFieldClass.union(List<Enum> keys) : this(keys);

//   // S castBase(EnumMap<K, V> state) => state as S;

//   BitsMapMixin resolve(BitsBase bitsBase) {
//     return switch (keys) {
//       List<BitsIndexKey>() => ConstBoolStructWithKeys<K>(keys, bitsBase.bits),
//       List<BitsKey>() => ConstBitStructMap<K>(keys, bitsBase.bits),
//     };
//   }
// }

// or put bitsmap ext with  bool and bits suport

// selection
// class BitStructMap<T extends BitField> = MutableBitsMap<T, int> with BitStruct<T>;
// class ConstBitStructMap<T extends BitField> = ConstBitsMap<T, int> with BitStruct<T>;
// class MutableBoolStructWithKeys<T extends Enum> = MutableBitsMap<T, bool> with BoolStruct<T>;
// class ConstBoolStructWithKeys<T extends Enum> = ConstBitsMap<T, bool> with BoolStruct<T>;

abstract interface class BitsMap<K extends Enum, V> implements EnumMap<K, V> {
  const BitsMap();
  // BitsMap.of(List<K> keys, [int bits = 0, bool mutable = true])
  // {
  //    switch(keys)
  //    {
  //        List<BitsIndexKey> : return MutableBoolStructWithKeys<K>(keys, Bits(bits));
  //        List<BitsKey> : return MutableBitStructMap<K>(keys, Bits(bits));
  //    }
  //   return switch (mutable) {
  //     true => MutableBoolStructWithKeys<K>(keys, Bits(bits)),
  //     false => ConstBoolStructWithKeys<K>(keys, Bits(bits)),
  //   };
  // }

  // const factory BitsMap.constant(int width, Bits bits);
  // const factory BitsMap.constInit(Map<K, V> initializer)
  // {
  //   return BitsMapInitalizer<K>(initializer);
  // }

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable

  int get width;

  // Map operators implemented by subclass depending on V type
  List<K> get keys;
  V operator [](covariant K key);
  void operator []=(covariant K key, V value);

  @override
  void clear() => bits = const Bits.allZeros();

  Iterable<({K key, bool value})> get fieldsAsBool;
  Iterable<({K key, int value})> get fieldsAsBits;
  // Iterable<int> get valuesAsBits;
  // Iterable<bool> get valuesAsBools;

  // as a special case for BitsMap, override this function for withX function to return as child type
  // by default, EnumMap would allocate a new array buffer and copy each value
  BitsMap<K, V> copyWithBits(Bits value);
  @override
  BitsMap<K, V> copyWith() => copyWithBits(bits);

  @override
  String toString() => toStringAsMap();

  String toStringAsMap() => MapBase.mapToString(this); // {key: value, key: value}
  String toStringAsBinary() => bits.toStringAsBinary(); // 0b000
  String toStringAsValues() => values.toString(); // (0, 0, 0)

  String toStringAs(String Function(MapEntry<K, V> entry) stringifier) => entries.fold('', (previousValue, element) => previousValue + stringifier(element));
}
