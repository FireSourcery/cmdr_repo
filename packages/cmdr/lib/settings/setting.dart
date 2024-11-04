//with TypedKey
abstract interface class Setting<V> {
  String get key;
  String get valueString;
  List<V>? get enumValues; // must be non-null for Enum types
  ({num min, num max})? get numLimits; // must be null for non-num types
  // T? get defaultValue;

  String get label;

  Type get type;
  V? get value;
  set value(V? value);
  Future<bool> updateValue(V value);
  // Future<V?> loadValue();

  R callWithType<R>(R Function<G>() callback);
}


// enum ExampleSetting<T> with SettingBase<T> {
//   wheelDiameter<double>(),
//   ;
//   const ExampleSetting( )  ;
//   final List<Enum>? enumValues;
//   String get key => name;

//   @override
//   String get name => key;

//   @override
//   List<Enum>? get enumValues => null;

//   @override
//   (num, num)? get viewMinMax => null;

//   @override
//   set value(T? value) {
//     // Implement the setter logic here.
//   }
// }
