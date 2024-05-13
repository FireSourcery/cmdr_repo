// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';

import 'bits.dart';

class Bitmask {
  const Bitmask(this.offset, this.width)
      : assert(offset + width < kMaxUnsignedSMI),
        _bitmask = ((1 << width) - 1) << offset;

  final int _bitmask;
  final int offset;
  final int width;

  // int get width => (_bitmask >> offset).bitLength;

  // int maskOff(int source) => (source & ~_bitmask);
  // int maskOn(int source) => (source | _bitmask);
  int apply(int value) => (value << offset) & _bitmask; // get as masked
  int read(int source) => (source & _bitmask) >> offset; // get as shifted back
  int modify(int source, int value) => (source & ~_bitmask) | apply(value); // ready for write back

  // int operator |(int value) => (value | _bitmask);
  // int operator &(int value) => (value & _bitmask);
  // int operator ~() => (~_bitmask);
  int operator *(int value) => ((value << offset) & _bitmask); // apply as compile time const??
  int call(int value) => ((value << offset) & _bitmask);

  // implemented using Enum
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

  @override
  bool operator ==(covariant Bitmask other) {
    if (identical(this, other)) return true;
    return other._bitmask == _bitmask;
  }

  @override
  int get hashCode => _bitmask.hashCode ^ offset.hashCode ^ width.hashCode;
}

const Bitmask kBitmask0 = Bitmask(0, 1);

// Compile time const of codec
// extend BitmasksBase for const
abstract class Bitmasks<T extends Enum> {
  const Bitmasks();
  // const Bitmasks.test() : a = kBitmask0 * 1;
  // final int a;

  const factory Bitmasks.fromMap(Map<T, Bitmask> masks) = _BitmasksMap;
  factory Bitmasks.fromWidth(Map<T, int> widthMap) = _BitmasksMap.fromWidths;
  // factory Bitmasks.fromMembers(List<BitFieldMember> bitFieldMembers) => _BitmasksOnMembers<BitFieldMember>(bitFieldMembers) as Bitmasks<T>;
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

// passing data for constructor redirect
class _BitmasksMap<T extends Enum> extends Bitmasks<T> {
  const _BitmasksMap(this._bitmasks);

  _BitmasksMap.fromWidths(Map<T, int> widthMap)
      : _bitmasks = Map.unmodifiable({for (final (index, MapEntry(:key, value: width)) in widthMap.entries.indexed) key: Bitmask(offsetOf(widthMap.values, index), width)});

  static int offsetOf(Iterable<int> widths, int index) => widths.take(index).fold(0, (previousValue, element) => previousValue + element);

  final Map<T, Bitmask> _bitmasks;

  @override
  Iterable<T> get memberKeys => _bitmasks.keys;
  @override
  Bitmask operator [](T key) => _bitmasks[key]!;
}

///
extension type const BitmasksWidthMap<T extends Enum>(Map<T, int> widthMap) {
  static int offsetOf(Iterable<int> widths, int index) => widths.take(index).fold(0, (previousValue, element) => previousValue + element);
  Map<T, Bitmask> get masksMap => {for (final (index, MapEntry(:key, value: width)) in widthMap.entries.indexed) key: Bitmask(offsetOf(widthMap.values, index), width)};
// Bitmasks get bitmasks =>
}

extension type const BitFieldValuesMap<T extends Enum>(Map<T, int> valuesMap) {}

///
// contain the member dont have to split bitmask mixins
abstract mixin class BitFieldMember implements Enum, Bitmask {
  Bitmask get bitmask;

  // Enum get id => this;

  int apply(int value) => bitmask.apply(value);
  int read(int source) => bitmask.read(source);
  int modify(int source, int value) => bitmask.modify(source, value);
}

extension BitFieldMemberMasks on List<BitFieldMember> {
  Iterable<BitFieldMember> get memberKeys => this;
  Bitmask operator [](BitFieldMember key) => key;
}

// abstract class BitmasksBase2<T extends BitFieldMember> extends Bitmasks<T> {
//   const BitmasksBase2();
//   List<T> get memberKeys;
//   @override
//   Bitmask operator [](T key) => key.bitmask;
// }

// class _BitmasksOnMembers<T extends BitFieldMember> extends Bitmasks<T> {
//   const _BitmasksOnMembers(this.memberKeys);

//   @override
//   final List<T> memberKeys;
//   @override
//   Bitmask operator [](T key) => key;
// }
