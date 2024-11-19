 

// abstract class BitsMapBase<K extends Enum, V> = BitsBase with MapBase<K, V>, EnumMap<K, V>, BitsMapMixin<K, V>;
// internal use only, todo split struct and map
// abstract class MutableBitsStructBase<T extends Enum, V> = MutableBits with MapBase<T, V>, EnumMap<T, V>, BitsMapBase<T, V>;
// abstract class ConstBitsStructBase<T extends Enum, V> = ConstBits with MapBase<T, V>, EnumMap<T, V>, BitsMapBase<T, V>;

// /// Maps contain Keys as final field
// abstract class MutableBitsMap<T extends Enum, V> extends MutableBits with MapBase<T, V>, EnumMap<T, V>, BitsMapBase<T, V> {
//   MutableBitsMap(this.keys, [super.bits]);
//   MutableBitsMap.castBase(BitsMapBase<T, V> super.state)
//       : keys = state.keys,
//         super.castBase();

//   @override
//   final List<T> keys;
// }

// @immutable
// abstract class ConstBitsMap<T extends Enum, V> extends ConstBits with MapBase<T, V>, EnumMap<T, V>, BitsMapBase<T, V> {
//   const ConstBitsMap(this.keys, super.bits);
//   ConstBitsMap.castBase(BitsMapBase<T, V> super.state)
//       : keys = state.keys,
//         super.castBase();

//   // const ConstBitsMap.index(List<IndexField> this.keys, super.bits);

//   @override
//   final List<T> keys;
// }
 