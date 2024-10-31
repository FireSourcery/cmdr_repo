import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

extension type const Bits(int _bits) implements int {
  const Bits.allOnes() : _bits = -1;
  const Bits.allZeros() : _bits = 0;

  // general Bits case
  Bits.ofFields(Iterable<(Bitmask, int)> pairs, [Bits initial = const Bits.allZeros()]) : _bits = const Bits.allZeros().withEach(pairs);

  // Iterable.generate assert(keys.length == values.length),
  Bits.ofIterables(Iterable<Bitmask> keys, Iterable<int> values) : this.ofFields(Iterable.generate(keys.length, (index) => (keys.elementAt(index), values.elementAt(index))));
  Bits.ofEntries(Iterable<MapEntry<Bitmask, int>> entries) : this.ofFields(entries.map((e) => (e.key, e.value)));
  Bits.ofMap(Map<Bitmask, int> map) : this.ofEntries(map.entries);

  // width value pairs
  // Bits.fromWidth(Iterable<(int width, int value)> pairs) : _bits = Bitmasks.fromWidths(pairs.keys).apply(map.values) as Bits;

  // general bool case
  Bits.ofIndexValues(Iterable<(int index, bool value)> flags) : _bits = const Bits.allZeros().withEachBool(flags);
  // using enum index, name is discarded
  Bits.ofIndexMap(Map<Enum, bool> map) : _bits = map.entries.fold<int>(0, (previous, entry) => previous.withBoolAt(entry.key.index, entry.value));
  Bits.ofIndexed(Iterable<bool> flags) : _bits = flags.foldIndexed<int>(0, (index, previous, element) => previous.withBoolAt(index, element)); // first element is index 0

  bool get isNotZero => (_bits != 0);
  bool get isZero => (_bits == 0);

  Bits getBits(Bitmask mask) => _bits.getBits(mask) as Bits;
  Bits withBits(Bitmask mask, int value) => _bits.withBits(mask, value) as Bits;

  Bits bitsAt(int offset, int width) => _bits.bitsAt(offset, width) as Bits;
  Bits withBitsAt(int offset, int width, int value) => _bits.withBitsAt(offset, width, value) as Bits;

  Bits bitAt(int index) => _bits.bitAt(index) as Bits;
  Bits withBitAt(int index, int value) => _bits.withBitAt(index, value) as Bits;

  Bits byteAt(int index) => _bits.byteAt(index) as Bits;
  Bits withByteAt(int index, int value) => _bits.withByteAt(index, value) as Bits;

  Bits bytesAt(int index, int size) => _bits.bytesAt(index, size) as Bits;
  Bits withBytesAt(int index, int size, int value) => _bits.withBytesAt(index, size, value) as Bits;

  bool boolAt(int index) => _bits.boolAt(index);
  Bits withBoolAt(int index, bool value) => _bits.withBoolAt(index, value) as Bits;

  Bits withEach(Iterable<(Bitmask mask, int value)> entries) => entries.fold<Bits>(this, (previous, element) => previous.withBits(element.$1, element.$2));
  Bits withEachBit(Iterable<(int index, int value)> entries) => entries.fold<Bits>(this, (previous, element) => previous.withBitAt(element.$1, element.$2));
  Bits withEachBool(Iterable<(int index, bool value)> entries) => entries.fold<Bits>(this, (previous, element) => previous.withBoolAt(element.$1, element.$2));

  // int operator [](int index) => bitAt(index);
  // void operator []=(int index, int value) => setBitAt(index, value);

  String toStringAsBits() => '0b${_bits.toRadixString(2)}';
}

// function of a single number, object methods over top level math functions
extension BinaryOfInt on int {
  int get byteLength => ((bitLength - 1) ~/ 8) + 1; // (bitLength / 8).ceil();

  // int clear(Bitmask mask) => this & ~mask._bitmask;
  // int read(Bitmask mask) => (this & mask._bitmask) >>> mask.shift;
  // int modify(Bitmask mask, int value) => clear(mask) | mask.apply(value);

  /// Bit operations
  int getBits(Bitmask mask) => mask.read(this);
  int withBits(Bitmask mask, int value) => mask.modify(this, value);

