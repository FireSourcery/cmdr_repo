import 'dart:collection';
import 'package:cmdr/binary_data/int_ext.dart';

const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;
const int _smiBits = 62;
const int _allZeros = 0;
const int _allOnes = kMaxUnsignedSMI;

abstract mixin class Bits {
  const Bits();

  int get value;
  set value(int newValue) => value = newValue;

  // int get maxWidth;

  int bitsAt(int offset, int width) => value.bitsAt(offset, width);
  int modifyBits(int offset, int width, int value) => this.value.modifyBits(offset, width, value);
  void setBitsAt(int offset, int width, int value) => this.value = modifyBits(offset, width, value);

  bool boolAt(int index) => value.boolAt(index);
  int modifyBool(int index, bool value) => this.value.modifyBool(index, value);
  void setBoolAt(int index, bool value) => this.value = modifyBool(index, value);

  int bitAt(int index) => value.bitAt(index);
  int modifyBit(int index, int value) => this.value.modifyBit(index, value);
  void setBitAt(int index, int value) => this.value = modifyBit(index, value);

  int byteAt(int index) => value.byteAt(index);
  int modifyByte(int index, int value) => this.value.modifyByte(index, value);
  void setByteAt(int index, int value) => this.value = modifyByte(index, value);

  int bytesAt(int index, int size) => value.bytesAt(index, size);
  int modifyBytes(int index, int size, int value) => this.value.modifyBytes(index, size, value);
  void setBytesAt(int index, int size, int value) => this.value = modifyBytes(index, size, value);

  void reset([bool fill = false]) => value = fill ? _allOnes : _allZeros;

  int get byteLength => value.byteLength;
  bool get isSet => (value != 0);

  @override
  bool operator ==(covariant Bits other) {
    if (identical(this, other)) return true;
    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

mixin UnmodifiableBitsMixin<T, V> implements Bits {
  @override
  set value(int value) => throw UnsupportedError("Cannot modify unmodifiable");
  // @override
  // void operator []=(T key, V value) => throw UnsupportedError("Cannot modify unmodifiable");
  // @override
  // void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");
}

/// T is Enum for Flags, Bitmask for Field
/// V is bool for Flags, int for Field
abstract mixin class BitsMap<T, V> implements MapBase<T, V>, Bits {
  const BitsMap();

  List<T> get keys;
  V operator [](covariant T key);
  void operator []=(covariant T key, V value);

  @override
  void clear() => value = 0;
  @override
  V? remove(covariant T key) => throw UnsupportedError('BitsMap does not support remove operation');

  Iterable<(T, V)> get pairs => keys.map((e) => (e, this[e]));

  @override
  String toString() => '$runtimeType: $values';

  // @override
  // bool operator ==(covariant BitsMap<T, V> other) {
  //   if (identical(this, other)) return true;
  //   return other.value == value;
  // }

  // @override
  // int get hashCode => value.hashCode;
}

/// combined mixins
/// alternatively child class selectively mixin Bits
abstract class GenericBitFieldBase<T, V> with MapBase<T, V>, BitsMap<T, V>, Bits {
  const GenericBitFieldBase();
  int get width;
  int get value;
  List<T> get keys;
  V operator [](covariant T key);
  void operator []=(T key, V value);
}

// abstract class GenericMutableBitFieldBase<T, V> extends GenericBitFieldBase<T, V> {
//   GenericMutableBitFieldBase(this.value);
//   @override
//   int value;
// }

// abstract class GenericConstBitFieldBase<T, V> extends GenericBitFieldBase<T, V> {
//   const GenericConstBitFieldBase(this.value);
//   @override
//   final int value;
// }

// for cast of compile time const only
abstract class ConstBitFieldOnMapBase<T, V> extends GenericBitFieldBase<T, V> with UnmodifiableBitsMixin<T, V> {
  const ConstBitFieldOnMapBase(this.valueMap, [List<T>? _keys]);
  final Map<T, V> valueMap;

  int get value;
  int get width;

  @override
  V operator [](covariant T key) => valueMap[key]!;

  @override
  void operator []=(T key, V value) => throw UnsupportedError("Cannot modify unmodifiable");

  @override
  List<T> get keys => throw UnsupportedError("Extend BitFieldBase");
}

////////////////////////////////////////////////////////////////////////////////
/// BitsBaseInterface
////////////////////////////////////////////////////////////////////////////////
/// V is bool for Flags, int for Field
// abstract interface class GenericBits<T, V> implements Map<T, V> {
//   const GenericBits();

//   int get width; // max width

//   int get value; // bits value
//   set value(int newValue);

//   int bitsAt(int index, int width);
//   void setBitsAt(int index, int width, int value);
//   bool boolAt(int index);
//   void setBoolAt(int index, bool newValue);
//   int bitAt(int index);
//   void setBitAt(int index, int newValue);

//   void reset([bool value = false]);

//   List<T> get keys; // using Enum.values
//   V operator [](covariant T key);
//   void operator []=(T key, V value);
//   V? remove(covariant T key);
//   void clear();

//   Iterable<(T, V)> get pairs;
// }
 

////////////////////////////////////////////////////////////////////////////////
/// Component Mixins
////////////////////////////////////////////////////////////////////////////////


