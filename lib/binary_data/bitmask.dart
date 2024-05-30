import 'package:collection/collection.dart';

int bitmask(int shift, int width) => ((1 << width) - 1) << shift;

// as storable object to use as key
class Bitmask {
// extension type const Bitmask(({int shift, int width}) ) {
// extension type const Bitmask(({int shift, int mask}) ) {
  const Bitmask(this.shift, this.width) : mask = ((1 << width) - 1) << shift;
  const Bitmask.bits(this.shift, this.width) : mask = ((1 << width) - 1) << shift;
  const Bitmask.bit(int index) : this.bits(index, 1); // (1 << index);
  const Bitmask.bytes(int shift, int size) : this.bits(shift * 8, size * 8);
  const Bitmask.byte(int index) : this.bits(index * 8, 8);

  final int mask;
  final int shift;
  final int width; // (_bitmask >> shift).bitLength;

  int apply(int value) => (value << shift) & mask; // get as masked
  int read(int source) => (source & mask) >> shift; // get as shifted back
  int modify(int source, int value) => (source & ~mask) | apply(value); // ready for write back
  // int maskOff(int source) => (source & ~_mask);
  // int maskOn(int source) => (source | _mask);
  // int mask(int source) => (source & _mask);

  int operator *(int value) => ((value << shift) & mask); // apply as compile time const??
  // int call(int value) => ((value << shift) & bits);
}

// extension type const BitmaskedValue._(int value) implements int {
//   BitmaskedValue(Bitmask bitmask, int input) : this._(bitmask.apply(input));
//   const BitmaskedValue.test(Bitmask bitmask, int input) : this._(bitmask * input);
//   const BitmaskedValue.of(int shift, int width, int input) : this._((input << shift) & (((1 << width) - 1) << shift));
//   const BitmaskedValue.read(int shift, int width, int source) : this._((source & (((1 << width) - 1) << shift)) >> shift);
// }

extension type Bitmasks._(Iterable<Bitmask> bitmasks) implements Iterable<Bitmask> {
  Bitmasks.fromWidths(Iterable<int> widths) : bitmasks = Iterable.generate(widths.length, (index) => Bitmask(widths.take(index).sum, widths.elementAt(index)));
}

extension BitmasksMethods on Iterable<Bitmask> {
  int get totalWidth => map((e) => e.width).sum;
  // assuming same ordering
  int apply(Iterable<int> values) => values.foldIndexed<int>(0, (index, previous, value) => elementAt(index).modify(previous, value));
}

extension BitmaskMapMethods on Map<Bitmask, int> {
  int get totalWidth => keys.totalWidth;
  int fold() => entries.fold<int>(0, (previous, element) => element.key.modify(previous, element.value));
  // int fold() => keys.apply(values);
}

// extension type const BitmasksMap (Map<Bitmask, int> valuesMap) {}
