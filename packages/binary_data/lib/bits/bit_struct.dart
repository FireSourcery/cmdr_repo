import 'package:meta/meta.dart';

import 'package:binary_data/data/struct.dart';

import 'bit_field.dart';
import 'bits_map.dart';

export 'bit_field.dart';
export 'bits_map.dart';

////////////////////////////////////////////////////////////////////////////////
/// [BitStruct] — zero-cost keyed view over a [BitData] object.
///
/// [Bits] + [BitField] keys, [] operators, returning [int]
///
/// Extension type analogue of [Structure] for the bit domain.
/// Provides [Structure<K, int>] access via [BitField] keys over a [BitData].
/// The wrapped [BitData]'s storage is unchanged; all dispatch goes through
/// [BitField.getIn] / [BitField.setIn].
///
/// Wrap around [BitData] instead of Bits to pass mutable and immutable variants to BitData layer
/// extending [BitData] would need to handle mutable and immutable variants,
// or none mutable only, bitsmap handle buffer
////////////////////////////////////////////////////////////////////////////////
extension type const BitStruct<K extends BitField>(BitData bitData) implements BitData, Structure<K, int> {
  // unique in that the entire memory layout is known
  // can create a value without keys
  BitStruct.from(int value) : this(ConstBits(value as Bits));
  BitStruct.fromMap(Map<K, int> map) : this(ConstBits(Bits.ofMap(map.map((key, value) => MapEntry(key.bitmask, value)))));

  int get width => 64; // const version leading zero unknown, overwrite for field get

  BitStruct<K> withField(K key, int value) => bitData.withBits(key.bitmask, value) as BitStruct<K>;
  BitStruct<K> withFields(Iterable<BitFieldEntry<K>> fields) => bitData.withEach(fields.map((e) => (e.key.bitmask, e.value))) as BitStruct<K>;
  BitStruct<K> withMap(Map<K, int> map) => bitData.withEach(map.entries.map((e) => (e.key.bitmask, e.value))) as BitStruct<K>;
}

/// [BitForm] — zero-cost wrapper over a [List<K>] field schema.
/// Analogue of [StructForm] for the bit domain.
/// `BitForm<K>(K.values).cast(ConstBits(raw as Bits));`
extension type const BitForm<K extends BitField>(List<K> _fields) implements StructForm<K, int> {
  BitStruct<K> cast(BitData bitData) => BitStruct<K>(bitData);

  // alternatively BitField implements Bitmask
  Bitmasks get bitmasks => _fields.map((e) => e.bitmask) as Bitmasks;
  int get totalWidth => bitmasks.totalWidth;

  //   Bits mapValues(List<int> values) {
  //     if (length != values.length) throw ArgumentError('Values length ${values.length} does not match BitFields length $length');

  //     return Bits.ofPairs(mapIndexed((index, e) => (e.bitmask, values[index])));
  //   }
}

