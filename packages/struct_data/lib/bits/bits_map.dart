import 'dart:collection';

import 'package:collection/collection.dart';

import '../general/index_map.dart';
import "bit_field.dart";

part 'bool_map.dart';

/// [BitsMap]
/// Common interface for [BitFieldMap, [BoolMap].
/// Enforce concrete keys as base.
/// A special case of [FixedMap], all values retrieve from a [Bits] object
/// Map operators implemented by subclass depending on V type, int or bool.
abstract interface class const BitsMap<K, V>._(@override final List<K> keys) with MapBase<K, V> implements Map<K, V> {
  factory BitsMap.of(List<K> keys, [int bits = 0, bool mutable = true]) {
    return switch (keys) {
      List<BitIndexField> keys => mutable ? MutableBoolMap(keys, Bits(bits)) : ConstBoolMap(keys, Bits(bits)),
      List<BitField> keys => mutable ? MutableBitFieldMap(keys, Bits(bits)) : ConstBitFieldMap(keys, Bits(bits)),
      List<Enum> keys => mutable ? MutableBoolMap(keys, Bits(bits)) : ConstBoolMap(keys, Bits(bits)),
      List<dynamic> keys when (keys.first.index == keys.first.index) => mutable ? MutableBoolMap(keys, Bits(bits)) : ConstBoolMap(keys, Bits(bits)),
      [...] => throw UnimplementedError(),
    } as BitsMap<K, V>;
  }

  Bits get bits;
  set bits(Bits value);

  @override
  V operator [](covariant K key);
  @override
  void operator []=(covariant K key, V value);
  @override
  void clear();
  @override
  V remove(covariant K key);
}

/// [BitFieldMap]
abstract mixin class BitFieldMap<K extends BitField> implements BitsMap<K, int> {
  factory BitFieldMap.of(List<K> keys, [Bits bits]) = MutableBitFieldMap<K>;

  const factory BitFieldMap.constant(List<K> keys, Bits bits) = ConstBitFieldMap<K>;

  int get width => keys.map((key) => key.bitmask).totalWidth;

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
}

class MutableBitFieldMap<K extends BitField>(super.keys, [@override var Bits bits = const Bits.allZeros()]) extends BitsMap<K, int> with BitFieldMap<K> {
  this : super._();
}

class const ConstBitFieldMap<K extends BitField>(super.keys, @override final Bits bits) extends BitsMap<K, int> with BitFieldMap<K> {
  this : super._();

  @override
  set bits(Bits value) => throw UnsupportedError('ConstBitFieldMap.bits is read-only');
}

extension BitFieldMapMethods<K extends BitField> on BitFieldMap<K> {
  Iterable<int> get valuesAsBits => values;
  Iterable<bool> get valuesAsBools => values.map((e) => e != 0);
  Iterable<MapEntry<K, int>> get entriesAsBits => keys.map((key) => MapEntry(key, this[key]));
  Iterable<MapEntry<K, bool>> get entriesAsBools => keys.map((key) => MapEntry(key, this[key] != 0));
  K get firstSet => entries.firstWhere((entry) => (entry.value != 0)).key;
  K? get firstSetOrNull => entries.firstWhereOrNull((entry) => (entry.value != 0))?.key;
}
