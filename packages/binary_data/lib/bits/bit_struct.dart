import 'package:meta/meta.dart';

import 'package:type_ext/index_map.dart';
import 'package:type_ext/struct.dart';
import 'package:type_ext/basic_ext.dart';

import 'bit_field.dart';
import 'bits_map.dart';

export 'bit_field.dart';
export 'bits_map.dart';

////////////////////////////////////////////////////////////////////////////////
/// [Bits] + [BitField] keys, [] operators, returning [int]
///
/// wrapper with key access, Map interface,
/// [Map<Enum, int>] mixin provides serialization
///   MapBase<K, int> must be mixed in first.
///
/// [BitStruct] Interface for extending with Subtypes
///   Struct must be extended with Keys
///   Partial Map implementation with [Bits] as source
///
/// [BitsMap] - a version of Map with [Bits] as source. Does not need to be extended in most cases
////////////////////////////////////////////////////////////////////////////////
abstract mixin class BitStruct<K extends BitField> implements BitsBase, BitsMap<K, int> {
  const BitStruct();
  const factory BitStruct.view(List<K> keys, Bits bits) = _BitStruct<K>;
  // const factory BitStruct.withType(List<K> keys, Bits bits) = _BitStruct<K>;

  // Child class defines fixed keys
  Iterable<K> get keys; // effectively the BitStruct type
  // List<K> get fields; keep keys as Iterable for compatibility with const map initializer

  Bits get bits;
  set bits(Bits value);
  // BitsBase get data; //alternatively wrap for combined const and mutable

  // Map operators common
  int operator [](covariant K key);
  void operator []=(covariant K key, int value);
  // Map operators implemented by [BitFieldMap] mixin
  void clear();
  int remove(K key);

  @override
  int get width => keys.bitmasks.totalWidth;

  // implements Structure
  // Unconstrained type keys
  @protected
  int get(BitField key) => bits.getBits(key.bitmask);
  @protected
  void set(BitField key, int value) => setBits(key.bitmask, value);
  @protected
  bool testBounds(BitField key) => key.bitmask.shift + key.bitmask.width <= width;

  // can include from Structure
  @protected
  int? getOrNull(BitField key) => testBounds(key) ? bits.getBits(key.bitmask) : null;
  @protected
  bool trySet(BitField key, int value) {
    if (testBounds(key)) {
      bits = bits.withBits(key.bitmask, value);
      return true;
    }
    return false;
  }

  int field(K key) => get(key);
  void setField(K key, int value) => set(key, value);
  int? fieldOrNull(BitField key) => getOrNull(key);
  bool trySetField(BitField key, int value) => trySet(key, value);

  Iterable<({K key, bool value})> get fieldsAsBool => keys.map((e) => (key: e, value: (this[e] != 0)));
  Iterable<({K key, int value})> get fieldsAsBits => keys.map((e) => (key: e, value: this[e]));

  /// returned instance is immutable
  /// override to return a subtype
  BitStruct<K> copyWithBits(Bits value) => _BitStruct(keys, value);
  // @override
  // BitStruct<K> copyWith() => copyWithBits(bits);

  // keep keys, update value
  BitStruct<K> withValue(int value) => copyWithBits(Bits(value));
  @override
  BitStruct<K> withField(K key, int value) => copyWithBits(bits.withBits(key.bitmask, value));
  @override
  BitStruct<K> withEntries(Iterable<MapEntry<K, int>> entries) => copyWithBits(bits.withEach(entries.map((e) => (e.key.bitmask, e.value))));
  @override
  BitStruct<K> withMap(Map<K, int> map) => withEntries(map.entries);

  @override
  String toString() => toStringAsMap();

  String toStringAsMap() => MapBase.mapToString(this); // {key: 0, key: 0,}
  String toStringAsValues() => values.toString(); // (0, 0, 0)

  MapEntry<String, int> toStringMapEntry([String? name]) => MapEntry<String, int>(name ?? K.toString(), bits); // {name: value}

  /// bitfields compare by value
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BitStruct<K>) return false;
    // keys are not copied, so they must match
    // (other.keys == keys) || other is BitsInitializer<K>
    return (other.bits == bits);
  }

  @override
  int get hashCode {
    return keys.hashCode ^ bits.hashCode;
  }
}

