part of 'bits_map.dart';

/// [BoolMap]
///
abstract mixin class BoolMap<K extends dynamic> implements BitsMap<K, bool> {
  factory BoolMap.of(List<K> keys, [Bits bits]) = MutableBoolMap<K>;

  const factory BoolMap.constant(List<K> keys, Bits bits) = ConstBoolMap<K>;

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
}

class MutableBoolMap<K extends dynamic>(super.keys, [
  @override
  var Bits bits = const Bits.allZeros()]) extends BitsMap<K, bool> with BoolMap<K> {
  this : super._();

}

class const ConstBoolMap<K extends dynamic>(super.keys, 
  @override
  final Bits bits) extends BitsMap<K, bool> with BoolMap<K> {
  this : super._();

  @override
  set bits(Bits value) => throw UnsupportedError('ConstBoolMap.bits is read-only');
}