  int bitsAt(int offset, int width) => getBits(Bitmask.bits(offset, width));
  int withBitsAt(int offset, int width, int value) => withBits(Bitmask.bits(offset, width), value);

  int bitAt(int index) => getBits(Bitmask.bit(index));
  int withBitAt(int index, int value) => withBits(Bitmask.bit(index), value);

  // use bitmask directly skip TypedData buffer
  int bytesAt(int index, int size) => getBits(Bitmask.bytes(index, size));
  int withBytesAt(int index, int size, int value) => withBits(Bitmask.bytes(index, size), value);

  int byteAt(int index) => getBits(Bitmask.byte(index));
  int withByteAt(int index, int value) => withBits(Bitmask.byte(index), value);

  // let flags optimize slightly as special case
  bool boolAt(int index) => (this & (1 << index)) != 0;
  int withBoolAt(int index, bool value) => value ? (this | (1 << index)) : (this & ~(1 << index));

  /// pow2 only
  int alignDown(int align) => (this & (-align));
  int alignUp(int align) => (-(-this & (-align)));
  bool isAligned(int align) => ((this & (align - 1)) == 0);
}

/// Bitmask
// int bitmask(int shift, int width) => ((1 << width) - 1) << shift;
// as storable object to use as key
class Bitmask {
  const Bitmask._(this._bitmask, this.shift, this.width);
  const Bitmask(this.shift, this.width) : _bitmask = ((1 << width) - 1) << shift;
  const Bitmask.bits(int shift, int width) : this(shift, width);
  const Bitmask.bit(int index) : this(index, 1);
  const Bitmask.bytes(int shift, int size) : this(shift * 8, size * 8);
  const Bitmask.byte(int index) : this(index * 8, 8);
  const Bitmask.index(int index) : this._(1 << index, index, 1); // can this optimize unused assignments?

  final int _bitmask;
  final int shift;
  final int width; // (_bitmask >> shift).bitLength;

  // Bits get maskBits => Bits(_bitmask);

  // move to Bits?
  int apply(int value) => (value << shift) & _bitmask; // get as masked
  int clear(int source) => source & ~_bitmask; // clear bits
  int read(int source) => (source & _bitmask) >>> shift; // get as shifted back
  int modify(int source, int value) => clear(source) | apply(value); // ready for write back

  // int operator *(int value) => ((value << shift) & _bitmask); // apply as compile time const??
  // int call(int value) => ((value << shift) & bits);
}

extension type const Bitmasks(Iterable<Bitmask> bitmasks) implements Iterable<Bitmask> {
  Bitmasks.fromWidths(Iterable<int> widths) : bitmasks = Iterable.generate(widths.length, (index) => Bitmask(widths.take(index).sum, widths.elementAt(index)));
}

extension BitmasksMethods on Iterable<Bitmask> {
  int get totalWidth => map((e) => e.width).sum;
}

// extension BitsMapMethods on Map<Bitmask, int> {
//   Bits asBits() => Bits.ofEntries(entries);
// }

abstract mixin class BitsKey {
  Bitmask get bitmask;

  int valueOf(BitsBase bitsBase) => bitsBase.get(bitmask);
  void setValueOf(BitsBase bitsBase, int value) => bitsBase.set(bitmask, value);
  // int? valueOrNullOf(BitsBase bitsBase) => bitsBase.get(bitmask);
}

