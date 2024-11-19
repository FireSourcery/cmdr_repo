import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
export 'package:meta/meta.dart';

/// Bits - Bitwise operations on [int]
extension type const Bits(int _bits) implements int {
  const Bits.allOnes() : _bits = -1;
  const Bits.allZeros() : _bits = 0;

  // general Bits case
  Bits.ofPairs(Iterable<(Bitmask, int)> pairs, [Bits initial = const Bits.allZeros()]) : _bits = const Bits.allZeros().withEach(pairs);

  // Iterable.generate assert(keys.length == values.length),
  Bits.ofIterables(Iterable<Bitmask> keys, Iterable<int> values) : this.ofPairs(Iterable.generate(keys.length, (index) => (keys.elementAt(index), values.elementAt(index))));
  Bits.ofEntries(Iterable<MapEntry<Bitmask, int>> entries) : this.ofPairs(entries.map((e) => (e.key, e.value)));
  Bits.ofMap(Map<Bitmask, int> map) : this.ofEntries(map.entries);

  // width value pairs
  Bits.ofWidthPairs(Iterable<(int width, int value)> pairs) : this.ofIterables(Bitmasks.fromWidths(pairs.map((e) => e.$1)), pairs.map((e) => e.$2));
  // Bits.ofBitsMap(Map<BitsKey, int> map) : this.ofEntries(map.bitsEntries);

  // general bool case
  Bits.ofIndexPairs(Iterable<(int index, bool value)> pairs) : _bits = const Bits.allZeros().withEachBool(pairs);
  // using enum index, name is discarded
  Bits.ofIndexMap(Map<Enum, bool> map) : this.ofIndexPairs(map.entries.map((e) => (e.key.index, e.value)));
  Bits.ofIndexed(Iterable<bool> values) : _bits = values.foldIndexed<int>(0, (index, previous, element) => previous.withBoolAt(index, element)); // first element is index 0

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
}

// function of a single number, object methods over top level math functions
extension BitFieldOfInt on int {
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

  /// Pow2 only
  int alignDown(int align) => (this & -align);
  int alignUp(int align) => (-(-this & -align));
  bool isAligned(int align) => ((this & (align - 1)) == 0);

  String toStringAsBinary() => '0b${toRadixString(2)}';
}

/// Bitmask, change to record?
// as storable object to use as key
class Bitmask {
// int bitmask(int shift, int width) => ((1 << width) - 1) << shift;
  const Bitmask._(this._bitmask, this.shift, this.width);
  const Bitmask(this.shift, this.width) : _bitmask = ((1 << width) - 1) << shift;
  const Bitmask.bits(int shift, int width) : this(shift, width);
  const Bitmask.bit(int index) : this(index, 1);
  const Bitmask.bytes(int shift, int size) : this(shift * 8, size * 8);
  const Bitmask.byte(int index) : this(index * 8, 8);
  const Bitmask.index(int index) : this._(1 << index, index, 1); // can this optimize unused assignments?

  final int _bitmask;
  final int shift;
  final int width; // (_bitmask >>> shift).bitLength;

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

/// [BitsBase]/[BitData]/ - base for classes backed by Bits
///   contain bits for setters - Cannot be extension type
///   gives Bits a type for matching, distinguish from int
///   cast with any sub type
///
abstract mixin class BitsBase {
  const BitsBase();

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable

  int get width;

  // @override
  // int operator [](dynamic key) => bits.getBits(key.bitmask);
  // @override
  // void operator []=(dynamic key, int value) => bits = bits.withBits(key.bitmask, value);

  int getBits(Bitmask mask) => bits.getBits(mask);

  void setBits(Bitmask mask, int value) => bits = bits.withBits(mask, value);
  void setBitsAt(int offset, int width, int value) => bits = bits.withBitsAt(offset, width, value);
  void setBitAt(int index, int value) => bits = bits.withBitAt(index, value);
  void setBoolAt(int index, bool value) => bits = bits.withBoolAt(index, value);
  void setByteAt(int index, int value) => bits = bits.withByteAt(index, value);
  void setBytesAt(int index, int size, int value) => bits = bits.withBytesAt(index, size, value);
  void setEach(Iterable<(Bitmask mask, int value)> entries) => bits = bits.withEach(entries);

  void reset([bool fill = false]) => bits = fill ? const Bits.allOnes() : const Bits.allZeros();

  String toStringAsBinary() => bits.toStringAsBinary(); // 0b000
  String toStringAsBits() => bits.toRadixString(2); // 000

  @override
  bool operator ==(covariant BitsBase other) {
    if (identical(this, other)) return true;
    return other.bits == bits;
  }

  @override
  int get hashCode => bits.hashCode;
}

class MutableBits with BitsBase {
  MutableBits([this.bits = const Bits.allZeros()]);
  MutableBits.castBase(BitsBase state) : this(state.bits);

  @override
  Bits bits;
  @override
  int get width => 64;
}

// although only MutableBits must wrap Bits, this way they both implement and derive the same interfaces
@immutable
class ConstBits with BitsBase {
  const ConstBits(this.bits);
  ConstBits.castBase(BitsBase state) : this(state.bits);

  @override
  final Bits bits;
  @override
  set bits(Bits value) => throw UnsupportedError('Cannot modify unmodifiable');
  @override
  int get width => bits.bitLength;
}
