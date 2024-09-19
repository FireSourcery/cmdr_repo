import 'package:collection/collection.dart';

extension type const Bits(int value) implements int {
  const Bits.zero() : value = 0;
  const Bits.allOnes() : value = -1;
  const Bits.allZeros() : value = 0;

  // using enum index, name is discarded
  Bits.ofIndexMap(Map<Enum, bool> map) : value = map.entries.fold<int>(0, (previous, entry) => previous.withBoolAt(entry.key.index, entry.value));
  Bits.ofBools(Iterable<bool> flags) : value = flags.foldIndexed<int>(0, (index, previous, element) => previous.withBoolAt(index, element)); // first element is index 0

  Bits.ofMap(Map<Bitmask, int> map) : this.ofEntries(map.entries);
  Bits.ofEntries(Iterable<MapEntry<Bitmask, int>> entries) : value = entries.fold<int>(0, (previous, element) => element.key.modify(previous, element.value));
  Bits.ofPairs(Iterable<(Bitmask, int)> pairs) : value = pairs.fold<int>(0, (previous, element) => element.$1.modify(previous, element.$2));

  // width value pairs
  // Bits.fromWidth(Iterable<(int, int)> map) : value = Bitmasks.fromWidths(map.keys).apply(map.values) as Bits;

  set value(int newValue) => value = newValue;

  bool get isNotZero => (value != 0);
  bool get isZero => (value == 0);

  void reset([bool fill = false]) => value = fill ? const Bits.allOnes() : const Bits.allZeros();

  Bits getBits(Bitmask mask) => value.getBits(mask) as Bits;
  Bits withBits(Bitmask mask, int value) => value.withBits(mask, value) as Bits;
  void setBits(Bitmask mask, int value) => this.value = withBits(mask, value);

  Bits bitsAt(int offset, int width) => value.bitsAt(offset, width) as Bits;
  Bits withBitsAt(int offset, int width, int value) => value.withBitsAt(offset, width, value) as Bits;
  void setBitsAt(int offset, int width, int value) => this.value = withBitsAt(offset, width, value);

  Bits bitAt(int index) => value.bitAt(index) as Bits;
  Bits withBitAt(int index, int value) => this.value.withBitAt(index, value) as Bits;
  void setBitAt(int index, int value) => this.value = withBitAt(index, value);

  bool boolAt(int index) => value.boolAt(index);
  Bits withBoolAt(int index, bool value) => this.value.withBoolAt(index, value) as Bits;
  void setBoolAt(int index, bool value) => this.value = withBoolAt(index, value);

  Bits byteAt(int index) => value.byteAt(index) as Bits;
  Bits withByteAt(int index, int value) => this.value.withByteAt(index, value) as Bits;
  void setByteAt(int index, int value) => this.value = withByteAt(index, value);

  Bits bytesAt(int index, int size) => value.bytesAt(index, size) as Bits;
  Bits withBytesAt(int index, int size, int value) => this.value.withBytesAt(index, size, value) as Bits;
  void setBytesAt(int index, int size, int value) => this.value = withBytesAt(index, size, value);

  int operator [](int index) => bitAt(index);
  void operator []=(int index, int value) => setBitAt(index, value);
}

// function of a single number, object methods over top level math functions
extension BinaryOfInt on int {
  int get byteLength => ((bitLength - 1) ~/ 8) + 1; // (bitLength / 8).ceil();

  /// Bit operations
  int getBits(Bitmask mask) => mask.read(this); // (this & mask._bitmask) >>> mask.shift;
  int withBits(Bitmask mask, int value) => mask.modify(this, value); // clear(source) | apply(value);

  int bitsAt(int offset, int width) => Bitmask.bits(offset, width).read(this);
  int withBitsAt(int offset, int width, int value) => Bitmask.bits(offset, width).modify(this, value);

  int bitAt(int index) => Bitmask.bit(index).read(this);
  int withBitAt(int index, int value) => Bitmask.bit(index).modify(this, value);

  // let flags optimize slightly as special case
  bool boolAt(int index) => (this & (1 << index)) != 0;
  int withBoolAt(int index, bool value) => (this & ~(1 << index)) | (value ? (1 << index) : 0); // ((value ? 1 : 0) << index);

  // use bitmask directly skip TypedData buffer
  int bytesAt(int index, int size) => Bitmask.bytes(index, size).read(this);
  int withBytesAt(int index, int size, int value) => Bitmask.bytes(index, size).modify(this, value);

  int byteAt(int index) => Bitmask.byte(index).read(this);
  int withByteAt(int index, int value) => Bitmask.byte(index).modify(this, value);
}

/// Bitmask
// int bitmask(int shift, int width) => ((1 << width) - 1) << shift;
// as storable object to use as key
class Bitmask {
  const Bitmask(this.shift, this.width) : _bitmask = ((1 << width) - 1) << shift;
  const Bitmask.bits(int shift, int width) : this(shift, width);
  const Bitmask.bit(int index) : this.bits(index, 1); // (1 << index);
  const Bitmask.bytes(int shift, int size) : this.bits(shift * 8, size * 8);
  const Bitmask.byte(int index) : this.bits(index * 8, 8);

  final int _bitmask;
  final int shift;
  final int width; // (_bitmask >> shift).bitLength;

  // Bits get bits => Bits(_bitmask);

  int apply(int value) => (value << shift) & _bitmask; // get as masked
  int clear(int source) => source & ~_bitmask; // clear bits
  int read(int source) => (source & _bitmask) >>> shift; // get as shifted back
  int modify(int source, int value) => clear(source) | apply(value); // ready for write back

  int operator *(int value) => ((value << shift) & _bitmask); // apply as compile time const??
  // int call(int value) => ((value << shift) & bits);
}

extension type Bitmasks(Iterable<Bitmask> bitmasks) implements Iterable<Bitmask> {
  Bitmasks.fromWidths(Iterable<int> widths) : bitmasks = Iterable.generate(widths.length, (index) => Bitmask(widths.take(index).sum, widths.elementAt(index)));
}

extension BitmasksMethods on Iterable<Bitmask> {
  int get totalWidth => map((e) => e.width).sum;
  // assuming same ordering
  Bits apply(Iterable<int> values) => values.foldIndexed<int>(0, (index, previous, value) => elementAt(index).modify(previous, value)) as Bits;
}
