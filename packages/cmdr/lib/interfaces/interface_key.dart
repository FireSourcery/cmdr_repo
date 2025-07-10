import 'package:cmdr/var_notifier.dart';
import 'package:type_ext/basic_types.dart';

/// Union of generic types
// A primitive union type key
// Key `to` a generic value
// boundary depending on type
// GenericRetriverKey
// abstract mixin class UnionValueKey<V> implements TypeKey<V> {
//   const UnionValueKey();

//   List<Enum>? get valueEnumRange; // EnumSubtype.values must be non-null for Enum types
//   // Iterable<V>? get valuEnumRange;
//   // Limits as the values the num can take, inclusive, compare with >= and <=
//   ({num min, num max})? get valueNumLimits; // must be null for non-num types

//   V? get valueDefault;

//   V get value;
//   set value(V newValue);

//   // num get valueAsNum;

//   // set valueAsNum(num newValue) {
//   //   // assert(V == int || V == double, 'Only num types are supported');
//   //   if (valueNumLimits != null) {
//   //     value = newValue.clamp(valueNumLimits!.min, valueNumLimits!.max) as V;
//   //   }
//   // }

//   // set valueAsEnum(Enum newValue) {
//   //   if (valueEnumRange != null) {
//   //     if (valueEnumRange!.contains(newValue)) value = newValue as V;
//   //   }
//   // }

//   // move check limits here
// }

// abstract mixin class NumValue {
//   List<Enum>? get valueEnumRange;
//   ({num min, num max})? get valueNumLimits;
//   List<BitField>? get bitsKeys;

//   num _value = 0;
// }

// ServiceKey for retrieving data of dynamic type from external source and casting
// IdKey, EntityKey, DataKey, FieldKey, VarKey,
// abstract mixin class ServiceKey<K, V> implements UnionValueKey<V> {
//   K get key;
//   String get label;
//   // Stringifier? get valueStringifier;

//   // a serviceKey can directly access the value with a provided reference to service
//   // ServiceIO? get service;
//   // V? get value => service?.get(keyValue);
//   // alternatively as V always return a cached value
//   // V? get value;
//   // set value(V? newValue);

//   Future<V?> loadValue();
//   Future<void> updateValue(V value);
//   // Future<bool> updateValue(V value);
//   String get valueString;

//   // void setValueAsNum(num newValue) {
//   //   if (valueNumLimits != null) {
//   //     // assert(V == int || V == double, 'Only num types are supported');
//   //     value = newValue.clamp(valueNumLimits!.min, valueNumLimits!.max) as V;
//   //   }
//   // }

//   // void setValueAsEnum(Enum newValue) {
//   //   if (valueEnumRange != null) {
//   //     value = valueEnumRange!.contains(newValue) ? newValue as V : valueDefault;
//   //   }
//   // }

//   // Type get type;
//   // TypeKey<V> get valueType => TypeKey<V>();
// }
