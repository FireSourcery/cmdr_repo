// ignore_for_file: annotate_overrides

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' as foundation show BitField; 

import 'bits.dart';
import 'bitmask.dart';

export 'bitmask.dart';


////////////////////////////////////////////////////////////////////////////////
/// operations on singular flag bits, using Enum Id
////////////////////////////////////////////////////////////////////////////////
abstract interface class BitFlags<T extends Enum> implements GenericBitField<T, bool>, foundation.BitField<T> {
  factory BitFlags.from(int width, [int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFlagsFromWidth<T>(width, bits),
      false => _UnmodifiableBitFlagsFromWidth<T>(width, bits),
    };
  }

  factory BitFlags.withEnums(List<T> names, [int bits = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFlagsWithEnums<T>(names, bits),
      false => _UnmodifiableBitFlagsWithEnums<T>(names, bits),
    };
  }

  factory BitFlags.fromFlags(Iterable<bool> flags, [bool mutable = true]) => BitFlags.from(flags.length, bitsOfIterable(flags), mutable);
  factory BitFlags.fromMap(Map<T, bool> map, [bool mutable = true]) => BitFlags.from(map.length, bitsOfMap(map), mutable);
  factory BitFlags.cast(BitFlags bitFlags, [bool mutable = true]) => BitFlags.from(bitFlags.width, bitFlags.value, mutable);

  // factory BitFlags.filled(int width, [bool? value]) => _MutableBitFlagsFromLength<T>(0, width);
  // const factory BitFlags.unmodifiable(int bits, int length) = _UnmodifiableBitFlagsFromLength;

  int get width;
  int get bits;
  set bits(int value);
  int get value;
  bool operator [](T indexed);
  void operator []=(T indexed, bool value);
  void reset([bool value = false]);
  Iterable<T> get memberKeys;
  Iterable<bool> get memberValues; // memberValues
  (T, bool) entry(T indexed); // memberKeyValue
  Iterable<(T, bool)> get entries;

  Iterable<bool> get asFlags;
  Iterable<int> get asBits;

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
  BitFlagsBase(this.bits);
  int bits;
  List<T> get memberKeys;
}

abstract class UnmodifiableBitFlagsBase<T extends Enum> extends _BitFlagsBase<T> with UnmodifiableBitsMixin<T, bool> implements BitFlags<T> {
  const UnmodifiableBitFlagsBase(this.bits);
  final int bits;
  List<T> get memberKeys;
}

abstract class _BitFlagsBase<T extends Enum> with BitFlagsMixin<T>, BitsBaseMixin<T, bool>, BitsNamesMixin<T, bool> implements BitFlags<T> {
  const _BitFlagsBase();
  @override
  List<T> get memberKeys;
  @override
  int get width => memberKeys.length;
}

////////////////////////////////////////////////////////////////////////////////
/// BitFlags Implementation
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitFlagsMixin<T extends Enum> implements BitFlags<T> {
  @override
  bool operator [](T indexed) {
    assert(indexed.index < width);
    return Bitmask.flagOf(bits, indexed.index);
  }

  @override
  void operator []=(T indexed, bool value) {
    assert(indexed.index < width);
    bits = Bitmask.modifyBit(bits, indexed.index, value);
  }

  bool flagAt(int index) => Bitmask.flagOf(bits, index);
  int bitAt(int index) => Bitmask.bitOf(bits, index);

  @override
  Iterable<bool> get asFlags => Iterable.generate(width, flagAt);
  @override
  Iterable<int> get asBits => Iterable.generate(width, bitAt);

  @override
  String toString() => '$runtimeType: $asBits';
}

////////////////////////////////////////////////////////////////////////////////
/// for constructor use
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// passing fixed width
////////////////////////////////////////////////////////////////////////////////
abstract class _BitFlagFromWidth<T extends Enum> with BitFlagsMixin<T>, BitsBaseMixin<T, bool> implements BitFlags<T> {
  const _BitFlagFromWidth(this.width);
  @override
  final int width;

  @override
  Iterable<T> get memberKeys => throw UnsupportedError("Use BitFlagsOnEnum");
  @override
  Iterable<bool> get memberValues => asFlags;
  @override
  (T, bool) entry(T indexed) => throw UnsupportedError("Use BitFlagsOnEnum");
  @override
  Iterable<(T, bool)> get entries => throw UnsupportedError("Use BitFlagsOnEnum");
}

class _MutableBitFlagsFromWidth<T extends Enum> extends _BitFlagFromWidth<T> implements BitFlags<T> {
  _MutableBitFlagsFromWidth(super.width, [this.bits = 0]);
  @override
  int bits;
}

class _UnmodifiableBitFlagsFromWidth<T extends Enum> extends _BitFlagFromWidth<T> with UnmodifiableBitsMixin<T, bool> implements BitFlags<T> {
  const _UnmodifiableBitFlagsFromWidth(super.width, this.bits);
  @override
  final int bits;
}

////////////////////////////////////////////////////////////////////////////////
/// passing enum list
////////////////////////////////////////////////////////////////////////////////
abstract class _BitFlagsWithEnums<T extends Enum> extends _BitFlagsBase<T> implements BitFlags<T> {
  const _BitFlagsWithEnums(this.memberKeys);
  @override
  final List<T> memberKeys;
}

class _MutableBitFlagsWithEnums<T extends Enum> extends _BitFlagsWithEnums<T> implements BitFlags<T> {
  _MutableBitFlagsWithEnums(super.memberNames, this.bits);
  @override
  int bits;
}

class _UnmodifiableBitFlagsWithEnums<T extends Enum> extends _BitFlagsWithEnums<T> with UnmodifiableBitsMixin<T, bool> implements BitFlags<T> {
  const _UnmodifiableBitFlagsWithEnums(super.memberNames, this.bits);
  @override
  final int bits;
}
