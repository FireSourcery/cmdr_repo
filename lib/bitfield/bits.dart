import 'dart:collection';

import 'package:cmdr/common/enum_map.dart';

import 'bitmask.dart';

const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;
const int _smiBits = 62;
const int _allZeros = 0;
const int _allOnes = kMaxUnsignedSMI;

typedef RecordEntry<K, V> = ({K key, V value});

////////////////////////////////////////////////////////////////////////////////
/// BitsBaseInterface
////////////////////////////////////////////////////////////////////////////////

/// V is bool for Flags, int for Field
abstract interface class GenericBitField<T, V> implements MapBase<T, V> {
  const GenericBitField();

  int get width;

  int get value;
  set value(int newValue);

  int bitsAt(int index, int width);
  int setBitsAt(int index, int width, int value);
  void reset([bool value = false]);

  List<T> get keys; // using Enum.values
  V operator [](covariant T key);
  void operator []=(T key, V value);
  V? remove(covariant T key);
  void clear();

  Iterable<(T, V)> get pairs;
  // Iterable<(String, V)> get namedValues;
}

////////////////////////////////////////////////////////////////////////////////
/// Component Mixins
////////////////////////////////////////////////////////////////////////////////
// typedef BitsMap<T extends Enum, V> = EnumMap<T, V>;

abstract mixin class BitsMap<T, V> implements MapBase<T, V>, GenericBitField<T, V> {
  const BitsMap();

  @override
  List<T> get keys;
  @override
  V operator [](covariant T key);
  @override
  void operator []=(T key, V value);

  @override
  void clear() => value = 0;
  @override
  V? remove(covariant T key) => throw UnsupportedError('EnumMap does not support remove operation');
  // @override
  // Iterable<(String, V)> get namedValues => keys.map((e) => (e.name, this[e]));
  @override
  Iterable<(T, V)> get pairs => keys.map((e) => (e, this[e]));
}

abstract mixin class BitsBaseMixin<T, V> implements GenericBitField<T, V> {
  const BitsBaseMixin();

  int get value;
  @override
  set value(int newValue) => value = newValue;
  @override
  int bitsAt(int index, int width) => Bitmask(index, width).read(value);
  @override
  int setBitsAt(int index, int width, int newValue) => Bitmask(index, width).modify(value, newValue);
  @override
  void reset([bool fill = false]) => value = fill ? _allOnes : _allZeros;

  @override
  String toString() => '$runtimeType: $values';

  @override
  bool operator ==(covariant GenericBitField<T, V> other) {
    if (identical(this, other)) return true;
    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

mixin UnmodifiableBitsMixin<T, V> implements GenericBitField<T, V> {
  @override
  set value(int value) => throw UnsupportedError("Cannot modify unmodifiable");
  @override
  void operator []=(T indexed, V value) => throw UnsupportedError("Cannot modify unmodifiable");
  @override
  void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");
}

//replace with map
// mixin BitsNamesMixin<T, V> implements GenericBitField<T, V> {
//   // @override
//   // List<T> get memberKeys; // using Enum.values
//   @override
//   Iterable<V> get values => keys.map((e) => this[e]);
//   @override
//   (T, V) entry(T member) => (member, this[member]);
//   @override
//   Iterable<(T, V)> get pairs => keys.map((e) => entry(e));
// }

  

// class _ConstBitFieldFromMap<T , V> with BitFieldMixin<T>, BitsBaseMixin<T, V> implements GenericBitField<T, V> {
//   const _ConstBitFieldFromMap(this.map);

//   final Map<T, V> map;

//   @override
//   V? operator [](T indexed) => map[indexed];

//   @override
//   void operator []=(T indexed, V value) => throw UnsupportedError("Cannot modify unmodifiable");

//   @override
//   Iterable<T> get memberKeys => throw UnimplementedError();

//   @override
//   int get width => throw UnimplementedError();

//   @override
//   int get bits => throw UnimplementedError();
// }


// abstract class ConstBitField<T, V> with BitsBaseMixin<T, V>, BitsBaseMixin<T, V>, BitsNamesMixin<T, V> implements GenericBitField<T, V> {
//   const ConstBitField(this.bits);
//   // const ConstBitField.fromMasks(masks);
//   // const ConstBitField.fromMap(map);
//   @override
//   final int bits;

//   @override
//   V operator [](T indexed);

//   @override
//   void operator []=(T indexed, V value);

//   @override 
//   Iterable<T> get memberKeys => throw UnimplementedError();

//   @override 
//   int get width => throw UnimplementedError();
// }
