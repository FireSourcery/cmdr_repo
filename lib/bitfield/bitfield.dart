// ignore_for_file: annotate_overrides
import 'dart:collection';
import 'package:collection/collection.dart';

import 'bits.dart';
import 'bitmask.dart';

export 'bitmask.dart';

/// operations on a range of bits
abstract interface class BitField<T extends Bitmask> implements GenericBitField<T, int>, MapBase<T, int> {
  const BitField();

  factory BitField.from(int width, [int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFieldFromWidth(width, bits),
      false => _UnmodifiableBitFieldFromWidth(width, bits),
    };
  }

  const factory BitField.constant(int width, int bits) = _UnmodifiableBitFieldFromWidth;
  // const factory BitField.constantFromMap(int width, int bits) = _UnmodifiableBitFieldFromWidth;

  /// BitField example = BitField({
  ///   EnumType.name1: 2,
  ///   EnumType.name2: 3,
  /// });
  factory BitField.ofMap(Map<T, int> values, [bool mutable = true]) {
    return BitField.from(widthOf(values), valueOf(values), mutable);
  }

  factory BitField.fromMap(Map<Bitmask, int> values, [bool mutable = true]) {
    return BitField.from(widthOf(values), valueOf(values), mutable);
  }

  factory BitField.fromIterables(Iterable<int> width, Iterable<int> values, [bool mutable = true]) {
    return BitField.from(width.sum, valueOfIterables(width, values), mutable);
  }

  static int widthOf(Map<Bitmask, int> valueMap) => valueMap.keys.map((e) => e.width).sum;
  static int valueOf(Map<Bitmask, int> valueMap) => valueMap.keys.fold<int>(0, (previous, mask) => mask.modify(previous, valueMap[mask]!));
  static int valueOfIterables(Iterable<int> widths, Iterable<int> values) => Bitmasks.fromWidths(widths).valueOfIterable(values);

  int get width;
  int get value;
  set value(int value);

  int bitsAt(int index, int width);
  int setBitsAt(int index, int width, int value);
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
//   int get value;
//   set value(int value);
//   List<T> get keys; // using Enum.values
//   int get width;
abstract class BitFieldBase<T extends BitFieldMember> = Object with MapBase<T, int>, BitFieldMixin<T>, BitsBaseMixin<T, int>, BitsMap<T, int> implements BitField<T>;
abstract class ConstBitFieldBase<T extends BitFieldMember> = BitFieldBase<T> with UnmodifiableBitsMixin<T, int> implements BitField<T>;

// abstract class ConstBitFieldBase<T extends BitFieldMember> extends BitFieldBase<T> with UnmodifiableBitsMixin<T, int> implements BitField<T> {
//   const ConstBitFieldBase(this.bits);
//   @override
//   final int bits;

//   List<T> get memberKeys; // using Enum.values
//   int get width;
// }

// abstract class BitFieldBase<T extends BitFieldMember> with MapBase<T, int>, BitFieldMixin<T>, BitsBaseMixin<T, int>, BitsMap<T, int> implements BitField<T> {
//   const BitFieldBase();

//   int get value;
//   set value(int value);
//   List<T> get keys; // using Enum.values
//   int get width;
// }

///
abstract mixin class BitFieldMember implements Enum, Bitmask {
  Bitmask get bitmask;
  @override
  int operator *(int value) => bitmask(value);
  @override
  int get bits => bitmask.bits;
  @override
  int call(int value) => bitmask(value);
  @override
  int get offset => bitmask.offset;
  @override
  int get width => bitmask.width;
  @override
  int apply(int value) => bitmask.apply(value);
  @override
  int read(int source) => bitmask.read(source);
  @override
  int modify(int source, int value) => bitmask.modify(source, value);
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
/// only (index, width) based access
abstract class _BitFieldFromWidth<T extends Bitmask> with MapBase<T, int>, BitFieldMixin<T>, BitsBaseMixin<T, int>, BitsMap<T, int> implements BitField<T> {
  const _BitFieldFromWidth(this.width);
  @override
  final int width;

  @override
  List<T> get keys => throw UnsupportedError("Use extend BitFieldBase");
}

// potentially use value.bitLength over passing width
class _MutableBitFieldFromWidth<T extends Bitmask> extends _BitFieldFromWidth<T> implements BitField<T> {
  _MutableBitFieldFromWidth(super.width, this.value);
  @override
  int value;
}

class _UnmodifiableBitFieldFromWidth<T extends Bitmask> extends _BitFieldFromWidth<T> implements BitField<T> {
  const _UnmodifiableBitFieldFromWidth(super.width, this.value);
  @override
  final int value;
}

// class _ConstBitFieldFromMap<T extends Bitmasks, V> with BitFieldMixin<T>, BitsBaseMixin<T, V> implements GenericBitField<T, V> {
//   const _ConstBitFieldFromMap(this.map);

//   final Map<T, V> map;

//   @override
//   V? operator [](T key) => map[key];

//   @override
//   void operator []=(T key, V value) => throw UnsupportedError("Cannot modify unmodifiable");

//   @override
//   Iterable<T> get memberKeys => throw UnimplementedError();

//   @override
//   int get width => throw UnimplementedError();

//   @override
//   int get bits => throw UnimplementedError();
// }
