import 'package:flutter/foundation.dart' as foundation show BitField;

import 'bits_map.dart';
import 'bits.dart';

export 'bits.dart';

////////////////////////////////////////////////////////////////////////////////
/// [Bits] + operators <Enum, bool>
/// operations on singular flag bits, using Enum Id
/// or BoolField
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitFlags<T extends Enum> implements foundation.BitField<T>, BitsMap<T, bool> {
  const BitFlags._();
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

  List<T> get keys;
  Bits get bits;

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
    bits = bits.withBoolAt(key.index, value);
  }

  @override
  BitFlags<T> copyWithBits(Bits bits) => ConstBitFlagsWithKeys<T>(keys, bits);
  @override
  BitFlags<T> copyWith() => copyWithBits(bits);

  @override
  BitFlags<T> withField(T key, bool value) => copyWithBits(bits.withBoolAt(key.index, value));
  @override
  BitFlags<T> withEntries(Iterable<MapEntry<T, bool>> entries) => copyWithBits(bits.withEachBool(entries.map((e) => (e.key.index, e.value))));
  @override
  BitFlags<T> withAll(Map<T, bool> map) => copyWithBits(Bits.ofBools(values));

  Iterable<int> get valuesAsBits => values.map((e) => e ? 1 : 0); //todo as general extension
  // Iterable<(T, bool)> get entriesAsBits => keys.map((key) => MapEntry(key, this[key] ? 1 : 0));
}

////////////////////////////////////////////////////////////////////////////////
/// extendable with context of Enum.values base
////////////////////////////////////////////////////////////////////////////////
abstract class MutableBitFlagsBase<T extends Enum> = MutableBitsMapBase<T, bool> with BitFlags<T>;
abstract class ConstBitFlagsBase<T extends Enum> = ConstBitsMapBase<T, bool> with BitFlags<T>;

// ignore: missing_override_of_must_be_overridden
class MutableBitFlagsWithKeys<T extends Enum> = MutableBitsMapWithKeys<T, bool> with BitFlags<T>;
// ignore: missing_override_of_must_be_overridden
class ConstBitFlagsWithKeys<T extends Enum> = ConstBitsMapWithKeys<T, bool> with BitFlags<T>;

abstract class ConstBitFlagsInit<T extends Enum> extends ConstBitsMapInit<T, bool> with BitFlags<T> {
  const ConstBitFlagsInit(super.source);

  @override
  Bits get bits => Bits.ofBoolPairs(source.entries.map((e) => (e.key.index, e.value)));

  @override
  set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");

  @override
  BitFlags<T> copyWith() => this;
}
