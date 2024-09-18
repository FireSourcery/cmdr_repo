import 'package:collection/collection.dart';

extension type const Bits(int value) implements int {
  const Bits.zero() : value = 0;
  const Bits.allOnes() : value = -1;
  const Bits.allZeros() : value = 0;

  // move to flags
  // using enum index, name is discarded
  Bits.ofIndexMap(Map<Enum, bool> map) : value = map.entries.fold<int>(0, (previous, entry) => previous.modifyBool(entry.key.index, entry.value));
  Bits.ofBools(Iterable<bool> flags) : value = flags.foldIndexed<int>(0, (index, previous, element) => previous.modifyBool(index, element));
  //  value = flags.fold<int>(0, (previous, element) => (previous << 1) | (element ? 1 : 0)); // first element is ms bit

  set value(int newValue) => value = newValue;

  bool get isNotZero => (value != 0);
  bool get isZero => (value == 0);

  void reset([bool fill = false]) => value = fill ? const Bits.allOnes() : const Bits.allZeros();

  //todo fix aliases
  void write(Bitmask mask, int value) => this.value = modify(mask, value);

  // int getBits(Bitmask mask) => this..value.getBits(mask);
  Bits withBits(Bitmask mask, int value) => this..value.modify(mask, value);
  // void setBits(Bitmask mask, int value) => this.value = modify(mask, value);

  // int bitsAt(int offset, int width) => value.bitsAt(offset, width);
  // Bits modifyBits(int offset, int width, int value) => this.value.modifyBits(offset, width, value);
  void setBitsAt(int offset, int width, int value) => this.value = modifyBits(offset, width, value);

  // int bitAt(int index) => value.bitAt(index);
  // Bits modifyBit(int index, int value) => this.value.modifyBit(index, value);
  void setBitAt(int index, int value) => this.value = modifyBit(index, value);

  // bool boolAt(int index) => value.boolAt(index);
  // Bits modifyBool(int index, bool value) => this.value.modifyBool(index, value);
  void setBoolAt(int index, bool value) => this.value = modifyBool(index, value);

  // int byteAt(int index) => value.byteAt(index);
  // Bits modifyByte(int index, int value) => this.value.modifyByte(index, value);
  void setByteAt(int index, int value) => this.value = modifyByte(index, value);

  // int bytesAt(int index, int size) => value.bytesAt(index, size);
  // Bits modifyBytes(int index, int size, int value) => this..value.modifyBytes(index, size, value);
  void setBytesAt(int index, int size, int value) => this.value = modifyBytes(index, size, value);

  int operator [](int index) => bitAt(index);
  void operator []=(int index, int value) => setBitAt(index, value);
}

// function of a single number, object methods over top level math functions
extension BinaryOfInt on int {
  int get byteLength => ((bitLength - 1) ~/ 8) + 1; // (bitLength / 8).ceil();

  /// Bit operations
  int read(Bitmask mask) => mask.read(this); // (this & mask._bitmask) >>> mask.shift;
  int modify(Bitmask mask, int value) => mask.modify(this, value);

  // todo fix aliases
  // int getBits(Bitmask mask) => read(mask);
  // int withBits(Bitmask mask, int value) => modify(mask, value);

  int bitsAt(int offset, int width) => Bitmask.bits(offset, width).read(this);
  int modifyBits(int offset, int width, int value) => Bitmask.bits(offset, width).modify(this, value);

  int bitAt(int index) => Bitmask.bit(index).read(this);
  int modifyBit(int index, int value) => Bitmask.bit(index).modify(this, value);

  bool boolAt(int index) => Bitmask.bit(index).read(this) != 0;
  int modifyBool(int index, bool value) => Bitmask.bit(index).modify(this, value ? 1 : 0);

  // use bitmask directly skip TypedData buffer
  int bytesAt(int index, int size) => Bitmask.bytes(index, size).read(this);
  int modifyBytes(int index, int size, int value) => Bitmask.bytes(index, size).modify(this, value);

  int byteAt(int index) => Bitmask.byte(index).read(this);
  int modifyByte(int index, int value) => Bitmask.byte(index).modify(this, value);
}

// int bitmask(int shift, int width) => ((1 << width) - 1) << shift;

/// Bitmask
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

  int apply(int value) => (value << shift) & _bitmask; // get as masked
  int read(int source) => (source & _bitmask) >>> shift; // get as shifted back
  int modify(int source, int value) => (source & ~_bitmask) | apply(value); // ready for write back
  // int maskOff(int source) => (source & ~_mask);
  // int maskOn(int source) => (source | _mask);
  // int mask(int source) => (source & _mask);

  int operator *(int value) => ((value << shift) & _bitmask); // apply as compile time const??
  // int call(int value) => ((value << shift) & bits);
}

extension type Bitmasks._(Iterable<Bitmask> bitmasks) implements Iterable<Bitmask> {
  Bitmasks.fromWidths(Iterable<int> widths) : bitmasks = Iterable.generate(widths.length, (index) => Bitmask(widths.take(index).sum, widths.elementAt(index)));
}

extension BitmasksMethods on Iterable<Bitmask> {
  int get totalWidth => map((e) => e.width).sum;
  // assuming same ordering
  int apply(Iterable<int> values) => values.foldIndexed<int>(0, (index, previous, value) => elementAt(index).modify(previous, value));
}
