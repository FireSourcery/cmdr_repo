// ignore_for_file: annotate_overrides
import 'package:collection/collection.dart';

import 'bits_map.dart';
import 'bits.dart';
import 'bitmask.dart';

export 'bitmask.dart';

/// [Bits] + operators <Bitmask, int>
/// operations on a range of bits
abstract interface class BitField<T extends Bitmask> implements Map<T, int> {
  factory BitField([int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFieldFromValues(64, Bits(bits)),
      false => _ConstBitFieldFromValues(64, Bits(bits)),
    };
  }

  factory BitField.from(int width, [int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFieldFromValues(width, Bits(bits)),
      false => _ConstBitFieldFromValues(width, Bits(bits)),
    };
  }

  const factory BitField.constant(int width, Bits bits) = _ConstBitFieldFromValues;
  const factory BitField.constantMap(Map<T, int> values) = ConstBitFieldMap;

  /// BitField example = BitField.ofMap({
  ///   EnumType.name1: 2,
  ///   EnumType.name2: 3,
  /// });
  factory BitField.ofMap(Map<T, int> values, [bool mutable = true]) {
    return BitField.from(values.totalWidth, values.fold(), mutable);
  }

  factory BitField.fromMap(Map<Bitmask, int> values, [bool mutable = true]) {
    return BitField.from(values.totalWidth, values.fold(), mutable);
  }

  factory BitField.fromIterables(Iterable<int> widths, Iterable<int> values, [bool mutable = true]) {
    return BitField.from(widths.sum, Bitmasks.fromWidths(widths).apply(values), mutable);
  }

  int get width;
  Bits get bits;

  List<T> get keys; // using Enum.values
  int operator [](covariant T key);
  void operator []=(covariant T key, int value);
  void clear();
  int? remove(covariant T key);
  Iterable<(T, int)> get pairs;
}

////////////////////////////////////////////////////////////////////////////////
/// extendable, with Enum.values
///  imposes an additional constraint on the type parameter, or require BitmaskOf, or override map operators
////////////////////////////////////////////////////////////////////////////////
abstract class BitFieldBase<T extends BitFieldMember> = BitsMapBase<T, int> with BitFieldMixin<T> implements BitField<T>;
// abstract class MutableBitFieldBase<T extends BitFieldMember> = GenericMutableBitFieldBase<T, int> with BitFieldMixin<T> implements BitField<T>;
// abstract class ConstBitFieldBase<T extends BitFieldMember> = GenericConstBitFieldBase<T, int> with UnmodifiableBitsMixin<T, int> implements BitField<T>;

abstract class MutableBitFieldBase<T extends BitFieldMember> extends BitFieldBase<T> implements BitField<T> {
  MutableBitFieldBase(int bits) : bits = bits as Bits;
  @override
  Bits bits;

  List<T> get keys; // using Enum.values
  int get width;
}

abstract class ConstBitFieldBase<T extends BitFieldMember> extends BitFieldBase<T> with UnmodifiableBitsMixin implements BitField<T> {
  const ConstBitFieldBase(int bits) : bits = bits as Bits;
  @override
  final Bits bits;

  List<T> get keys; // using Enum.values
  int get width;
}

/// user implement field keys with bitmask parameters
/// alternatively BitField implements Bitmask bitmaskOf(T Enum key)
/// alternatively Enum specify only width, derive offset from order
/// "BitFieldField"
abstract mixin class BitFieldMember implements Enum, Bitmask {
  Bitmask get bitmask;

  @override
  int get shift => bitmask.shift;
  @override
  int get width => bitmask.width;
  @override
  int operator *(int value) => bitmask * value;
  @override
  int apply(int value) => bitmask.apply(value);
  @override
  int read(int source) => bitmask.read(source);
  @override
  int readSigned(int source) => bitmask.readSigned(source);
  @override
  int modify(int source, int value) => bitmask.modify(source, value);
  // @override
  // int get width;
  // Bitmask get bitmask => Bitmask(index + fold(), width);
}

class ConstBitFieldMap<T extends Bitmask> extends ConstBitsMap<T, int> implements BitField<T> {
  const ConstBitFieldMap(super.valueMap);

  // @override
  // V operator [](covariant T key) => valueMap[key]!;
  // @override
  // void operator []=(T key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
  // @override
  // List<T> get keys => throw UnsupportedError("Extend BitFieldBase");

  @override
  int get width => valueMap.totalWidth;
  @override
  Bits get bits => Bits(valueMap.fold());
}

////////////////////////////////////////////////////////////////////////////////
/// BitField Implementation
////////////////////////////////////////////////////////////////////////////////
/// Map operators
abstract mixin class BitFieldMixin<T extends Bitmask> implements BitsMapBase<T, int>, BitField<T> {
  const BitFieldMixin();

  /// alternatively if T is nto Bitmask
  /// Bitmask bitmaskOf(T key);

  @override
  int operator [](T key) => key.read(bits); // bitsAt(key.offset, key.width);
  @override
  void operator []=(T key, int newValue) => bits = Bits(key.modify(bits, newValue));

  // @override
  // void clear() => value = 0;
  // @override
  // int? remove(covariant T key) => throw UnsupportedError('BitsMap does not support remove operation');
  // Iterable<(T, int)> get pairs => keys.map((e) => (e, this[e]));
  // @override
  // String toString() => '$runtimeType: $values';
}

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
abstract class _BitFieldFromValues<T extends Bitmask> extends BitsMapBase<T, int> with BitFieldMixin<T> implements BitField<T> {
  const _BitFieldFromValues(this.width);
  @override
  final int width;

  @override
  List<T> get keys => throw UnsupportedError("Extend BitFieldBase");
}

class _MutableBitFieldFromValues<T extends Bitmask> extends _BitFieldFromValues<T> implements BitField<T> {
  _MutableBitFieldFromValues(super.width, this.bits);
  @override
  Bits bits;
}

class _ConstBitFieldFromValues<T extends Bitmask> extends _BitFieldFromValues<T> with UnmodifiableBitsMixin implements BitField<T> {
  const _ConstBitFieldFromValues(super.width, this.bits);
  @override
  final Bits bits;
}
