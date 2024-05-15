// ignore_for_file: annotate_overrides
import 'dart:collection';
import 'package:collection/collection.dart';

import 'bits.dart';
import 'bitmask.dart';

export 'bitmask.dart';

/// operations on a range of bits
abstract interface class BitField<T extends Bitmask> implements GenericBitField<T, int>, Map<T, int> {
  factory BitField([int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFieldFromValues(32, bits),
      false => _ConstBitFieldFromValues(32, bits),
    };
  }

  factory BitField.from(int width, [int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFieldFromValues(width, bits),
      false => _ConstBitFieldFromValues(width, bits),
    };
  }

  const factory BitField.constant(int width, int bits) = _ConstBitFieldFromValues;
  const factory BitField.constantMap(Map<T, int> values) = ConstBitFieldMap;

  /// BitField example = BitField.ofMap({
  ///   EnumType.name1: 2,
  ///   EnumType.name2: 3,
  /// });
  factory BitField.ofMap(Map<T, int> values, [bool mutable = true]) {
    return BitField.from(widthOf(values), valueOf(values), mutable);
  }

  factory BitField.fromMap(Map<Bitmask, int> values, [bool mutable = true]) {
    return BitField.from(widthOf(values), valueOf(values), mutable);
  }

  factory BitField.fromIterables(Iterable<int> widths, Iterable<int> values, [bool mutable = true]) {
    return BitField.from(widths.sum, Bitmasks.fromWidths(widths).apply(values), mutable);
  }

  static int widthOf(Map<Bitmask, int> valueMap) => valueMap.keys.totalWidth;
  static int valueOf(Map<Bitmask, int> valueMap) => valueMap.keys.apply(valueMap.values);

  int get width;
  int get value;
  set value(int value);

  int bitsAt(int index, int width);
  void setBitsAt(int index, int width, int value);
  void reset([bool value = false]);

  List<T> get keys; // using Enum.values
  int operator [](T key);
  void operator []=(T key, int value);
  int? remove(covariant T key);
  void clear();

  Iterable<(T, int)> get pairs;
}

////////////////////////////////////////////////////////////////////////////////
/// extendable, with Enum.values
///  imposes an additional constraint on the type parameter
////////////////////////////////////////////////////////////////////////////////
abstract class BitFieldBase<T extends BitFieldMember> = GenericBitFieldBase<T, int> with BitFieldMixin<T> implements BitField<T>;

abstract class MutableBitFieldBase<T extends BitFieldMember> extends BitFieldBase<T> implements BitField<T> {
  MutableBitFieldBase(this.value);
  @override
  int value;

  List<T> get keys; // using Enum.values
  int get width;
}

abstract class ConstBitFieldBase<T extends BitFieldMember> extends BitFieldBase<T> with UnmodifiableBitsMixin<T, int> implements BitField<T> {
  const ConstBitFieldBase(this.value);
  @override
  final int value;

  List<T> get keys; // using Enum.values
  int get width;
}

/// user implement field keys with bitmask parameters
/// alternatively BitField implements Bitmask bitmaskOf(T key)
/// alternatively Enum specify only width, derive offset from order
///
abstract mixin class BitFieldMember implements Enum, Bitmask {
  Bitmask get bitmask;
  @override
  int get offset => bitmask.offset;
  @override
  int get width => bitmask.width;
  @override
  int operator *(int value) => bitmask * value;
  @override
  int apply(int value) => bitmask.apply(value);
  @override
  int read(int source) => bitmask.read(source);
  @override
  int modify(int source, int value) => bitmask.modify(source, value);
  // @override
  // int get width;
  // Bitmask get bitmask => Bitmask(index + fold(), width);
}

class ConstBitFieldMap<T extends Bitmask> extends GenericBitFieldMapBase<T, int> with BitFieldMixin<T> implements BitField<T> {
  const ConstBitFieldMap(super.valueMap);

  @override
  int get width => valueMap.keys.totalWidth;
  @override
  int get value => valueMap.keys.apply(values);
}

////////////////////////////////////////////////////////////////////////////////
/// BitField Implementation
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitFieldMixin<T extends Bitmask> implements BitField<T> {
  const BitFieldMixin();

  @override
  int operator [](T key) => key.read(value);
  @override
  void operator []=(T key, int newValue) => value = key.modify(value, newValue);
}

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
abstract class _BitFieldFromValues<T extends Bitmask> extends GenericBitFieldBase<T, int> with BitFieldMixin<T> implements BitField<T> {
  const _BitFieldFromValues(this.width);
  @override
  final int width;

  @override
  List<T> get keys => throw UnsupportedError("Extend BitFieldBase");
}

// potentially use value.bitLength over passing width
class _MutableBitFieldFromValues<T extends Bitmask> extends _BitFieldFromValues<T> implements BitField<T> {
  _MutableBitFieldFromValues(super.width, this.value);
  @override
  int value;
}

class _ConstBitFieldFromValues<T extends Bitmask> extends _BitFieldFromValues<T> implements BitField<T> {
  const _ConstBitFieldFromValues(super.width, this.value);
  @override
  final int value;
}
