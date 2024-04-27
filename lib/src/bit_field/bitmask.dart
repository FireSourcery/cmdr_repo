import 'package:collection/collection.dart';

import 'bits.dart';

class Bitmask {
  const Bitmask(this.offset, this.width)
      : assert(offset + width < kMaxUnsignedSMI),
        bitmask = ((1 << width) - 1) << offset;

  final int bitmask;
  final int offset;
  final int width;

  // int get width => (bitmask >> offset).bitLength;

  // int maskOff(int source) => (source & ~bitmask);
  // int maskOn(int source) => (source | bitmask);
  int apply(int value) => (value << offset) & bitmask; // get as masked
  int read(int source) => (source & bitmask) >> offset; // get as shifted back
  int modify(int source, int value) => (source & ~bitmask) | apply(value); // ready for write back

  int operator |(int value) => (value | bitmask);
  int operator &(int value) => (value & bitmask);
  int operator ~() => (~bitmask);
  int operator *(int value) => ((value << offset) & bitmask); // apply as compile time const
  // int operator () => bitmask;  
  int call() => bitmask;  

  // if implemented using Enum
  static int maskOf(int offset, int width) => ((1 << width) - 1) << offset;

  /// Flag Mask
  /// alternatively use common mask const?
  static int flagMask(int index) => (1 << index);
  static int maskBit(int source, int index) => source & flagMask(index);
  static int onBit(int source, int index) => source | flagMask(index); // maskOn
  static int offBit(int source, int index) => source & ~flagMask(index); // maskOff
  static int modifyBit(int source, int index, bool value) => value ? onBit(source, index) : offBit(source, index);
  static bool flagOf(int source, int index) => maskBit(source, index) > 0;
  static int bitOf(int source, int index) => flagOf(source, index) ? 1 : 0;
} 

// extend BitmasksBase for const
abstract class Bitmasks<T extends Enum> {
  const Bitmasks();
  const factory Bitmasks.onMap(Map<T, Bitmask> masks) = _BitmasksOnMap;
  factory Bitmasks.fromMap(Map<T, int> widthMap) = _BitmasksOnMap.fromWidths;
  factory Bitmasks.fromMembers(List<BitFieldMember> bitFieldMembers) => _BitmasksOnMembers<BitFieldMember>(bitFieldMembers) as Bitmasks<T>;
  // factory Bitmasks.fromHandler(Bitmask Function(T key) bitmaskOf) ;

  Iterable<T> get memberKeys;
  Bitmask operator [](T key);

  int get totalWidth => memberKeys.map((e) => this[e].width).sum;
  int valueOf(Map<T, int> valueMap) => valueMap.keys.fold<int>(0, (previous, key) => this[key].modify(previous, valueMap[key]!));
  int valueOfIterable(Iterable<int> values) => memberKeys.foldIndexed<int>(0, (index, previous, element) => this[element].modify(previous, values.elementAtOrNull(index) ?? 0));
}

abstract class BitmasksBase<T extends Enum> extends Bitmasks<T> {
  const BitmasksBase();
  List<T> get memberKeys; // with Enum.values
  Bitmask operator [](T key);
}

// contain the member dont have to split bitmask mixins
abstract class BitFieldMember implements Enum {
  Bitmask get bitmask;
}

abstract class BitmasksBase2<T extends BitFieldMember> extends Bitmasks<T> {
  const BitmasksBase2();
  List<T> get memberKeys;
  @override
  Bitmask operator [](T key) => key.bitmask;
}

// passing data for constructor redirect
class _BitmasksOnMap<T extends Enum> extends Bitmasks<T> {
  const _BitmasksOnMap(this._bitmasks);

  _BitmasksOnMap.fromWidths(Map<T, int> widthMap)
      : _bitmasks = Map.unmodifiable({for (final (index, MapEntry(:key, value: width)) in widthMap.entries.indexed) key: Bitmask(offsetOf(widthMap.values, index), width)});

  static int offsetOf(Iterable<int> widths, int index) => widths.take(index).fold(0, (previousValue, element) => previousValue + element);

  final Map<T, Bitmask> _bitmasks;

  @override
  Iterable<T> get memberKeys => _bitmasks.keys;
  @override
  Bitmask operator [](T key) => _bitmasks[key]!;
}

class _BitmasksOnMembers<T extends BitFieldMember> extends Bitmasks<T> {
  const _BitmasksOnMembers(this.memberKeys);

  @override
  final List<T> memberKeys;
  @override
  Bitmask operator [](T key) => key.bitmask;
}

extension type const BitmasksWidthMap<T extends Enum>(Map<T, int> widthMap) {
  static int offsetOf(Iterable<int> widths, int index) => widths.take(index).fold(0, (previousValue, element) => previousValue + element);
  Map<T, Bitmask> get masksMap => {for (final (index, MapEntry(:key, value: width)) in widthMap.entries.indexed) key: Bitmask(offsetOf(widthMap.values, index), width)};
// Bitmasks get bitmasks =>
}

extension type const BitFieldValuesMap<T extends Enum>(Map<T, int> valuesMap) {}
