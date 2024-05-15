// ignore_for_file: annotate_overrides

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' as foundation show BitField;

import 'bits.dart';
import 'bitmask.dart';

export 'bitmask.dart';

////////////////////////////////////////////////////////////////////////////////
/// operations on singular flag bits, using Enum Id
/// or BoolField
////////////////////////////////////////////////////////////////////////////////
abstract interface class BitFlags<T extends Enum> implements GenericBitField<T, bool>, foundation.BitField<T> {
  factory BitFlags.from(int width, [int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFlagsFromWidth<T>(width, bits),
      false => _UnmodifiableBitFlagsFromWidth<T>(width, bits),
    };
  }

  const factory BitFlags.constant(int width, int bits) = _UnmodifiableBitFlagsFromWidth;

  factory BitFlags.fromFlags(Iterable<bool> flags, [bool mutable = true]) => BitFlags.from(flags.length, bitsOfIterable(flags), mutable);
  factory BitFlags.fromMap(Map<T, bool> map, [bool mutable = true]) => BitFlags.from(map.length, bitsOfMap(map), mutable);
  factory BitFlags.cast(BitFlags bitFlags, [bool mutable = true]) => BitFlags.from(bitFlags.width, bitFlags.value, mutable);

  int get width;
  int get value;
  set value(int value);
  bool flagAt(int index);
  void setFlagAt(int index, bool value);

  List<T> get keys;
  bool operator [](T key);
  void operator []=(T key, bool value);
  void reset([bool value = false]);
  bool? remove(covariant T key);
  void clear();

  Iterable<int> get valuesAsBits;
  Iterable<(T, bool)> get pairs;

  static int bitsOfMap(Map<Enum, bool> map) {
    int accumulate(int previous, Enum key) => Bitmask.modifyBit(previous, key.index, map[key]!);
    return map.keys.fold<int>(0, accumulate);
  }

  static int bitsOfIterable(Iterable<bool> flags) {
    int accumulate(int index, int previous, bool element) => element ? Bitmask.onBit(previous, index) : previous;
    return flags.foldIndexed<int>(0, accumulate);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// extendable with context of Enum.values base
////////////////////////////////////////////////////////////////////////////////
abstract class BitFlagsBase<T extends Enum> extends _BitFlagsBase<T> implements BitFlags<T> {
  BitFlagsBase(this.value);
  int value;
  List<T> get keys;
}

abstract class ConstBitFlagsBase<T extends Enum> extends _BitFlagsBase<T> with UnmodifiableBitsMixin<T, bool> implements BitFlags<T> {
  const ConstBitFlagsBase(this.value);
  final int value;
  List<T> get keys;
}

abstract class _BitFlagsBase<T extends Enum> with MapBase<T, bool>, BitFlagsMixin<T>, BitsBaseMixin<T, bool>, BitsMap<T, bool> implements BitFlags<T> {
  const _BitFlagsBase();
  @override
  List<T> get keys;
  @override
  int get width => keys.length;
}

////////////////////////////////////////////////////////////////////////////////
/// BitFlags Implementation
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitFlagsMixin<T extends Enum> implements BitFlags<T> {
  @override
  bool operator [](T key) {
    assert(key.index < width);
    return Bitmask.flagOf(value, key.index);
  }

  @override
  void operator []=(T key, bool newValue) {
    assert(key.index < width);
    value = Bitmask.modifyBit(value, key.index, newValue);
  }

  @override
  bool flagAt(int index) => Bitmask.flagOf(value, index);
  @override
  void setFlagAt(int index, bool newValue) => Bitmask.modifyBit(value, index, newValue);

  @override
  Iterable<int> get valuesAsBits => values.map((e) => e ? 1 : 0);
}

////////////////////////////////////////////////////////////////////////////////
/// Interface constructors implementation
////////////////////////////////////////////////////////////////////////////////
abstract class _BitFlagFromWidth<T extends Enum> with MapBase<T, bool>, BitsMap<T, bool>, BitsBaseMixin<T, bool>, BitFlagsMixin<T> implements BitFlags<T> {
  const _BitFlagFromWidth(this.width);
  @override
  final int width;

  @override
  List<T> get keys => throw UnsupportedError("Extend BitFlagsBase");
}

class _MutableBitFlagsFromWidth<T extends Enum> extends _BitFlagFromWidth<T> implements BitFlags<T> {
  _MutableBitFlagsFromWidth(super.width, [this.value = 0]);
  @override
  int value;
}

class _UnmodifiableBitFlagsFromWidth<T extends Enum> extends _BitFlagFromWidth<T> with UnmodifiableBitsMixin<T, bool> implements BitFlags<T> {
  const _UnmodifiableBitFlagsFromWidth(super.width, this.value);
  @override
  final int value;
}

// ////////////////////////////////////////////////////////////////////////////////
// /// passing enum list
// ////////////////////////////////////////////////////////////////////////////////
// abstract class _BitFlagsWithEnums<T extends Enum> extends _BitFlagsBase<T> implements BitFlags<T> {
//   const _BitFlagsWithEnums(this.keys);
//   @override
//   final List<T> keys;
// }

// class _MutableBitFlagsWithEnums<T extends Enum> extends _BitFlagsWithEnums<T> implements BitFlags<T> {
//   _MutableBitFlagsWithEnums(super.keys, this.value);
//   @override
//   int value;
// }

// class _UnmodifiableBitFlagsWithEnums<T extends Enum> extends _BitFlagsWithEnums<T> with UnmodifiableBitsMixin<T, bool> implements BitFlags<T> {
//   const _UnmodifiableBitFlagsWithEnums(super.keys, this.value);
//   @override
//   final int value;
// }
