part of 'bits_map.dart';

/// [BoolMap]
///
/// implements foundation.BitField<T>,
abstract mixin class BoolMap<K extends dynamic> implements BitsMap<K, bool> {
  const BoolMap._();

  factory BoolMap.of(List<K> keys, [Bits bits]) = MutableBoolMap<K>;

  const factory BoolMap.constant(List<K> keys, Bits bits) = ConstBoolMap<K>;

  // factory BoolMap(List<T> keys, [int bits = 0, bool mutable = true]) {
  //   assert(bits.bitLength < keys.length);
  //   return switch (mutable) {
  //     true => MutableBoolMapWithKeys<T>(keys, Bits(bits)),
  //     false => ConstBoolMapWithKeys<T>(keys, Bits(bits)),
  //   };
  // }

  // const factory BoolMap.constant(int width, Bits bits) = ConstBoolMapWithKeys;
  // const factory BoolMap.constInit(Map<T, bool> values) = ConstBoolMapMap;

  // factory BoolMap.fromFlags(Iterable<bool> flags, [bool mutable = true]) => BoolMap.from(flags.length, Bits.ofBools(flags), mutable);
  // factory BoolMap.fromMap(Map<T, bool> map, [bool mutable = true]) => BoolMap.from(map.length, Bits.ofIndexMap(map), mutable);

  // factory BoolMap.cast(BoolMap boolStruct, [bool mutable = true]) => BoolMap.from(boolStruct.width, boolStruct.bits, mutable);

  @override
  int get width => keys.length;

  @override
  bool operator [](K key) {
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

  @override
  Iterable<int> get valuesAsBits => values.map((e) => e ? 1 : 0);
  @override
  Iterable<bool> get valuesAsBools => values;
  @override
  Iterable<MapEntry<K, int>> get entriesAsBits => keys.map((key) => MapEntry(key, this[key] ? 1 : 0));
  @override
  Iterable<MapEntry<K, bool>> get entriesAsBools => keys.map((key) => MapEntry(key, this[key]));
  // @override
  // Iterable<({K key, int value})> get fieldsAsBits => keys.map((e) => (key: e, value: this[e] ? 1 : 0));
  // @override
  // Iterable<({K key, bool value})> get fieldsAsBool => keys.map((e) => (key: e, value: this[e]));
}

class MutableBoolMap<K extends dynamic> extends BitsMap<K, bool> with BoolMap<K> {
  MutableBoolMap(super.keys, [this.bits = const Bits.allZeros()]) : super._();

  @override
  Bits bits;
}

class ConstBoolMap<K extends dynamic> extends BitsMap<K, bool> with BoolMap<K> {
  const ConstBoolMap(super.keys, this.bits) : super._();

  @override
  final Bits bits;
  @override
  set bits(Bits value) => throw UnsupportedError('ConstBoolMap.bits is read-only');
}