/// mixn to override [copyWithBits]/copyWith to return a subtype
/// Subtype considerations:
/// to return a subtype,[S extends BitStruct<K>]:
///   provide the constructor of the subtype
///   use a prototype object copyWith(), which calls the constructor of the subtype
mixin BitStructAsSubtype<S extends BitStruct<K>, K extends BitField> on BitStruct<K> {
  @mustBeOverridden // mark for overide in the case of return as a subtype
  S copyWithBits(Bits value);

  @override
  S withField(K key, int value) => super.withField(key, value) as S;
  @override
  S withEntries(Iterable<MapEntry<K, int>> entries) => super.withEntries(entries) as S;
  @override
  S withMap(Map<K, int> map) => super.withMap(map) as S;

  // @mustBeOverridden
  // S copyWith();
  // S withField(K key, int value) => (super.withField(key, value) as BitStructAsSubtype).copyWith();
}

////////////////////////////////////////////////////////////////////////////////
/// Struct abstract keys
/// extendable, with Enum.values
////////////////////////////////////////////////////////////////////////////////
abstract class BitStructBase<K extends BitField> = BitsBase with MapBase<K, int>, BitFieldMap<K>, BitStruct<K>;

abstract class MutableBitStruct<K extends BitField> extends BitStructBase<K> {
  MutableBitStruct([int value = 0]) : bits = Bits(value);
  @override
  Bits bits;
}

@immutable
abstract class ConstBitStruct<K extends BitField> extends BitStructBase<K> {
  const ConstBitStruct(int value) : bits = value as Bits;
  @override
  final Bits bits;
  @override
  set bits(Bits value) => throw UnsupportedError('Cannot modify unmodifiable');
}

/// alternatively, wrap for combined const and mutable, allow BitsInitializer as common interfacce
// abstract class BitStructBase1<K extends BitField> extends BitsBase with MapBase<K, int>, BitFieldMap<K>, BitStruct<K> implements BitStruct<K> {
//   const BitStructBase1(this.bitData);
//   const BitStructBase1.initalizer(BitsInitializer this.bitData);

//   BitStructBase1.mutable(Bits bits) : bitData = MutableBits(bits);

//   Iterable<K> get keys;
//   final BitsBase bitData;

//   @override
//   Bits get bits => bitData.bits;
//   @override
//   set bits(Bits value) => bitData.bits = value;
// }

// class BitStructBaseTest<K extends BitField> extends BitStructBase1<K> {
//   const BitStructBaseTest.init(BitsInitializer super.bitData);
//   const BitStructBaseTest(super.bits);

//   @override
//   Iterable<K> get keys => [];
// }

// const BitStructBaseTest<BitField> empty = BitStructBaseTest<BitField>(ConstBits(1 as Bits));

/// [BitsInitializer]
/// compile time const definition using map literal
/// implements [ConstBitStruct<K>] via base data of [const Map<T, int>]
///
/// BitStruct<EnumType> example = BitsInitializer({
///   EnumType.name1: 2,
///   EnumType.name2: 3,
/// });
///
/// UserSubStruct extends BitsInitializer implements UserSuperStruct
///
typedef _BitsInitializer<T extends BitField> = Map<T, int>;

@immutable
class BitsInitializer<K extends BitField> with BitsBase, MapBase<K, int>, BitFieldMap<K>, BitStruct<K> implements ConstBitStruct<K> {
  const BitsInitializer(this._init);

  final _BitsInitializer<K> _init;

  @override
  Iterable<K> get keys => _init.keys;
  @override
  Bits get bits => Bits.ofEntries(_init.bitsEntries); // in order to init using const Map, bits must be derived at run time
  @override
  set bits(Bits value) => throw UnsupportedError('Cannot modify unmodifiable');

  @override
  String toString() => toStringAsMap();
}

/// concrete pair return
/// passing keys
@immutable
class _BitStruct<K extends BitField> extends ConstBitStruct<K> implements BitStruct<K> {
  const _BitStruct(this.keys, super.value);
  @override
  final Iterable<K> keys;
}

