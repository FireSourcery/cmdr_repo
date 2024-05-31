import 'dart:collection';
import 'bits.dart';

// a fixed map, Keys must be Enum for name string
// may not need to be shared
/// T is Enum for Flags, Bitmask for Field
/// V is bool for Flags, int for Field
abstract mixin class BitsMap<T, V> implements Map<T, V> {
  const BitsMap();

  Bits get bits;
  set bits(Bits value);

  @override
  List<T> get keys;
  @override
  V operator [](covariant T key);
  @override
  void operator []=(covariant T key, V value);

  @override
  void clear() => bits = const Bits(0);
  @override
  V? remove(covariant T key) => throw UnsupportedError('BitsMap does not support remove operation');

  Iterable<(T, V)> get pairs => keys.map((e) => (e, this[e]));

  @override
  String toString() => '$runtimeType: $values';

  @override
  bool operator ==(covariant BitsMap<T, V> other) {
    if (identical(this, other)) return true;
    return other.bits == bits;
  }

  @override
  int get hashCode => bits.hashCode;
}

/// combined mixins
abstract class BitsMapBase<T, V> with MapBase<T, V>, BitsMap<T, V> {
  const BitsMapBase();
  int get width;
  @override
  Bits get bits;
  @override
  set bits(Bits value);

  @override
  List<T> get keys;
  @override
  V operator [](covariant T key);
  @override
  void operator []=(T key, V value);
}

// for cast of compile time const only
abstract class ConstBitsMap<T, V> with MapBase<T, V>, BitsMap<T, V>, UnmodifiableBitsMixin {
  const ConstBitsMap(this.valueMap, [List<T>? _keys]);
  final Map<T, V> valueMap;
  int get width;
  @override
  Bits get bits;

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
