// ignore_for_file: annotate_overrides

import 'bits.dart';
import 'bitmask.dart';

export 'bitmask.dart';

/// operations on a range of bits
// abstract interface class BitField<T extends Bitmask> implements GenericBitField<T, int> {
abstract interface class BitField<T extends Enum> implements GenericBitField<T, int> {
  const BitField();

  factory BitField.from(Bitmasks<T> bitmasks, [int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFieldFrom(bitmasks, bits),
      false => _UnmodifiableBitFieldFrom(bitmasks, bits),
    };
  }

  // factory BitField.fromMap(Map<T, Bitmask> bitmasks, [int bits = 0, bool mutable = true]) {
  //   return switch (mutable) {
  //     true => _MutableBitFieldFrom(Bitmasks.fromMap(bitmasks), bits),
  //     false => _UnmodifiableBitFieldFrom(Bitmasks.fromMap(bitmasks), bits),
  //   };
  // }

  factory BitField.fromWidths(Map<T, int> widthMap, [int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFieldFrom(Bitmasks.fromWidth(widthMap), bits),
      false => _UnmodifiableBitFieldFrom(Bitmasks.fromWidth(widthMap), bits),
    };
  }

  const factory BitField.unmodifiable(Bitmasks<T> bitmasks, int bits) = _UnmodifiableBitFieldFrom;

  // todo with extension type
  /// BitField example = BitField({
  ///   EnumType.name1: 2,
  ///   EnumType.name2: 3,
  /// });
  // factory BitField.fromValues({required Map<T, int> valuesMap, required Map<T, Bitmask> bitmasks,  bool mutable = true}) {}

  int get width;
  int get bits;
  set bits(int value);
  int get value;
  int operator [](T indexed);
  void operator []=(T indexed, int value);
  void reset([bool value = false]);
  Iterable<T> get memberKeys;
  Iterable<int> get memberValues;
  (T, int) entry(T indexed);
  Iterable<(T, int)> get entries;
}

// typedef BitFieldMembers<T extends Enum> = BitmasksBase<T>;

////////////////////////////////////////////////////////////////////////////////
/// extendable, with Enum.values + bitmaskOf(T key)
////////////////////////////////////////////////////////////////////////////////
///
/// user implements
/// Bitmask bitmaskOf(T key);
/// List<T> get memberKeys; // using Enum.values
/// int get width;
abstract class BitFieldBase<T extends Enum> = BitField<T> with BitFieldMixin<T>, BitsBaseMixin<T, int>, BitsNamesMixin<T, int>;
abstract class UnmodifiableBitFieldBase<T extends Enum> = BitFieldBase<T> with UnmodifiableBitsMixin<T, int> implements BitField<T>;

// abstract class BitFieldBase<T extends Enum> extends _BitFieldBase<T> implements BitField<T> {
//   BitFieldBase(this.bits);
//   @override
//   int bits;

//   // Bitmasks bitmasks; alternatively contain in masks
//   Bitmask bitmaskOf(T key);
//   List<T> get memberKeys; // using Enum.values
//   int get width;
// }

// abstract class UnmodifiableBitFieldBase<T extends Enum> extends _BitFieldBase<T> with UnmodifiableBitsMixin<T, int> implements BitField<T> {
//   const UnmodifiableBitFieldBase(this.bits);
//   @override
//   final int bits;

//   Bitmask bitmaskOf(T key);
//   List<T> get memberKeys; // using Enum.values
//   int get width;
// }

// abstract class _BitFieldBase<T extends Enum> with BitFieldMixin<T>, BitsBaseMixin<T, int>, BitsNamesMixin<T, int> implements BitField<T> {
//   const _BitFieldBase();
//   // Bitmasks get bitmasks;
//   // int get width;
// }

// alternatively if T implements mask and enum
// List<T> get memberKeys;
abstract class BitFieldBaseOnMembers<T extends BitFieldMember> extends BitFieldBase<T> implements BitField<T> {
  const BitFieldBaseOnMembers();
  Bitmask bitmaskOf(T key) => key;
}

////////////////////////////////////////////////////////////////////////////////
/// BitField Implementation
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitFieldMixin<T extends Enum> implements BitField<T> {
  const BitFieldMixin();
  Bitmask bitmaskOf(T key); // alternatively T extends BitFieldMember
  // Bitmasks get bitmasks;

  // @override
  // List<T> get memberKeys => bitmasks.memberKeys;
  // @override
  // int get width => bitmasks.width;

  int bitsAt(int index, int width) => Bitmask(index, width).read(bits);
  int bitsRange(int start, int end) => Bitmask(start, end - 1).read(bits);

  @override
  int operator [](T key) => bitmaskOf(key).read(bits);

  @override
  void operator []=(T key, int value) => bits = bitmaskOf(key).modify(bits, value);
}

////////////////////////////////////////////////////////////////////////////////
/// passing masks
////////////////////////////////////////////////////////////////////////////////
abstract class _BitFieldFrom<T extends Enum> with BitFieldMixin<T>, BitsBaseMixin<T, int>, BitsNamesMixin<T, int> implements BitField<T> {
  const _BitFieldFrom(this.bitmasks);

  final Bitmasks<T> bitmasks;

  @override
  Bitmask bitmaskOf(T key) => bitmasks[key];
  @override
  Iterable<T> get memberKeys => bitmasks.memberKeys;
  @override
  int get width => bitmasks.totalWidth;
}

class _UnmodifiableBitFieldFrom<T extends Enum> extends _BitFieldFrom<T> with UnmodifiableBitsMixin<T, int> implements BitField<T> {
  const _UnmodifiableBitFieldFrom(super.bitmasks, this.bits);
  @override
  final int bits;
}

class _MutableBitFieldFrom<T extends Enum> extends _BitFieldFrom<T> implements BitField<T> {
  _MutableBitFieldFrom(super.bitmasks, [this.bits = 0]);
  @override
  int bits;
}