// Keys list effectively define type and act as factory
// factorys returning as super interface type
// Separates subtype `class variables` from instance
// inheritable over BitStruct factory constructors
extension type const BitStructType<T extends BitField>(List<T> keys) {
  // BitStruct<T> castBase(BitsBase base) {
  //   return switch (base) {
  //     ConstBitStruct() => _BitStruct(keys, base.bits),
  //     // MutableBitStruct() => MutableBitStruc (keys, base.bits),
  //     BitsBase() => throw StateError(''),
  //   };
  // }

  // BitStruct<T> castBits(int value) => _BitStruct<T>(keys, Bits(value));

  // unmodifiableView
  BitStruct<T> view(int value) => _BitStruct<T>(keys, Bits(value));

  // alternatively default constructors can return partial implementation without Keys/MapOperator
  // BitStruct<T> create([int value = 0, bool mutable = true]) {
  //   return switch (mutable) {
  //     true => _BitStruct(keys, Bits(value)),
  //     false => _BitStruct(keys, Bits(value)),
  //   };
  // }

  // Alternatively subclass directly call Bits constructors to derive Bits value
  // enum map by default copies into an array
  // BitStruct<T> fromValues(Iterable<int> values, [bool mutable = true]) {
  //   return create(Bits.ofIterables(keys.bitmasks, values), mutable);
  // }

  // BitStruct<T> fromMap(Map<T, int> map, [bool mutable = true]) {
  //   return create(Bits.ofEntries(map.bitsEntries), mutable);
  // }
}

// return as subtype needs constructor
typedef BitStructCaster<T extends BitStruct> = T Function(BitsBase bitsBase);
// extension type const BitStructSubType<S extends BitStruct<T>, T extends BitField>(List<T> keys) implements BitStructType<T> {
//   // redeclare in the subtype
//   @mustBeOverridden
//   S castBase(BitsBase base) => throw UnimplementedError('castBase must be implemented in the subtype');

//   // S castBits(int value) => (this as BitStructType<T>).castBits(value) as S;
// }

// abstract class BitStructClass<S extends BitStruct, K extends BitField> {
//   List<K> get keys;
//   S cast(BitsBase base);
//   // S createBuffer([Bits initialValue = const Bits.allZeros()]) => constructor(initialValue);
// }

////////////////////////////////////////////////////////////////////////////////
/// Wrapper/Buffer with all interfaces, factory, return as subtype
/// prototype object which can return a subtype
///
/// keys with buffer
/// extends for mutiple view types
///
/// passing keys
/// castBase returning S
// optionally as const object or as typed buffer
////////////////////////////////////////////////////////////////////////////////
class BitConstruct<S extends BitStruct<K>, K extends BitField> with BitsBase, MapBase<K, int>, BitFieldMap<K>, BitStruct<K> implements BitStruct<K> {
  const BitConstruct({required this.keys, required this.constructor, required this.buffer});

  BitConstruct.withConstructor(this.constructor, [Bits initialValue = const Bits.allZeros()]) : keys = constructor(initialValue).keys, buffer = constructor(initialValue);

  BitConstruct.withPrototype(S prototype) : keys = prototype.keys, buffer = prototype, constructor = prototype.copyWithBits as S Function(Bits);

  // S is dynamic or BitStruct<K>, return base type
  // BitConstruct.generic(this.keys, this.bits) : constructor = ((Bits bits) => BitStruct<K>.view(const [], bits) as S);

  @override
  final Iterable<K> keys;
  final S Function(Bits) constructor; // final S Function(BitsBase) caster;
  final BitsBase buffer; // may be shared

  @override
  Bits get bits => buffer.bits;
  @override
  set bits(Bits value) => buffer.bits = value; // mutable if base is mutable

  S createBuffer() {
    return constructor(bits);
    // return caster(MutableBits(bits)) ;
  }

  S castView(BitsBase base) => constructor(base.bits);

  @override
  S copyWithBits(Bits value) => constructor(value);

  // @override
  // BitConstruct<S, K> copyWith() => BitConstruct<S, K>(keys, bits);

  // @override
  // S withField(K key, int value) => copyWithBits(bits.withBits(key.bitmask, value));
  // @override
  // BitConstruct<S, K> withEntries(Iterable<MapEntry<K, int>> entries) =>
  // @override
  // BitConstruct<S, K> withAll(Map<K, int> map) =>
}
