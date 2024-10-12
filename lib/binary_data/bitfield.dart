import 'package:cmdr/common/enum_map.dart';

import 'bits_map.dart';
import 'bits.dart';

export 'bits.dart';

/// [Bits] + operators <Bitmask, int>
/// operations on a range of bits
///
abstract mixin class BitField<T extends BitFieldKey> implements BitsMap<T, int> {
  factory BitField(List<T> keys, [int value = 0, bool mutable = true]) {
    return switch (mutable) {
      true => MutableBitFieldWithKeys(keys, Bits(value)),
      false => ConstBitFieldWithKeys(keys, Bits(value)),
    };
  }

  const factory BitField.constant(List<T> keys, Bits bits) = ConstBitFieldWithKeys;
  // const factory BitField.constInitializer(Map<T, int> values) = ConstBitFieldMap;

  factory BitField.values(List<T> keys, Iterable<int> values, [bool mutable = true]) {
    return BitField(keys, Bits.ofIterables(keys.bitmasks, values), mutable);
  }

  /// initializer map
  /// BitField<EnumType> example = BitField.values(EnumType.values, {
  ///   EnumType.name1: 2,
  ///   EnumType.name2: 3,
  /// });
  /// this way updates to keys propagate
  factory BitField.valuesMap(List<T> keys, Map<T, int> map, [bool mutable = true]) {
    return BitField(keys, Bits.ofEntries(map.bitmaskEntries), mutable);
  }

  // factory BitField.cast(BitsMap<T, int> values ) => BitField(values.keys, values.bits, mutable);

  // defined by child class
  List<T> get keys; // using Enum.values
  Bits get bits;

  // override to optimize
  @override
  int get width => keys.bitmasks.totalWidth;

  // Map operators
  @override
  int operator [](T key) => bits.getBits(key.bitmask);
  @override
  void operator []=(T key, int value) => bits = bits.withBits(key.bitmask, value);

  @override
  BitField<T> copyWithBits(Bits value) => ConstBitFieldWithKeys<T>(keys, value);
  @override
  BitField<T> copyWith() => copyWithBits(bits);

  // by default, EnumMap would allocate a new array buffer and copy each value
  // alternatively implement in BitsMap, if bits.withBits<V> is implemented, where V is int or bool
  @override
  BitField<T> withField(T key, int value) => copyWithBits(bits.withBits(key.bitmask, value));
  @override
  BitField<T> withEntries(Iterable<MapEntry<T, int>> entries) => copyWithBits(bits.withEach(entries.map((e) => (e.key.bitmask, e.value))));
  @override
  BitField<T> withAll(Map<T, int> map) => withEntries(map.entries);
}

/// `BitFieldField`
/// user implement field keys with bitmask parameters
/// alternatively BitField implements Bitmask bitmaskOf(T Enum key)
abstract mixin class BitFieldKey implements Enum {
  Bitmask get bitmask;
}

// Keys list effectively define type and act as factory
// typedef BitFieldType<T extends BitFieldKey> = List<T>;

// not necessary in this class since Bits constructors can already be shared
extension type const BitFieldType<T extends BitFieldKey>(List<T> keys) implements EnumMapFactory<BitField<T>, T, int> {
  // EnumMapFactory<T, int> get _super => EnumMapFactory(keys);
  // BitField<T> create([BitField<T>? state]) => BitField(keys, state?.bits ?? 0);
  // BitField<T> fromValues(Iterable<int> values) => BitField(keys, keys.bitmasks.apply(values));
}

/// alternatively BitFieldKey implements Bitmask
extension BitFieldTypeMethods on List<BitFieldKey> {
  Bitmasks get bitmasks => map((e) => e.bitmask) as Bitmasks;
}

// extension type const BitFieldInitMap<T extends BitFieldKey>(Map<T, int> values) implements Map<T, int> {
// toBits() => Bits.ofEntries(entries.map((e) => MapEntry(e.key.bitmask, e.value)));
// }

extension BitFieldMapMethods on Map<BitFieldKey, int> {
  Iterable<MapEntry<Bitmask, int>> get bitmaskEntries => entries.map((e) => MapEntry(e.key.bitmask, e.value));
}

////////////////////////////////////////////////////////////////////////////////
/// extendable, with Enum.values
////////////////////////////////////////////////////////////////////////////////
// abstract class BitFieldBase<T extends BitFieldKey> = BitsMapBase<T, int> with BitField<T>;
abstract class MutableBitFieldBase<T extends BitFieldKey> = MutableBitsMapBase<T, int> with BitField<T>;
abstract class ConstBitFieldBase<T extends BitFieldKey> = ConstBitsMapBase<T, int> with BitField<T>;
// ignore: missing_override_of_must_be_overridden
class MutableBitFieldWithKeys<T extends BitFieldKey> = MutableBitsMapWithKeys<T, int> with BitField<T>;
// ignore: missing_override_of_must_be_overridden
class ConstBitFieldWithKeys<T extends BitFieldKey> = ConstBitsMapWithKeys<T, int> with BitField<T>;

/// constructor compile time constant by wrapping Map.
/// alternatively use final and compare using value
abstract class ConstBitFieldInit<T extends BitFieldKey> extends ConstBitsMapInit<T, int> with BitField<T> {
  const ConstBitFieldInit(super.source);

  @override
  int get width => source.keys.map((e) => e.bitmask).totalWidth;
  @override
  Bits get bits => Bits.ofEntries(source.entries.map((e) => MapEntry(e.key.bitmask, e.value)));

  @override
  set bits(Bits value) => throw UnsupportedError("Cannot modify unmodifiable");

  @override
  BitField<T> copyWith() => this;

  // @override
  // List<T> get keys => source.keys;
}