////////////////////////////////////////////////////////////////////////////////
/// [BitStructBase] — abstract base for user-defined bit struct subtypes.
/// Analogue of [StructureBase] for the bit domain.
///
/// Unlike [BitStruct] (which wraps an _external_ [BitData]), subclasses of
/// [BitStructBase] hold data directly in their own fields. [BitField.getIn] /
/// [BitField.setIn] receive [bitData] as the host object.
///
/// Mixes in [MapBase<K, int>], [BitFieldMap<K>], and [StructureBase<T, K, int>]
/// providing: Map operators, serialization via [toMap], value equality, and
/// immutable copy helpers via [withField] / [withEntries] / [withMap].
///
/// [data] returns [BitStruct<K>(bitData)] — a zero-cost wrapper around [bitData]
/// — so keyed access delegates through the same [Field]-based dispatch as [Structure].
///
/// caller compose compile time const  const BitStructBase(ConstBits(11))
////////////////////////////////////////////////////////////////////////////////
// abstract base class BitStructBase<T extends BitStructBase<T>> with MapBase<BitField, int>, BitFieldMap<BitField>, StructureBase<T, BitField, int> {
abstract base class BitStructBase<T extends BitStructBase<T, K>, K extends BitField> with MapBase<K, int>, StructureBase<T, K, int> {
  const BitStructBase(this.bitData);

  BitStructBase.from(int bits) : bitData = ConstBits(bits as Bits);
  const BitStructBase.withData(BitStruct<K> data) : this(data); // base for copy, copys value

  /// The underlying bit storage. enforced data implementation as direct field
  final BitData bitData;

  @override
  List<K> get keys;

  @override
  BitStruct<K> get data => bitData as BitStruct<K>;

  @override
  Bits get bits => bitData.bits;
  @override
  set bits(Bits value) => bitData.bits = value; // throws for ConstBits; works for MutableBits

  int get width => BitForm(keys).totalWidth;

  @override
  // Map<K, int> toMap() => BitsMap.of(keys, bits);
  Map<K, int> toMap() => _BitStruct(keys, BitData.constant(bits) as BitStruct<K>);

  //
  @override
  void clear() => bits = 0 as Bits; // only for mutable data, but no need to enforce here

  @override
  int remove(covariant K key) {
    final value = this[key];
    this[key] = 0;
    return value;
  }

  /// Returns an `immutable` instance with [value] as bits. Override to return subtype.
  // BitStructBase copyWithBits(Bits value) => _BitStruct(keys, BitData.constant(value));
  T copyWithData(covariant BitStruct<K> data);

  T withField(K key, int value) => copyWithData(data.withField(key, value));
  T withFields(Iterable<BitFieldEntry<K>> entries) => copyWithData(data.withFields(entries));
  T withMap(Map<K, int> map) => copyWithData(data.withMap(map));

  @override
  String toString() => toStringAsMap();

  String toStringAsMap() => MapBase.mapToString(this); // {key: 0, key: 0,}
  String toStringAsValues() => values.toString(); // (0, 0, 0)
  String toStringAsBinary() => bits.toStringAsBinary(); // 0b000

  MapEntry<String, int> toStringMapEntry([String? name]) => MapEntry<String, int>(name ?? K.toString(), bits); // {name: value}

  /// Bitfields compare by bits value only.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BitStructBase<T, K>) return false;
    return (other.bits == bits);
  }

  @override
  int get hashCode => keys.hashCode ^ bits.hashCode;
}

/// Concrete pair: keys passed in, immutable (uses [ConstBits]).
@immutable
base class _BitStruct<K extends BitField> extends BitStructBase<_BitStruct<K>, K> {
  const _BitStruct(this.keys, super.bitData);
  @override
  final List<K> keys;

  @override
  _BitStruct<K> copyWithData(covariant BitStruct<K> data) => _BitStruct(keys, ConstBits(data.bits) as BitStruct<K>);
}

// ///
// /// [BitsInitializer]
// /// compile time const definition using map literal
// /// implements [ConstBitStruct<K>] via base data of [const Map<T, int>]
// ///
// /// BitStruct<EnumType> example = BitsInitializer({
// ///   EnumType.name1: 2,
// ///   EnumType.name2: 3,
// /// });
// ///
// /// UserSubStruct extends BitsInitializer implements UserSuperStruct
// ///
// typedef _BitsInitializer<K extends BitField> = Map<K, int>;

// as mixin for initialize
// @immutable
// final class BitStructInitializer<T extends BitStructBase<T, K>, K extends BitField> with MapBase<K, int>, StructureBase<T, K, int> implements BitStructBase<T, K> {
//   const BitStructInitializer(this._init);
//   final _BitsInitializer<K> _init;

//   @override
//   BitData get bitData => CoStructure<K, int>(_init) as BitData;
//   @override
//   BitStruct<K> get data => throw UnimplementedError();
//   @override
//   List<K> get keys => throw UnimplementedError();
//   @override
//   int get width => throw UnimplementedError();
//   @override
//   T copyWithData(BitStruct<K> data) {}

//   @override
//   Bits get bits => throw UnimplementedError();
//   @override
//   int remove(covariant K key) => throw UnimplementedError();

//   @override
//   void clear() => throw UnimplementedError();

//   @override
//   String toStringAsMap() {
//     throw UnimplementedError();
//   }

//   @override
//   String toStringAsValues() {
//     throw UnimplementedError();
//   }

//   @override
//   MapEntry<String, int> toStringMapEntry([String? name]) {
//     throw UnimplementedError();
//   }
// }
