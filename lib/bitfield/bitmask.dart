import 'package:collection/collection.dart';

import 'bits.dart';

class Bitmask {
  const Bitmask(this.offset, this.width) : _mask = ((1 << width) - 1) << offset;
  // assert(offset + width < kMaxUnsignedSMI)

  const Bitmask.flag(int offset) : this(offset, 1);
  const Bitmask.byte(int index) : this(index * 8, 8);
  const Bitmask.bytes(int index, int size) : this(index * 8, size * 8);

  final int _mask;
  final int offset;
  final int width; // (_bitmask >> offset).bitLength;

  static int asIntOf(int offset, int width) => ((1 << width) - 1) << offset;

  int apply(int value) => (value << offset) & _mask; // get as masked
  int read(int source) => (source & _mask) >> offset; // get as shifted back
  int modify(int source, int value) => (source & ~_mask) | apply(value); // ready for write back

  // int operator |(int value) => (value | _bitmask);
  // int operator &(int value) => (value & _bitmask);
  // int operator ~() => (~_bitmask);
  int operator *(int value) => ((value << offset) & _mask); // apply as compile time const??
  // int call(int value) => ((value << offset) & bits);

  // todo as top level math functions? alternatively use common mask const?

  /// Flag Mask
  static int flagMask(int index) => (1 << index);
  static int maskBit(int source, int index) => source & flagMask(index);
  static int onBit(int source, int index) => source | flagMask(index); // maskOn
  static int offBit(int source, int index) => source & ~flagMask(index); // maskOff
  static int modifyBit(int source, int index, bool value) => value ? onBit(source, index) : offBit(source, index);
  static bool flagOf(int source, int index) => maskBit(source, index) > 0;
  static int bitOf(int source, int index) => flagOf(source, index) ? 1 : 0;

  // static int maskOff(int source, int index, int value) => (source & ~_bitmask);
  // static int maskOn(int source, int index, int value) => (source | _bitmask);

  // @override
  // bool operator ==(covariant Bitmask other) {
  //   if (identical(this, other)) return true;
  //   return other.bits == bits;
  // }

  // @override
  // int get hashCode => bits.hashCode ^ offset.hashCode ^ width.hashCode;
}

extension IntBitmask on int {
  int bits(int offset, int length) => Bitmask(offset, length).read(this);
  int setBits(int offset, int length, int value) => Bitmask(offset, length).modify(this, value);
}

class Bitmasks extends Iterable<Bitmask> {
  Bitmasks.fromWidths(Iterable<int> widths) : iterator = Iterable.generate(widths.length, (index) => Bitmask(widths.take(index).sum, widths.elementAt(index))).iterator;

  @override
  Iterator<Bitmask> iterator;
}

extension BitmasksMethods on Iterable<Bitmask> {
  int get totalWidth => map((e) => e.width).sum;

  // assuming same ordering
  int apply(Iterable<int> values) => foldIndexed<int>(0, (index, previous, element) => element.modify(previous, values.elementAt(index)));
}

extension BitmasksMapMethods on Map<Bitmask, int> {
  // int value  => ;
}

// const Bitmask kBitmask0 = Bitmask(0, 1);

// extension type const BitFieldValuesMap<T extends Enum>(Map<T, int> valuesMap) {}