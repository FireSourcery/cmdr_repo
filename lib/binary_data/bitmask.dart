import 'package:collection/collection.dart';

import 'bits.dart';

int bitmask(int offset, int width) => ((1 << width) - 1) << offset;

// as storable object to use as key, + static functions
class Bitmask {
  const Bitmask(this.offset, this.width) : _mask = ((1 << width) - 1) << offset;
  // assert(offset + width < kMaxUnsignedSMI)
  const Bitmask.bit(int index) : this(index, 1); // (1 << index);
  const Bitmask.byte(int index) : this(index * 8, 8);
  const Bitmask.bytes(int offset, int size) : this(offset * 8, size * 8);

  final int _mask;
  final int offset;
  final int width; // (_bitmask >> offset).bitLength;

  int apply(int value) => (value << offset) & _mask; // get as masked
  int read(int source) => (source & _mask) >> offset; // get as shifted back
  int modify(int source, int value) => (source & ~_mask) | apply(value); // ready for write back
  // int maskOff(int source) => (source & ~_mask);
  // int maskOn(int source) => (source | _mask);
  // int mask(int source) => (source & _mask);

  // int operator |(int value) => (value | _bitmask);
  // int operator &(int value) => (value & _bitmask);
  // int operator ~() => (~_bitmask);
  int operator *(int value) => ((value << offset) & _mask); // apply as compile time const??
  // int call(int value) => ((value << offset) & bits);

  // @override
  // bool operator ==(covariant Bitmask other) {
  //   if (identical(this, other)) return true;
  //   return other.bits == bits;
  // }

  // @override
  // int get hashCode => bits.hashCode ^ offset.hashCode ^ width.hashCode;
}

class Bitmasks extends Iterable<Bitmask> {
  Bitmasks.fromWidths(Iterable<int> widths) : iterator = Iterable.generate(widths.length, (index) => Bitmask(widths.take(index).sum, widths.elementAt(index))).iterator;

  @override
  Iterator<Bitmask> iterator;
}

extension BitmasksMethods on Iterable<Bitmask> {
  // static fromWidths(Iterable<int> widths) => Iterable.generate(widths.length, (index) => Bitmask(widths.take(index).sum, widths.elementAt(index)));

  int get totalWidth => map((e) => e.width).sum;

  // assuming same ordering
  int apply(Iterable<int> values) => foldIndexed<int>(0, (index, previous, element) => element.modify(previous, values.elementAt(index)));
  // int applyModify(Iterable<int> values, Iterable<int> newValues);
}

extension BitmasksMapMethods on Map<Bitmask, int> {
  // int value  => ;
}

// const Bitmask kBitmask0 = Bitmask(0, 1);

// extension type const BitFieldValuesMap<T extends Enum>(Map<T, int> valuesMap) {}
