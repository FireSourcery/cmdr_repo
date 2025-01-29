import 'package:type_ext/index_map.dart';

import "bit_field.dart";

part 'bool_map.dart';

// export 'package:flutter/foundation.dart' hide BitField;

/// [BitsMap]

/// Common interface for [BitFieldMap, [BoolMap].
/// A special case of [FixedMap], all values retrieve from a [Bits] object
abstract interface class BitsMap<K, V> with MapBase<K, V>, FixedMap<K, V> {
  const BitsMap._(this.keys);

  factory BitsMap.of(List<K> keys, [int bits = 0, bool mutable = true]) {
    return switch (keys) {
      List<BitIndexField> keys => mutable ? MutableBoolMap(keys, Bits(bits)) : ConstBoolMap(keys, Bits(bits)),
      List<BitField> keys => mutable ? MutableBitFieldMap(keys, Bits(bits)) : ConstBitFieldMap(keys, Bits(bits)),
      List<Enum> keys => mutable ? MutableBoolMap(keys, Bits(bits)) : ConstBoolMap(keys, Bits(bits)),
      List<dynamic> keys when (keys.first.index == keys.first.index) => mutable ? MutableBoolMap(keys, Bits(bits)) : ConstBoolMap(keys, Bits(bits)),
      [...] => throw UnimplementedError(),
    } as BitsMap<K, V>;
  }

  // Map operators implemented by subclass depending on V type
  final List<K> keys;

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable

  // int get width;

  V operator [](covariant K key);
  void operator []=(covariant K key, V value);
  void clear() => bits = const Bits.allZeros();
  V remove(covariant K key);

  Iterable<int> get valuesAsBits;
  Iterable<bool> get valuesAsBools;
  Iterable<MapEntry<K, int>> get entriesAsBits;
  Iterable<MapEntry<K, bool>> get entriesAsBools;

  // Iterable<({K key, bool value})> get fieldsAsBool;
  // Iterable<({K key, int value})> get fieldsAsBits;
}

/// [BitFieldMap]
/// [BitsMapBase]
abstract mixin class BitFieldMap<K extends BitField> implements BitsMap<K, int> {
  const BitFieldMap._();

  factory BitFieldMap.of(List<K> keys, [Bits bits]) = MutableBitFieldMap<K>;

  const factory BitFieldMap.constant(List<K> keys, Bits bits) = ConstBitFieldMap<K>;

  List<K> get keys;
  Bits get bits;
  set bits(Bits value);

  // @override
  // int get width => keys.bitmasks.totalWidth;

  @override
  int operator [](covariant K key) => bits.getBits(key.bitmask);
  @override
  void operator []=(covariant K key, int value) => bits = bits.withBits(key.bitmask, value);
  @override
  void clear() => bits = const Bits.allZeros();
  @override
  int remove(K key) {
    final value = this[key];
    this[key] = 0;
    return value;
  }

  @override
  Iterable<int> get valuesAsBits => values;
  @override
  Iterable<bool> get valuesAsBools => values.map((e) => e != 0);
  @override
  Iterable<MapEntry<K, int>> get entriesAsBits => keys.map((key) => MapEntry(key, this[key]));
  @override
  Iterable<MapEntry<K, bool>> get entriesAsBools => keys.map((key) => MapEntry(key, this[key] != 0));
}

class MutableBitFieldMap<K extends BitField> extends BitsMap<K, int> with BitFieldMap<K> {
  MutableBitFieldMap(super.keys, [this.bits = const Bits.allZeros()]) : super._();

  @override
  Bits bits;
}

class ConstBitFieldMap<K extends BitField> extends BitsMap<K, int> with BitFieldMap<K> {
  const ConstBitFieldMap(super.keys, this.bits) : super._();

  @override
  final Bits bits;
  @override
  set bits(Bits value) => throw UnsupportedError('ConstBitFieldMap.bits is read-only');
}

// abstract interface class BitFieldEnum implements BitField, Enum {}

// extension BitFieldEnumMap on Map<BitFieldEnum, int> {
//   Map<String, Object> toJson() {
//     // by default returns keyed fields
//     // {
//     //   'fix': fix,
//     //   'minor': minor,
//     //   'major': major,
//     //   'optional': optional,
//     // }
//     return <String, Object>{
//       'name': name,
//       'value': bits,
//       'description': toStringAsVersion(),
//     };
//   }
// }
