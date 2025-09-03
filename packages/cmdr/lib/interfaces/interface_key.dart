import 'package:cmdr/var_notifier.dart';
import 'package:type_ext/basic_types.dart';

import 'dart:convert';

/// Union of generic types
// A primitive union type key
// boundary depending on type
// abstract mixin class NumUnion {
// num get valueNum   ;
//   List<Enum>? get valueEnumRange;
//   ({num min, num max})? get valueNumLimits;
//   List<BitField>? get bitsKeys;
// }

// abstract mixin class   {
//   // Limits as the values the num can take, inclusive, compare with >= and <=
//   ({num min, num max})? get numLimits; // must be null for non-num types
//   List<Enum>? get enumRange; // EnumSubtype.values must be non-null for Enum types
//   List<BitField>? get bitsKeys;
// }

// ServiceKey for retrieving data of dynamic type from external source and casting
// IdKey, EntityKey, DataKey, FieldKey, VarKey,
// abstract mixin class ServiceKey<K, V> implements UnionViewer<V, Object> {
//   K get key;
//   String get label;
//   // Stringifier? get valueStringifier;

//   // directly access the value with a provided reference to service
//   // ServiceIO? get service;
//   // V? get value => service?.get(keyValue);
//   // alternatively as V always return a cached value
//   // V? get value;
//   // set value(V? newValue);

//   Future<V?> getValue();
//   Future<void> setValue(V value);
//   // Future<V?> loadValue();
//   // Future<void> updateValue(V value);
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

// class WidgetUnionData<T> {
//   const WidgetUnionData({
//     this.idDecoration = const InputDecoration(),
//     this.isReadOnly = false, // alternatively move this to constructor parameter
//     this.tip = '',
//     required this.valueListenable,
//     required this.valueGetter,
//     this.valueSetter,
//     this.errorGetter,
//     this.valueStringGetter,
//     this.valueStringifier,
//     this.valueEnumRange,
//     this.valueNumLimits,
//     this.sliderChanged,
//     this.useSliderBorder = false,
//     this.useSwitchBorder = true,
//     this.boolStyle = IOFieldBoolStyle.latchingSwitch,
//   }) : assert(!((T == num || T == int || T == double) && (valueNumLimits == null && valueEnumRange == null)));

//   final InputDecoration idDecoration; // using input decoration to hold label fields
//   final bool isReadOnly;
//   final String tip;

//   /// using ListenableBuilder for cases where value is not of the same type as valueListenable
//   final Listenable valueListenable; // read/output update
//   final ValueGetter<T?> valueGetter;
//   final ValueSetter<T>? valueSetter;

//   final ValueGetter<bool>? errorGetter; // true on error

//   // value string precedence: valueStringGetter > valueStringifier > valueGetter().toString()
//   final ValueGetter<String>? valueStringGetter;
//   final Stringifier<T>? valueStringifier; // for enum and other range bound types

//   final ({num min, num max})? valueNumLimits; // required for num type, slider and input range check on submit
//   final List<Enum>? valueEnumRange; // enum or String selection, alternatively type as enum only

//   final ValueChanged<T>? sliderChanged; // slider

//   // final bool useSliderBorder;
//   // final bool useSwitchBorder;
//   // final IOFieldBoolStyle boolStyle;
// }
