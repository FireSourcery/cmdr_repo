import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Bits - Bitwise operations on [int]
/// function of a single number, object methods over top level math functions
extension type const Bits(int _bits) implements int {
  const Bits.allOnes() : this(-1);
  const Bits.allZeros() : this(0);

  /// general case
  Bits.ofPairs(Iterable<(Bitmask, int)> pairs) : _bits = const Bits.allZeros().withEach(pairs);

  // Bits.ofIterables(Iterable<Bitmask> keys, Iterable<int> values)

  Bits.ofLists(List<Bitmask> keys, List<int> values) : this.ofPairs(Iterable.generate(keys.length, (index) => (keys.elementAt(index), values.elementAt(index))));
  // Iterable.generate assert(keys.length == values.length),
  Bits.ofEntries(Iterable<MapEntry<Bitmask, int>> entries) : this.ofPairs(entries.map((e) => (e.key, e.value)));
  Bits.ofMap(Map<Bitmask, int> map) : this.ofEntries(map.entries);

  // Bits.ofInitializer(Map<Bitmask, int> map) : this.ofEntries(map.entries);
  // Bits.ofBitsMap(Map<BitsKey, int> map) : this.ofEntries(map.bitsEntries);

  // width value pairs
  // Indexed waith pairs
  // Bits.ofWidthPairs(List<(int width, int value)> pairs) : this.ofIterables(Bitmasks.fromWidths(pairs.map((e) => e.$1)), pairs.map((e) => e.$2));

  // general bool case
  Bits.ofIndexPairs(Iterable<(int index, bool value)> pairs) : _bits = const Bits.allZeros().withEachBool(pairs);
  // using enum index, name is discarded
  Bits.ofIndexMap(Map<Enum, bool> map) : this.ofIndexPairs(map.entries.map((e) => (e.key.index, e.value)));
  Bits.ofIndexed(Iterable<bool> values) : _bits = values.foldIndexed<Bits>(0 as Bits, (index, previous, element) => previous.withBoolAt(index, element)); // first element is index 0

  /// Implementation
  /// let int cast to access
  // isSet
  bool get isNotZero => (_bits != 0);
  bool get isZero => (_bits == 0);

  // int _clear(int bitmask) => this & ~bitmask; // clear bits
  // int _fill(int bitmask) => this | bitmask; // fill bits
  // int _applyOff(int bitmask, int shift) => (this & bitmask) >>> shift; // get as shifted back
  // int _applyOn(int bitmask, int shift, int value) => (value << shift) & bitmask; // get as masked
  // int _modify(int bitmask, int shift, int value) => _clear(this) | _applyOn(bitmask, shift, value); // ready for write back

  // // int read(Bitmask mask) => _applyOff;
  // // int modify(Bitmask mask, int value) => _modify ;

  int getBits(Bitmask mask) => mask.applyOff(this);
  Bits withBits(Bitmask mask, int value) => mask.modify(this, value) as Bits;

  int bitsAt(int offset, int width) => getBits(Bitmask.bits(offset, width));
  Bits withBitsAt(int offset, int width, int value) => withBits(Bitmask.bits(offset, width), value);

  int bitAt(int index) => getBits(Bitmask.bit(index));
  Bits withBitAt(int index, int value) => withBits(Bitmask.bit(index), value);

  // use bitmask directly skip TypedData buffer
  int bytesAt(int index, int size) => getBits(Bitmask.bytes(index, size));
  Bits withBytesAt(int index, int size, int value) => withBits(Bitmask.bytes(index, size), value);

  int byteAt(int index) => getBits(Bitmask.byte(index));
  Bits withByteAt(int index, int value) => withBits(Bitmask.byte(index), value);

  // let flags optimize slightly as special case
  bool boolAt(int index) => (this & (1 << index)) != 0;
  Bits withBoolAt(int index, bool value) => (value ? (this | (1 << index)) : (this & ~(1 << index))) as Bits;

  /// withEach
  Bits withEach(Iterable<(Bitmask mask, int value)> entries) => entries.fold<Bits>(this, (previous, element) => previous.withBits(element.$1, element.$2));
  Bits withEachBit(Iterable<(int index, int value)> entries) => entries.fold<Bits>(this, (previous, element) => previous.withBitAt(element.$1, element.$2));
  Bits withEachBool(Iterable<(int index, bool value)> entries) => entries.fold<Bits>(this, (previous, element) => previous.withBoolAt(element.$1, element.$2));

