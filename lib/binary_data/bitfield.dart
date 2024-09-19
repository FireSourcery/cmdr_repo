// ignore_for_file: annotate_overrides

import 'bits_map.dart';
import 'bits.dart';

export 'bits.dart';

/// [Bits] + operators <Bitmask, int>
/// operations on a range of bits
///  keeping T generic allows type checking, implements BitsMap<BitFieldMember, int> would not
abstract interface class BitField<T extends BitFieldMember> implements BitsMap<T, int> {
  factory BitField(List<T> keys, [int value = 0, bool mutable = true]) {
    return switch (mutable) {
      true => _MutableBitFieldWithKeys(keys, Bits(value)),
      false => _ConstBitFieldWithKeys(keys, Bits(value)),
    };
  }

  const factory BitField.constant(List<T> keys, Bits bits) = _ConstBitFieldWithKeys;
  // const factory BitField.constantMap(Map<T, int> values) = ConstBitFieldMap;

  /// initializer map
  /// BitField<EnumType> example = BitField.values(EnumType.values, {
  ///   EnumType.name1: 2,
  ///   EnumType.name2: 3,
  /// });
  /// this way updates to keys propagate
  factory BitField.valuesMap(List<T> keys, Map<T, int> map, [bool mutable = true]) {
    return BitField(keys, Bits.ofEntries(map.bitmaskEntries), mutable);
  }

  // changes to keys will not propagate
  // e.g. Enum.values updated
  factory BitField.values(List<T> keys, Iterable<int> values, [bool mutable = true]) {
    return BitField(keys, keys.apply(values), mutable);
  }

  // factory BitField.cast(List<T> keys, BitsMap<T, int> values, [bool mutable = true]) {
  //   return BitField(keys, values.bits, mutable);
  // }

  int get width;
  Bits get bits;

  List<T> get keys; // using Enum.values
  int operator [](covariant T key);
  void operator []=(covariant T key, int value);
  void clear();
  int? remove(covariant T key);
  Iterable<(T, int)> get pairs;
}

/// user implement field keys with bitmask parameters
/// alternatively BitField implements Bitmask bitmaskOf(T Enum key)
/// "BitFieldField"
abstract mixin class BitFieldMember implements Enum {
  Bitmask get bitmask;
}

extension BitFieldMemberMethods on List<BitFieldMember> {
  Bitmasks get bitmasks => map((e) => e.bitmask) as Bitmasks;

  int get totalWidth => bitmasks.totalWidth;
  Bits apply(Iterable<int> values) => bitmasks.apply(values);
}

extension BitFieldMapMethods on Map<BitFieldMember, int> {
  Iterable<MapEntry<Bitmask, int>> get bitmaskEntries => entries.map((e) => MapEntry(e.key.bitmask, e.value));
  Iterable<(Bitmask mask, int value)> get bitmaskPairs => entries.map((e) => (e.key.bitmask, e.value));
}

// copy using only keys
extension type BitFieldType<T extends BitFieldMember>(List<T> keys) {
  BitField<T> create([BitField<T>? state]) => BitField(keys, state?.bits ?? 0);
}

////////////////////////////////////////////////////////////////////////////////
/// extendable, with Enum.values
////////////////////////////////////////////////////////////////////////////////
abstract class BitFieldBase<T extends BitFieldMember> extends BitsMapBase<T, int> with BitFieldMixin<T> implements BitField<T> {
  const BitFieldBase();

  List<T> get keys; // using Enum.values
  int get width; // override to optimize
}

abstract class MutableBitFieldBase<T extends BitFieldMember> extends BitFieldBase<T> implements BitField<T> {
  MutableBitFieldBase(this.bits);
  factory MutableBitFieldBase.withKeys(List<T> keys, [Bits value]) = _MutableBitFieldWithKeys;

  @override
  Bits bits;
}

abstract class ConstBitFieldBase<T extends BitFieldMember> extends BitFieldBase<T> with UnmodifiableBitsMixin implements BitField<T> {
  const ConstBitFieldBase(this.bits); // inherited abstract constructor
  const factory ConstBitFieldBase.withKeys(List<T> keys, [Bits value]) = _ConstBitFieldWithKeys;
  // ConstBitFieldBase.cast(BitsMap<T, int> map) : bits = map.bits;

  @override
  final Bits bits;
}

/// constructor compile time constant by wrapping Map.
/// alternatively use final and compare using value
// class ConstBitFieldMap<T extends BitFieldMember> extends ConstBitsMap<T, int> implements BitField<T> {
//   const ConstBitFieldMap(super.valueMap);

//   @override
//   int get width => valueMap.keys.map((e) => e.bitmask).totalWidth;
//   @override
//   Bits get bits => Bits(valueMap.fold());
// }

////////////////////////////////////////////////////////////////////////////////
/// BitField Implementation
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitFieldMixin<T extends BitFieldMember> implements BitsMap<T, int>, BitField<T> {
  const BitFieldMixin();

  @override
  int get width => keys.map((e) => e.bitmask).totalWidth;

  // Map operators
  @override
  int operator [](T key) => bits.getBits(key.bitmask);
  @override
  void operator []=(T key, int value) => bits.setBits(key.bitmask, value);

  // copyWith base
  // use withKeys or abstract method holding child caster, effectively assigns keys
  // BitField<T> createWith(BitField<T> state); //also required for a general serializer
  BitField<T> copyWith({Bits? bits}) => BitField.constant(keys, bits ?? this.bits);
  BitField<T> copyWithState(BitsMap<T, int> state) => copyWith(bits: state.bits);

  BitField<T> copyWithEntry(T key, int value) => copyWith(bits: bits.withBits(key.bitmask, value));
  // a hash map need to be copied by iterating each field, must be of the same keys
  BitField<T> copyWithMap(Map<T, int> map) => copyWith(bits: Bits.ofEntries(map.bitmaskEntries));

  S withEntry<S extends BitField<T>>(T key, int value) => copyWithEntry(key, value) as S;
  S withMap<S extends BitField<T>>(Map<T, int> map) => copyWithMap(map) as S;

  // BitField<T> fromJson(Map<String, dynamic> json) {
  //   if (json is Map<String, int>) {
  //     return copyWith(bits: FixedMapBuffer<T, int>(keys).fromMapByName<FixedMap<T, int>>(json) );
  //   } else {
  //     throw FormatException('WordFields.fromJson: $json is not of type Map<String, int>');
  //   }
  // }
}

class _MutableBitFieldWithKeys<T extends BitFieldMember> extends MutableBitFieldBase<T> implements BitField<T> {
  _MutableBitFieldWithKeys(this.keys, [super.bits = const Bits.allZeros()]) : super();
  final List<T> keys;
}

class _ConstBitFieldWithKeys<T extends BitFieldMember> extends ConstBitFieldBase<T> implements BitField<T> {
  const _ConstBitFieldWithKeys(this.keys, [super.bits = const Bits.allZeros()]) : super();
  final List<T> keys;
}
