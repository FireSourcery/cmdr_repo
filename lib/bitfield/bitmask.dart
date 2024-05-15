// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';

import 'bits.dart';

class Bitmask {
  const Bitmask(this.offset, this.width)
      : assert(offset + width < kMaxUnsignedSMI),
        bits = ((1 << width) - 1) << offset;

  const Bitmask.flag(this.offset)
      : width = 1,
        bits = 1 << offset;

  final int bits;
  final int offset;
  final int width;

  // int get width => (_bitmask >> offset).bitLength;
  static int of(int offset, int width) => ((1 << width) - 1) << offset;

  // int maskOff(int source) => (source & ~_bitmask);
  // int maskOn(int source) => (source | _bitmask);
  int apply(int value) => (value << offset) & bits; // get as masked
  int read(int source) => (source & bits) >> offset; // get as shifted back
  int modify(int source, int value) => (source & ~bits) | apply(value); // ready for write back

  // int operator |(int value) => (value | _bitmask);
  // int operator &(int value) => (value & _bitmask);
  // int operator ~() => (~_bitmask);
  int operator *(int value) => ((value << offset) & bits); // apply as compile time const??
  int call(int value) => ((value << offset) & bits);

  /// Flag Mask
  /// alternatively use common mask const?
  static int flagMask(int index) => (1 << index);
  static int maskBit(int source, int index) => source & flagMask(index);
  static int onBit(int source, int index) => source | flagMask(index); // maskOn
  static int offBit(int source, int index) => source & ~flagMask(index); // maskOff
  static int modifyBit(int source, int index, bool value) => value ? onBit(source, index) : offBit(source, index);
  static bool flagOf(int source, int index) => maskBit(source, index) > 0;
  static int bitOf(int source, int index) => flagOf(source, index) ? 1 : 0;

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

// const Bitmask kBitmask0 = Bitmask(0, 1);

class Bitmasks extends Iterable<Bitmask> {
  Bitmasks.fromWidths(Iterable<int> widths) : iterator = Iterable.generate(widths.length, (index) => Bitmask(offsetOf(widths, index), widths.elementAt(index))).iterator;

  static int offsetOf(Iterable<int> widths, int index) => widths.take(index).fold(0, (previousValue, element) => previousValue + element);

  @override
  Iterator<Bitmask> iterator;

  int get totalWidth => map((e) => e.width).sum;

  int valueOfIterable(Iterable<int> values) => foldIndexed<int>(0, (index, previous, element) => element.modify(previous, values.elementAtOrNull(index) ?? 0));

  // int valueOfIterable(Iterable<int> values) =>  fold<int>(0, (previous, mask) => mask.modify(previous, valueMap[mask]!));
}
 

// extension type const BitFieldValuesMap<T extends Enum>(Map<T, int> valuesMap) {}