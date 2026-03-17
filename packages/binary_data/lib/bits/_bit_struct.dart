import 'package:meta/meta.dart';

import 'package:binary_data/data/index_map.dart';
import 'package:binary_data/data/struct.dart';

import 'bit_field.dart';
import 'bits_map.dart';

export 'bit_field.dart';
export 'bits_map.dart';

////////////////////////////////////////////////////////////////////////////////
/// [Bits] + [BitField] keys, [] operators, returning [int]
///
/// [BitsMap] - a version of Map with [Bits] as source. Does not need to be extended in most cases
///
/// sufficent for iterative access, common serialization
////////////////////////////////////////////////////////////////
extension type const BitStruct<K extends BitField>(BitData bits) implements BitData, Structure<K, int> {}

// Keys list effectively define type and act as factory
// factories returning as super interface type
// Separates subtype `class variables` from instance
extension type const BitStructType<K extends BitField>(List<K> _fields) implements StructureType<K, int> {
  // BitStructBase<K> castData(BitData base) {
  // }

  // BitStruct<K> castBits(int value) => _BitStruct<K>(keys, Bits(value));

  // unmodifiableView
  // BitStruct<T> view(int value) => _BitStruct<T>(keys, Bits(value));

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
  // BitStruct encode(int value) => BitStruct.view(this, value as Bits);
  // int decode(BitStruct bits) => bits.value;

  Bitmasks get bitmasks => _fields.map((e) => e.bitmask) as Bitmasks;
  int get totalWidth => bitmasks.totalWidth;

  // Bits mapValues(List<int> values) {
  //   if (_fields.length != values.length) throw ArgumentError('Values length ${values.length} does not match BitFields length ${_fields.length}');

  //   return Bits.ofPairs(_fields.mapIndexed((index, e) => (e.bitmask, values[index])));
  // }
}

/// [BitStructBase] Interface for extending with Subtypes
///   Struct must be extended with Keys
///   Partial Map implementation with [Bits] as source
///
/// /// wrapper with key access, Map interface,
/// [Map<Enum, int>] mixin provides serialization
///   MapBase<K, int> must be mixed in first.
///
abstract class BitStructBase<T extends BitStructBase<T, K>, K extends BitField> with MapBase<K, int>, BitFieldMap<K>, StructureBase<T, K, int> {
  const BitStructBase(this.bitData); //  base class enforce data implementation. ensure correct correspondance with remote devices

  final BitData bitData; // handle mutability, can be wrapped for const and mutable versions

  // BitStruct-specific methods
  List<K> get keys;
  // List<K> get fields; keep keys as Iterable for compatibility with const map initializer

  BitStruct<K> get data => bitData as BitStruct<K>;

  Bits get bits => bitData.bits;
  int get width => keys.bitmasks.totalWidth;

  //other functions implemented by StructureBase and BitFieldMap

  //
  // Iterable<({K key, bool value})> get fieldsAsBool => keys.map((e) => (key: e, value: (this[e] != 0)));
  // Iterable<({K key, int value})> get fieldsAsBits => keys.map((e) => (key: e, value: this[e]));

  // optionally override to keep int as data implementation
  @override
  Map<K, int> toMap() => BitsMap.of(keys, bits);

  /// returned instance is immutable
  /// override to return a subtype
  BitStructBase copyWithBits(Bits value) => _BitStruct(keys, BitData.constant(value));

  /// mixn to override [copyWithBits]/copyWith to return a subtype
  /// Subtype considerations:
  /// to return a subtype,[S extends BitStruct<K>]:
  ///   provide the constructor of the subtype
  ///   use a prototype object copyWith(), which calls the constructor of the subtype
  T copyWith();

  // returns  BitStructBase<BitStructBase<T, K>, K>  or T
  @override
  withField(K key, int value) => copyWithBits(bits.withBits(key.bitmask, value)); //.copyWith();
  @override
  withEntries(Iterable<MapEntry<K, int>> entries) => copyWithBits(bits.withEach(entries.map((e) => (e.key.bitmask, e.value))));
  @override
  withMap(Map<K, int> map) => withEntries(map.entries);

  @override
  String toString() => toStringAsMap();

  String toStringAsMap() => MapBase.mapToString(this); // {key: 0, key: 0,}
  String toStringAsValues() => values.toString(); // (0, 0, 0)

  MapEntry<String, int> toStringMapEntry([String? name]) => MapEntry<String, int>(name ?? K.toString(), bits); // {name: value}

  /// bitfields compare by value
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BitStructBase<T, K>) return false;
    // keys are not copied, so they must match
    // (other.keys == keys) || other is BitsInitializer<K>
    return (other.bits == bits);
  }

  @override
  int get hashCode {
    return keys.hashCode ^ bits.hashCode;
  }
}

/// concrete pair return
/// passing keys
@immutable
base class _BitStruct<K extends BitField> extends BitStructBase<_BitStruct<K>, K> {
  const _BitStruct(this.keys, super.value);
  @override
  final List<K> keys;

  @override
  set bits(Bits value) => throw UnsupportedError('Cannot modify unmodifiable');

  @override
  copyWith() => this;
}

///
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
// typedef _BitsInitializer<K extends BitField> = Map<K, int>;

// @immutable
// final class BitsInitializer<K extends BitField> with  MapBase<K, int>, BitFieldMap<K> implements BitStructBase<BitsInitializer<K>, K> {
//   const BitsInitializer(this._init);
//   final _BitsInitializer<K> _init;
//   @override
//   Iterable<K> get keys => _init.keys;
//   @override
//   Bits get bits => _init; // in order to init using const Map, bits must be derived at run time
//   @override
//   set bits(Bits value) => throw UnsupportedError('Cannot modify unmodifiable');

//   V operator [](K key) => key.getIn(_this);
//   void operator []=(K key, V value) => key.setIn(_this, value);

//   // `field` referring to the field value
//   V field(K key) => key.getIn(_this);
//   void setField(K key, V value) => key.setIn(_this, value);


//   // @override
//   // String toString() => toStringAsMap();
  
//   @override
//   // TODO: implement width
//   int get width => throw UnimplementedError();
// }
