// ignore_for_file: annotate_overrides

import 'package:flutter/foundation.dart' as foundation show BitField;

import 'bits_map.dart';
import 'bits.dart';

export 'bits.dart';

////////////////////////////////////////////////////////////////////////////////
/// [Bits] + operators <Enum, bool>
/// operations on singular flag bits, using Enum Id
/// or BoolField
////////////////////////////////////////////////////////////////////////////////
abstract interface class BitFlags<T extends Enum> implements foundation.BitField<T>, BitsMap<T, bool> {
  // factory BitFlags(List<T> keys, [int bits = 0, bool mutable = true]) {
  //   return switch (mutable) {
  //     true => _MutableBitFlagsFromValues<T>(32, Bits(bits)),
  //     false => _ConstBitFlagsFromValues<T>(32, Bits(bits)),
  //   };
  // }

  // const factory BitFlags.constant(int width, Bits bits) = _ConstBitFlagsFromValues;
  // const factory BitFlags.constantMap(Map<T, bool> values) = ConstBitFlagsMap;

  // factory BitFlags.fromFlags(Iterable<bool> flags, [bool mutable = true]) => BitFlags.from(flags.length, Bits.ofBools(flags), mutable);
  // factory BitFlags.fromMap(Map<T, bool> map, [bool mutable = true]) => BitFlags.from(map.length, Bits.ofIndexMap(map), mutable);
  // factory BitFlags.cast(BitFlags bitFlags, [bool mutable = true]) => BitFlags.from(bitFlags.width, bitFlags.bits, mutable);

  int get width;
  Bits get bits;

  List<T> get keys;
  bool operator [](covariant T key);
  void operator []=(covariant T key, bool value);
  bool? remove(covariant T key);
  void clear();
  Iterable<(T, bool)> get pairs;

  Iterable<int> get valuesAsBits;
}

////////////////////////////////////////////////////////////////////////////////
/// extendable with context of Enum.values base
////////////////////////////////////////////////////////////////////////////////
abstract class BitFlagsBase<T extends Enum> extends BitsMapBase<T, bool> with BitFlagsMixin<T> implements BitFlags<T> {
  const BitFlagsBase();
  List<T> get keys;
}

abstract class MutableBitFlagsBase<T extends Enum> extends BitFlagsBase<T> implements BitFlags<T> {
  MutableBitFlagsBase(this.bits);
  @override
  Bits bits;
}

abstract class ConstBitFlagsBase<T extends Enum> extends BitFlagsBase<T> with UnmodifiableBitsMixin implements BitFlags<T> {
  const ConstBitFlagsBase(this.bits);
  @override
  final Bits bits;
}

// todo remove or fix
// class ConstBitFlagsMap<T extends Enum> extends ConstBitsMap<T, bool> with BitFlagsMixin<T> implements BitFlags<T> {
//   const ConstBitFlagsMap(super.valueMap);
//   @override
//   int get width => valueMap.length;
//   @override
//   Bits get bits => BitFlags.fromFlags(valueMap.values).bits;
// }

// extension on Map<Enum, bool> {
//   Bits toBits() => Bits.ofBools(values);
// }

////////////////////////////////////////////////////////////////////////////////
/// BitFlags Implementation
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitFlagsMixin<T extends Enum> implements BitsMapBase<T, bool>, BitFlags<T> {
  const BitFlagsMixin();

  @override
  int get width => keys.length; // override in from values case

  @override
  bool operator [](T key) {
    assert(key.index < width);
    return bits.boolAt(key.index);
  }

  @override
  void operator []=(T key, bool value) {
    assert(key.index < width);
    bits.value = bits.modifyBool(key.index, value);
  }

  @override
  Iterable<int> get valuesAsBits => values.map((e) => e ? 1 : 0);

  @override
  void reset([bool value = false]) => bits.reset(value);
}

////////////////////////////////////////////////////////////////////////////////
/// Interface constructors implementation
////////////////////////////////////////////////////////////////////////////////
// abstract class _BitFlagFromValues<T extends Enum> extends BitFlagsBase<T> implements BitFlags<T> {
//   const _BitFlagFromValues(this.width);
//   @override
//   final int width;

//   @override
//   List<T> get keys => throw UnsupportedError("Extend BitFlagsBase");
// }

// class _MutableBitFlagsFromValues<T extends Enum> extends _BitFlagFromValues<T> implements BitFlags<T> {
//   _MutableBitFlagsFromValues(super.width, [this.bits = const Bits(0)]);
//   @override
//   Bits bits;
// }

// class _ConstBitFlagsFromValues<T extends Enum> extends _BitFlagFromValues<T> with UnmodifiableBitsMixin implements BitFlags<T> {
//   const _ConstBitFlagsFromValues(super.width, this.bits);
//   @override
//   final Bits bits;
// }
