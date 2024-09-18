import 'dart:collection';
import 'package:cmdr/common/fixed_map.dart';

import 'bits.dart';

/// Special case of a [FixedMap], all values retrieve from a [Bits] object
/// T is Enum for Flags, Bitmask for Field
/// V is bool for Flags, int for Field
abstract mixin class BitsMap<K extends Enum, V> implements Map<K, V> {
// abstract mixin class BitsMap<K extends Enum, V> implements FixedMap<K, V> {
  const BitsMap();

  Bits get bits;
  set bits(Bits value);
  int get width;

  @override
  List<K> get keys;
  @override
  V operator [](covariant K key);
  @override
  void operator []=(covariant K key, V value);

  @override
  void clear() => bits = const Bits.allZeros();
  @override
  V? remove(covariant K key) => throw UnsupportedError('BitsMap does not support remove operation');

// todo include from EnumMap
  Iterable<(K, V)> get pairs => keys.map((e) => (e, this[e]));

  //analogous to indexedValues
  Iterable<({String name, V value})> get namedValues => keys.map((e) => (name: e.name, value: this[e]));

  @override
  String toString() => '$runtimeType: $values';

  @override
  bool operator ==(covariant BitsMap<K, V> other) {
    // bool operator ==(covariant BitsMap other) {
    if (identical(this, other)) return true;
    return other.bits == bits;
  }

  @override
  int get hashCode => bits.hashCode;

  // BitsMap<K, V> copyWith({Bits? bits});
}

/// combined mixins
abstract class BitsMapBase<K extends Enum, V> = MapBase<K, V> with BitsMap<K, V>;

// for cast of compile time const only, simplify define using map literal
// alternatively fold map use final instead of const
abstract class ConstBitsMap<T extends Enum, V> with MapBase<T, V>, BitsMap<T, V>, UnmodifiableBitsMixin {
  const ConstBitsMap(this.valueMap, [List<T>? _keys]);
  final Map<T, V> valueMap;
  @override
  Bits get bits;
  @override
  int get width;

  @override
  List<T> get keys => [...valueMap.keys];
  @override
  V operator [](covariant T key) => valueMap[key]!;
  @override
  void operator []=(T key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
}

mixin UnmodifiableBitsMixin {
  // @override
  set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");
  // @override
  // void operator []=(T key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
  // @override
  // void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");
}
