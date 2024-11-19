import 'package:type_ext/enum_map.dart';

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

abstract interface class BitsMap<K extends Enum, V> with MapBase<K, V> implements FixedMap<K, V> {
  //
// selection
// class BitStructMap<T extends BitField> = MutableBitsMap<T, int> with BitStruct<T>;
// class ConstBitStructMap<T extends BitField> = ConstBitsMap<T, int> with BitStruct<T>;
// class MutableBoolStructWithKeys<T extends Enum> = MutableBitsMap<T, bool> with BoolStruct<T>;
// class ConstBoolStructWithKeys<T extends Enum> = ConstBitsMap<T, bool> with BoolStruct<T>;
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

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable

  int get width;

  // Map operators implemented by subclass depending on V type
  List<K> get keys;
  V operator [](covariant K key);
  void operator []=(covariant K key, V value);
  void clear() => bits = const Bits.allZeros();
  V remove(covariant K key);

  // Iterable<({K key, bool value})> get fieldsAsBool;
  // Iterable<({K key, int value})> get fieldsAsBits;
  Iterable<int> get valuesAsBits;
  Iterable<bool> get valuesAsBools;

  // as a special case for BitsMap, override this function for withX function to return as child type
  // by default, EnumMap would allocate a new array buffer and copy each value
  // BitsMap<K, V> copyWithBits(Bits value);
  // @override
  // BitsMap<K, V> copyWith() => copyWithBits(bits);

  // @override
  // String toString() => toStringAsMap();

  // String toStringAsMap() => MapBase.mapToString(this); // {key: value, key: value}
  // String toStringAsBinary() => bits.toStringAsBinary(); // 0b000
  // String toStringAsValues() => values.toString(); // (0, 0, 0)

  // String toStringAs(String Function(MapEntry<K, V> entry) stringifier) => entries.fold('', (previousValue, element) => previousValue + stringifier(element));
}

abstract interface class BoolMap<K extends Enum> extends BitsMap<K, bool> {
  const BoolMap._(this.keys);

  factory BoolMap.of(List<K> keys, [Bits bits]) = MutableBoolMap<K>;

  const factory BoolMap.constant(List<K> keys, Bits bits) = ConstBoolMap<K>;

  @override
  final List<K> keys;

  @override
  int get width => keys.length; // override in from values case

  @override
  bool operator [](K key) {
    // if(key is BitFieldKey) return  ;
    // if(key is Enum) return bits.boolAt(key.index);
    assert(key.index < width);
    return bits.boolAt(key.index);
  }

  @override
  void operator []=(K key, bool value) {
    assert(key.index < width);
    bits = bits.withBoolAt(key.index, value);
  }

  @override
  void clear() => bits = const Bits.allZeros();

  @override
  bool remove(K key) {
    final value = this[key];
    this[key] = false;
    return value;
  }

  // @override
  // Iterable<({K key, int value})> get fieldsAsBits => keys.map((e) => (key: e, value: this[e] ? 1 : 0));
  // @override
  // Iterable<({K key, bool value})> get fieldsAsBool => keys.map((e) => (key: e, value: this[e]));

  // Iterable<MapEntry<K, int>> get entriesAsBits => keys.map((key) => MapEntry(key, this[key] ? 1 : 0));

  @override
  Iterable<int> get valuesAsBits => values.map((e) => e ? 1 : 0);
  @override
  Iterable<bool> get valuesAsBools => values;
}

class MutableBoolMap<K extends Enum> extends BoolMap<K> {
  MutableBoolMap(super.keys, [this.bits = const Bits.allZeros()]) : super._();

  Bits bits;
}

class ConstBoolMap<K extends Enum> extends BoolMap<K> {
  const ConstBoolMap(super.keys, this.bits) : super._();

  final Bits bits;

  @override
  set bits(Bits value) => throw UnsupportedError('ConstBoolMap.bits is read-only');
}
