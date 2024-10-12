import 'package:collection/collection.dart';

extension type const Bits(int _bits) implements int {
  const Bits.allOnes() : _bits = -1;
  const Bits.allZeros() : _bits = 0;

  // optionally include , [Bits initial = const Bits.allZeros()]
  // initializer map
  // general bits case
  Bits.ofPairs(Iterable<(Bitmask, int)> pairs) : _bits = const Bits.allZeros().withEach(pairs);
  Bits.ofIterables(Iterable<Bitmask> keys, Iterable<int> values)
      : assert(keys.length == values.length),
        _bits = const Bits.allZeros().withEach(Iterable.generate(keys.length, (index) => (keys.elementAt(index), values.elementAt(index))));

  Bits.ofEntries(Iterable<MapEntry<Bitmask, int>> entries) : this.ofPairs(entries.map((e) => (e.key, e.value)));
  Bits.ofMap(Map<Bitmask, int> map) : this.ofEntries(map.entries);

  // width value pairs
  // Bits.fromWidth(Iterable<(int, int)> width value pairs) : value = Bitmasks.fromWidths(map.keys).apply(map.values) as Bits;

  // general bool case
  Bits.ofBoolPairs(Iterable<(int index, bool value)> flags) : _bits = const Bits.allZeros().withEachBool(flags);

  // using enum index, name is discarded
  Bits.ofIndexMap(Map<Enum, bool> map) : _bits = map.entries.fold<int>(0, (previous, entry) => previous.withBoolAt(entry.key.index, entry.value));
  Bits.ofBools(Iterable<bool> flags) : _bits = flags.foldIndexed<int>(0, (index, previous, element) => previous.withBoolAt(index, element)); // first element is index 0

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
extension BinaryOfInt on int {
  int get byteLength => ((bitLength - 1) ~/ 8) + 1; // (bitLength / 8).ceil();

  /// Bit operations
  int getBits(Bitmask mask) => mask.read(this); // (this & mask._bitmask) >>> mask.shift;
  int withBits(Bitmask mask, int value) => mask.modify(this, value); // clear(source) | apply(value);

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
  bool boolAt(int index) => (this & (1 << index)) != 0; // (this >> index) & 1 == 1;
  int withBoolAt(int index, bool value) => value ? (this | (1 << index)) : (this & ~(1 << index));

  /// pow2 only
// int alignDown(int value, int align) => (value & (-align));
// int alignUp(int value, int align) => (-(-value & (-align)));
// bool isAligned(int value, int align) => ((value & (align - 1)) == 0);
}

/// Bitmask
// int bitmask(int shift, int width) => ((1 << width) - 1) << shift;
// as storable object to use as key
class Bitmask {
  const Bitmask(this.shift, this.width) : _bitmask = ((1 << width) - 1) << shift;
  const Bitmask.bits(int shift, int width) : this(shift, width);
  const Bitmask.bit(int index) : this.bits(index, 1); // 1 << index
  const Bitmask.bytes(int shift, int size) : this.bits(shift * 8, size * 8);
  const Bitmask.byte(int index) : this.bits(index * 8, 8);

  // can this optimize away unused assignments?
  // const Bitmask.bool(int index)
  //     : _bitmask = (1 << index),
  //       shift = 0,
  //       width = 1;

  final int _bitmask;
  final int shift;
  final int width; // (_bitmask >> shift).bitLength;

  // Bits get maskBits => Bits(_bitmask);

  // move to Bits?
  int apply(int value) => (value << shift) & _bitmask; // get as masked
  int clear(int source) => source & ~_bitmask; // clear bits
  int read(int source) => (source & _bitmask) >>> shift; // get as shifted back
  int modify(int source, int value) => clear(source) | apply(value); // ready for write back

  int operator *(int value) => ((value << shift) & _bitmask); // apply as compile time const??
  // int call(int value) => ((value << shift) & bits);
}

extension type const Bitmasks(Iterable<Bitmask> bitmasks) implements Iterable<Bitmask> {
  Bitmasks.fromWidths(Iterable<int> widths) : bitmasks = Iterable.generate(widths.length, (index) => Bitmask(widths.take(index).sum, widths.elementAt(index)));
}

extension BitmasksMethods on Iterable<Bitmask> {
  int get totalWidth => map((e) => e.width).sum;
  // assuming same ordering
  // Bits apply(Iterable<int> values) => values.foldIndexed<int>(0, (index, previous, value) => elementAt(index).modify(previous, value)) as Bits;
}

// contains Iterable<Bitmask> to fold itself. alternatively call with List<Bitmask>
// extension BitFieldMapMethods on Map<Bitmask, int> {
//   Bits get bits => Bits.ofEntries(entries);
// }