  /// Pow2 only
  int alignDown(int align) => (this & -align);
  int alignUp(int align) => (-(-this & -align));
  bool isAligned(int align) => ((this & (align - 1)) == 0);

  String toStringAsBinary() => '0b${toRadixString(2)}';
}

extension BitsOfInt on int {
  Bits get bits => Bits(this); // asBits();
  int get byteLength => ((bitLength - 1) ~/ 8) + 1; // (bitLength / 8).ceil();
}

/// Bitmask
// as storable object to use as key
class Bitmask {
  const Bitmask._(this.bitmask, this.shift, this.width);
  const Bitmask(this.shift, this.width) : bitmask = ((1 << width) - 1) << shift;
  // int _bitmask(int shift, int width) => ((1 << width) - 1) << shift;

  const Bitmask.bits(int shift, int width) : this(shift, width);
  const Bitmask.bit(int index) : this(index, 1);
  const Bitmask.bytes(int shift, int size) : this(shift * 8, size * 8);
  const Bitmask.byte(int index) : this(index * 8, 8);
  const Bitmask.index(int index) : this._(1 << index, index, 1); // ideally inline unused assignments

  final int bitmask; // store compile time derived value
  final int shift;
  final int width; // (bitmask >>> shift).bitLength;

  // move to Bits?, for inheritance conveinience
  int clear(int source) => source & ~bitmask; // clear bits
  int fill(int source) => source | bitmask; // fill bits
  int applyOn(int value) => (value << shift) & bitmask; // get as masked
  int applyOff(int source) => (source & bitmask) >>> shift; // get as shifted back
  int modify(int source, int value) => clear(source) | applyOn(value); // ready for write back

  // int operator *(int value) => ((value << shift) & _bitmask); // apply as compile time const??
  // int call(int value) => (value & _bitmask);

  // int operator |(int value) => (value | bitmask); // fill bits
}

extension type const Bitmasks(Iterable<Bitmask> bitmasks) implements Iterable<Bitmask> {
  Bitmasks.fromWidths(Iterable<int> widths) : bitmasks = widths.mapIndexed((index, width) => Bitmask(widths.take(index).sum, width));
}

extension BitmasksMethods on Iterable<Bitmask> {
  int get totalWidth => map((e) => e.width).sum;
}

/// [BitsBase]/[BitData]/ - base for classes backed by Bits
///   contain bits for setters - Cannot be extension type
///     allows `pass by pointer`
///   gives Bits a type for matching, distinguish from int
///   cast with any sub type
///  use by BitsMap. BitsStuct, BoolMap, etc.
abstract base class BitsBase {
  const BitsBase();

  Bits get bits;
  set bits(Bits value); // only dependency for unmodifiable

  int get width;
  int get value => bits;

  // int operator [](Bitmask index) => bitAt(index);
  // void operator []=(Bitmask index, int value) => setBitAt(index, value);

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

/// base for Map or Struct
base class MutableBits extends BitsBase {
  MutableBits([this.bits = const Bits.allZeros()]);
  // MutableBits.castBase(BitsBase state) : this(state.bits);

  @override
  Bits bits;
  @override
  int get width => 64;
}

// although only MutableBits must wrap Bits, this way they both implement and derive the same interfaces
@immutable
base class ConstBits extends BitsBase {
  const ConstBits(this.bits);
  // const ConstBits.value(int bits) : this(bits as Bits);
  // ConstBits(int value) : this( );
  // ConstBits.castBase(BitsBase state) : this(state.bits);

  @override
  final Bits bits;
  @override
  set bits(Bits value) => throw UnsupportedError('Cannot modify unmodifiable');
  @override
  int get width => bits.bitLength;
}

// @immutable
// class BitsInitializer<K> with BitsBase {
//   const BitsInitializer(this._init);

//   final Map<Bitmask, int> _init;

//   @override
//   Bits get bits => Bits.ofMap(_init); // in order to init using const Map, bits must be derived at run time
//   @override
//   set bits(Bits value) => throw UnsupportedError('Cannot modify unmodifiable');

//   @override
//   int get width => _init.keys.map((e) => e.width).sum;
// }
