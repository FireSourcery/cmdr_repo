//with TypedKey
abstract interface class Setting<T> {
  String get key;
  String get valueString;
  List<T>? get enumValues; // must be non-null for Enum types
  ({num min, num max})? get numLimits; // must be null for non-num types
  // T? get defaultValue;

  String get label;

  Type get type;
  T? get value;
  set value(T? value);
  Future<bool> updateValue(T value);

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
