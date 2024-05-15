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
abstract interface class BitFlags<T extends Enum> implements GenericBitField<T, bool>, foundation.BitField<T>, Map<T, bool> {
  factory BitFlags([int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFlagsFromValues<T>(32, bits),
      false => _ConstBitFlagsFromValues<T>(32, bits),
    };
  }

  factory BitFlags.from(int width, [int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFlagsFromValues<T>(width, bits),
      false => _ConstBitFlagsFromValues<T>(width, bits),
    };
  }

  const factory BitFlags.constant(int width, int bits) = _ConstBitFlagsFromValues;
  const factory BitFlags.constantMap(Map<T, bool> values) = ConstBitFlagsMap;

  factory BitFlags.fromFlags(Iterable<bool> flags, [bool mutable = true]) => BitFlags.from(flags.length, bitsOfIterable(flags), mutable);
  factory BitFlags.fromMap(Map<T, bool> map, [bool mutable = true]) => BitFlags.from(map.length, bitsOfMap(map), mutable);
  factory BitFlags.cast(BitFlags bitFlags, [bool mutable = true]) => BitFlags.from(bitFlags.width, bitFlags.value, mutable);

  int get width;
  int get value;
  set value(int value);
  bool bitAt(int index);
  void setBitAt(int index, bool value);

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
abstract class BitFlagsBase<T extends Enum> extends GenericBitFieldBase<T, bool> with BitFlagsMixin<T> implements BitFlags<T> {
  const BitFlagsBase();
  List<T> get keys;
  @override
  int get width => keys.length;
}

abstract class MutableBitFlagsBase<T extends Enum> extends BitFlagsBase<T> implements BitFlags<T> {
  MutableBitFlagsBase(this.value);
  int value;

  List<T> get keys;
}

abstract class ConstBitFlagsBase<T extends Enum> extends BitFlagsBase<T> with UnmodifiableBitsMixin<T, bool> implements BitFlags<T> {
  const ConstBitFlagsBase(this.value);
  final int value;

  List<T> get keys;
}

class ConstBitFlagsMap<T extends Enum> extends GenericBitFieldMapBase<T, bool> with BitFlagsMixin<T> implements BitFlags<T> {
  const ConstBitFlagsMap(super.valueMap);
  @override
  int get width => valueMap.length;
  @override
  int get value => BitFlags.bitsOfIterable(valueMap.values); // todo as ext
}

////////////////////////////////////////////////////////////////////////////////
/// BitFlags Implementation
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitFlagsMixin<T extends Enum> implements BitFlags<T> {
  // @override
  // int get width => keys.length; // override in from values case

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
  Iterable<int> get valuesAsBits => values.map((e) => e ? 1 : 0);
}

////////////////////////////////////////////////////////////////////////////////
/// Interface constructors implementation
////////////////////////////////////////////////////////////////////////////////
abstract class _BitFlagFromValues<T extends Enum> extends BitFlagsBase<T> implements BitFlags<T> {
  const _BitFlagFromValues(this.width);
  @override
  final int width;

  @override
  List<T> get keys => throw UnsupportedError("Extend BitFlagsBase");
}

class _MutableBitFlagsFromValues<T extends Enum> extends _BitFlagFromValues<T> implements BitFlags<T> {
  _MutableBitFlagsFromValues(super.width, [this.value = 0]);
  @override
  int value;
}

class _ConstBitFlagsFromValues<T extends Enum> extends _BitFlagFromValues<T> with UnmodifiableBitsMixin<T, bool> implements BitFlags<T> {
  const _ConstBitFlagsFromValues(super.width, this.value);
  @override
  final int value;
}