/// [BitsBase]
/// Contain bits for setters
/// for classes backed by Bits
/// gives Bits a type for matching, distinguish from int
/// cast with any sub type
abstract mixin class BitsBase {
  // const BitsBase();

  // create a general bitsMap that can be cast later.
  const factory BitsBase([Bits bits]) = ConstBitsBase;

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable
  int get width;

  int get(Bitmask mask) => bits.getBits(mask);
  void set(Bitmask mask, int value) => bits = bits.withBits(mask, value);

  void setBitsAt(int offset, int width, int value) => bits = bits.withBitsAt(offset, width, value);
  void setBitAt(int index, int value) => bits = bits.withBitAt(index, value);
  void setBoolAt(int index, bool value) => bits = bits.withBoolAt(index, value);
  void setByteAt(int index, int value) => bits = bits.withByteAt(index, value);
  void setBytesAt(int index, int size, int value) => bits = bits.withBytesAt(index, size, value);
  void setEach(Iterable<(Bitmask mask, int value)> entries) => bits = bits.withEach(entries);

  void reset([bool fill = false]) => bits = fill ? const Bits.allOnes() : const Bits.allZeros();

  // Map operators implemented by subclass depending on V type
  // alternatively use generic switch
  // List<K> get keys;
  // V operator [](covariant K key);
  // void operator []=(covariant K key, V value);
  // @override
  // void clear() => bits = const Bits.allZeros();

  // as a special case for BitsMap, override this function for withX function to return as child type
  // if T includes Bitmask in this module, the optimized implementation with V as int can be defined here
  // @mustBeOverridden
  // @protected
  // BitsBase copyWithBits(Bits value);

  // @override
  // BitsBase copyWith() => copyWithBits(bits);

  @override
  bool operator ==(covariant BitsBase other) {
    if (identical(this, other)) return true;
    return other.bits == bits;
  }

  @override
  int get hashCode => bits.hashCode;
}

class MutableBitsBase with BitsBase {
  MutableBitsBase([this.bits = const Bits.allZeros()]);
  MutableBitsBase.castBase(BitsBase state) : this(state.bits);

  @override
  Bits bits;
  @override
  int get width => 64;

  // @override
  // MutableBitsBase copyWithBits(Bits value) => MutableBitsBase(value);
}

@immutable
class ConstBitsBase with BitsBase {
  const ConstBitsBase([this.bits = const Bits.allZeros()]);
  ConstBitsBase.castBase(BitsBase state) : this(state.bits);

  @override
  final Bits bits;
  @override
  set bits(Bits value) => throw UnsupportedError('Cannot modify unmodifiable');
  @override
  int get width => bits.bitLength;

  // @override
  // ConstBitsBase copyWithBits(Bits value) => ConstBitsBase(value);
}

/// for cast of compile time const definition using map literal
/// BitField<EnumType> example = ConstBitsInit({
///   EnumType.name1: 2,
///   EnumType.name2: 3,
/// });
///  mixin so user can extend it own class first
abstract mixin class ConstBitsBaseInit implements BitsBase {
  @protected
  Map<Bitmask, int> get source;

  @override
  Bits get bits => Bits.ofEntries(source.entries); //  by wrapping Map, this must be computed at run time

  @override
  int get width => source.keys.totalWidth;

  // @override
  // ConstBitsBase copyWithBits(Bits value) => ConstBitsBase(bits);
}

/// No type restriction on Keys, or include of Keys.
/// hence .values will not be available
/// Useful for capturing bits value to cast with keys later
/// cast as BitStruct or BoolStruct with keys
// abstract mixin class _BitsMap implements BitsBase, Map<Bitmask, int> {
//   const _BitsMap();

//   Bits get bits;
//   set bits(Bits value);

//   @override
//   int get width => 64;
//   @override
//   List<Bitmask> get keys => [];
//   @override
//   int operator [](covariant Bitmask key) => get(key);
//   @override
//   void operator []=(covariant Bitmask key, int value) => set(key, value);
//   @override
//   void clear() => bits = const Bits.allZeros();
//   @override
//   Never remove(Object? key) => throw UnsupportedError('BitsMap does not support remove');

//   @override
//   _BitsMap copyWithBits(Bits value);
// }

// // MutableBitsBase
// class BitsMap extends MapBase<Bitmask, int> with BitsBase, _BitsMap {
//   BitsMap([this.bits = const Bits.allZeros()]);

//   @override
//   Bits bits;

//   @override
//   BitsMap copyWithBits(Bits value) => BitsMap(value);
// }

// // ConstBitsBase
// @immutable
// class ConstBitsMap extends MapBase<Bitmask, int> with BitsBase, _BitsMap {
//   const ConstBitsMap([this.bits = const Bits.allZeros()]);

//   @override
//   final Bits bits;

//   @override
//   set bits(Bits value) => throw UnsupportedError('Cannot modify unmodifiable');

//   @override
//   ConstBitsMap copyWithBits(Bits value) => ConstBitsMap(value);
// }
