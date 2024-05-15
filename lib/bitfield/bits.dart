import 'dart:collection';

import 'bitmask.dart';

const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;
const int _smiBits = 62;
const int _allZeros = 0;
const int _allOnes = kMaxUnsignedSMI;

////////////////////////////////////////////////////////////////////////////////
/// BitsBaseInterface
////////////////////////////////////////////////////////////////////////////////
/// V is bool for Flags, int for Field
abstract interface class GenericBitField<T, V> implements MapBase<T, V> {
  const GenericBitField();

  int get width;

  int get value; // bits value
  set value(int newValue);

  int bitsAt(int index, int width);
  void setBitsAt(int index, int width, int value);
  bool bitAt(int index);
  void setBitAt(int index, bool newValue);

  void reset([bool value = false]);

  List<T> get keys; // using Enum.values
  V operator [](covariant T key);
  void operator []=(T key, V value);
  V? remove(covariant T key);
  void clear();

  Iterable<(T, V)> get pairs;
}

abstract class GenericBitFieldBase<T, V> with MapBase<T, V>, BitsMap<T, V>, BitsBase<T, V> implements GenericBitField<T, V> {
  const GenericBitFieldBase();

  int get value;
  List<T> get keys;
  V operator [](covariant T key);
  void operator []=(T key, V value);
}

// abstract class MutableBitFieldBase<T, V> extends GenericBitFieldBase<T, V> implements GenericBitField<T, V> {
//   MutableBitFieldBase(this.value);
//   @override
//   int value;
// }

// abstract class ConstBitFieldBase<T, V> extends GenericBitFieldBase<T, V> implements GenericBitField<T, V> {
//   const ConstBitFieldBase(this.value);
//   @override
//   final int value;
// }

// over map for const, inefficient otherwise
abstract class GenericBitFieldMapBase<T, V> extends GenericBitFieldBase<T, V> with UnmodifiableBitsMixin<T, V> implements GenericBitField<T, V> {
  const GenericBitFieldMapBase(this.valueMap, [List<T>? _keys]);
  final Map<T, V> valueMap;

  int get value;
  int get width;

  @override
  V operator [](covariant T key) => valueMap[key]!;

  @override
  List<T> get keys => throw UnsupportedError("Extend BitFieldBase");
}

////////////////////////////////////////////////////////////////////////////////
/// Component Mixins
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitsMap<T, V> implements MapBase<T, V>, GenericBitField<T, V> {
  const BitsMap();

  List<T> get keys;
  V operator [](covariant T key);
  void operator []=(T key, V value);

  @override
  void clear() => value = 0;
  @override
  V? remove(covariant T key) => throw UnsupportedError('EnumMap does not support remove operation');

  @override
  Iterable<(T, V)> get pairs => keys.map((e) => (e, this[e]));
}

abstract mixin class BitsBase<T, V> implements GenericBitField<T, V> {
  const BitsBase();

  int get value;

  @override
  set value(int newValue) => value = newValue;

  @override
  int bitsAt(int index, int width) => Bitmask(index, width).read(value);
  @override
  void setBitsAt(int index, int width, int newValue) => value = Bitmask(index, width).modify(value, newValue);

  @override
  bool bitAt(int index) => Bitmask.flagOf(value, index);
  @override
  void setBitAt(int index, bool newValue) => value = Bitmask.modifyBit(value, index, newValue);

  @override
  void reset([bool fill = false]) => value = fill ? _allOnes : _allZeros;

  @override
  String toString() => '$runtimeType: $values';

  @override
  bool operator ==(covariant GenericBitField<T, V> other) {
    if (identical(this, other)) return true;
    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

// alternatively declare field final
mixin UnmodifiableBitsMixin<T, V> implements GenericBitField<T, V> {
  @override
  set value(int value) => throw UnsupportedError("Cannot modify unmodifiable");
  @override
  void operator []=(T key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
  @override
  void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");
}
