const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;
const int _smiBits = 62;
const int _allZeros = 0;
const int _allOnes = kMaxUnsignedSMI;

////////////////////////////////////////////////////////////////////////////////
/// BitsBaseInterface
////////////////////////////////////////////////////////////////////////////////
/// V is bool for Flags, int for Field
abstract interface class GenericBitField<T, V> {
  const GenericBitField();

  int get width;

  int get bits;
  set bits(int value);

  int get value;

  V operator [](T indexed);
  void operator []=(T indexed, V value);
  void reset([bool value = false]);

  Iterable<T> get memberKeys; // using Enum.values
  Iterable<V> get memberValues;
  (T, V) entry(T indexed);
  Iterable<(T, V)> get entries;
}

abstract class GenericBitFieldBase<T, V> = GenericBitField<T, V> with BitsBaseMixin<T, V>, BitsNamesMixin<T, V>;
abstract class UnmodifiableGenericBitFieldBase<T, V> = GenericBitFieldBase<T, V> with UnmodifiableBitsMixin<T, V>;

abstract mixin class BitsBaseMixin<T, V> implements GenericBitField<T, V> {
  const BitsBaseMixin();

  @override
  set bits(int value) => bits = value;
  @override
  void reset([bool value = false]) => bits = value ? _allOnes : _allZeros;
  @override
  int get value => bits;

  @override
  bool operator ==(covariant GenericBitField<T, V> other) {
    if (identical(this, other)) return true;
    return other.bits == bits;
  }

  @override
  int get hashCode => bits.hashCode;
}

mixin BitsNamesMixin<T, V> implements GenericBitField<T, V> {
  // @override
  // List<T> get memberKeys; // using Enum.values
  @override
  Iterable<V> get memberValues => memberKeys.map((e) => this[e]);
  @override
  (T, V) entry(T indexed) => (indexed, this[indexed]);
  @override
  Iterable<(T, V)> get entries => memberKeys.map((e) => entry(e));
}

mixin UnmodifiableBitsMixin<T, V> implements GenericBitField<T, V> {
  @override
  set bits(int value) => throw UnsupportedError("Cannot modify unmodifiable");
  @override
  void operator []=(T indexed, V value) => throw UnsupportedError("Cannot modify unmodifiable");
  @override
  void reset([bool value = false]) => throw UnsupportedError("Cannot modify unmodifiable");

  //for const, use code gen
  // List<V Function(T)> get getters;
}

// extension type ConstBitField<T, V>(Map<T, V> constValues) implements GenericBitField<T, V> {
//   int get width;

//   int get bits;
//   set bits(int value) => BitFlags.bitsOfMap(constValues);

//   int get value;

//   V operator [](T indexed) => constValues[indexed]!;
//   void operator []=(T indexed, V value);
//   void reset([bool value = false]);

//   List<T> get memberKeys => constValues.keys.toList();
//   Iterable<V> get memberValues => constValues.values;
//   (T, V) entry(T indexed);
//   Iterable<(T, V)> get entries;
// }

// const via map
// abstract class ConstBitsBaseOnMap<T, V> extends BitsBaseMixin<T, V> with BitsNamesMixin<T, V>, UnmodifiableBitsMixin<T, V> implements GenericBitField<T, V> {
//   const ConstBitsBaseOnMap(this.constValues);

//   final Map<T, V> constValues;

//   @override
//   List<T> get memberKeys;

//   @override
//   int get bits;

//   @override
//   int get width;

//   @override
//   V operator [](T indexed) => constValues[indexed]!;
// }
