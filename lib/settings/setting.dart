import 'settings_service.dart';

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

// SettingBase using SharedPreferences
// can be inherited by enums
abstract mixin class SettingBase<T> implements Setting<T> {
  String get key;
  List<T>? get enumValues; // Enum or options set
  ({num min, num max})? get numLimits;
  // T get defaultValue;

  // String get key => name; // if implements enum
  String get label;
  String get valueString;

  @override
  Type get type => T;

  @override
  T? get value {
    return switch (T) {
      const (bool) || const (int) || const (double) || const (String) || const (List<String>) => SettingsService.main.get<T>(key),
      const (Enum) => SettingsService.main.get<T>(key, enumValues!),
      _ => throw UnsupportedError('$T'),
    };
  }

  // not needed if all settings are loaded at once in the case of sharedPreferences, may use interface for network settings
  // T? load() {
  //   return switch (T) {
  //     const (bool) || const (int) || const (double) || const (String) || const (List<String>) => SettingsService.main.load<T>(key),
  //     const (Enum) => SettingsService.main.loadEnum(key, enumValues!),
  //     _ => throw UnsupportedError(''),
  //   } as T;
  // }

  // bool isBound(num newValue) => (newValue.clamp(numLimits!.min, numLimits!.max) == newValue);

  T _boundValue(T newValue) {
    if (numLimits == null) return newValue;
    assert(T == int || T == double, 'Only num types are supported');
    return (newValue as num).clamp(numLimits!.min, numLimits!.max) as T;
    // final clamped = (newValue as num).clamp(numLimits!.min, numLimits!.max);
    // return switch (T) { const (int) => clamped.toInt(), const (double) => clamped.toDouble(), _ => newValue } as T;
  }

  @override
  set value(T? newValue) => (newValue != null) ? SettingsService.main.set<T>(key, _boundValue(newValue)) : null;

  @override
  Future<bool> updateValue(T value) async => await SettingsService.main.update<T>(key, _boundValue(value));

  @override
  R callWithType<R>(R Function<G>() callback) => callback<T>();
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
