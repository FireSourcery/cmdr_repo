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

  List<T> get keys;
  V operator [](covariant T key);
  void operator []=(covariant T key, V value);

  @override
  void clear() => bits = const Bits(0);
  @override
  V? remove(covariant T key) => throw UnsupportedError('BitsMap does not support remove operation');

  Iterable<(T, V)> get pairs => keys.map((e) => (e, this[e]));

  @override
  String toString() => '$runtimeType: $values';
}

/// combined mixins
abstract class BitsMapBase<T, V> with MapBase<T, V>, BitsMap<T, V> {
  const BitsMapBase();
  int get width;
  Bits get bits;
  set bits(Bits value);

  List<T> get keys;
  V operator [](covariant T key);
  void operator []=(T key, V value);

  // @override
  // bool operator ==(covariant BitsMap<T, V> other) {
  //   if (identical(this, other)) return true;
  //   return other.value == value;
  // }

  // @override
  // int get hashCode => value.hashCode;
}

// for cast of compile time const only
abstract class ConstBitsMap<T, V> with MapBase<T, V>, BitsMap<T, V>, UnmodifiableBitsMixin {
  const ConstBitsMap(this.valueMap, [List<T>? _keys]);
  final Map<T, V> valueMap;
  Bits get bits;
  int get width;

  @override
  V operator [](covariant T key) => valueMap[key]!;
  @override
  void operator []=(T key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
  @override
  List<T> get keys => [...valueMap.keys];
}

mixin UnmodifiableBitsMixin {
  // @override
  set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");
  // @override
  // void operator []=(T key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
  // @override
  // void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");
}

////////////////////////////////////////////////////////////////////////////////
/// BitsBaseInterface
////////////////////////////////////////////////////////////////////////////////
/// V is bool for Flags, int for Field
// abstract interface class GenericBits<T, V> implements Map<T, V> {
//   const GenericBits();

//   int get width; // max width

//   int get value; // bits value
//   set value(int newValue);

//   int bitsAt(int index, int width);
//   void setBitsAt(int index, int width, int value);
//   bool boolAt(int index);
//   void setBoolAt(int index, bool newValue);
//   int bitAt(int index);
//   void setBitAt(int index, int newValue);

//   void reset([bool value = false]);

//   List<T> get keys; // using Enum.values
//   V operator [](covariant T key);
//   void operator []=(T key, V value);
//   V? remove(covariant T key);
//   void clear();

//   Iterable<(T, V)> get pairs;
// }

// abstract class GenericMutableBitFieldBase<T, V> extends GenericBitFieldBase<T, V> {
//   GenericMutableBitFieldBase(this.value);
//   @override
//   int value;
// }

// abstract class GenericConstBitFieldBase<T, V> extends GenericBitFieldBase<T, V> {
//   const GenericConstBitFieldBase(this.value);
//   @override
//   final int value;
// }

// abstract mixin class BitFieldMap<T> implements MapBase<T, int>, Bits {
//   List<T> get keys;
//   int operator [](covariant T key);
//   void operator []=(covariant T key, int value);

//   @override
//   void clear() => value = 0;
//   @override
//   int? remove(covariant T key) => throw UnsupportedError('BitsMap does not support remove operation');

//   Iterable<(T, int)> get pairs => keys.map((e) => (e, this[e]));

//   @override
//   String toString() => '$runtimeType: $values';
// }
