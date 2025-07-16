import 'setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences Service
// SharedPreferencesRepository
// Wrap with type parameter get/set and init
// class SettingsService with ChangeNotifier {
class SharedPrefService {
  SharedPrefService._();
  static final SharedPrefService main = SharedPrefService._();
  factory SharedPrefService() => main;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance(); // loads the SharedPreferences cache
  late final SharedPreferences prefs;
  // final ValueNotifier<Setting> notifier = ValueNotifier<Setting>( );

  Future<void> init(/* {String? prefix} */) async => (prefs = await _prefs);

  R? get<R>(String key) => prefs.get(key) as R?;

  R? getEnum<R>(String key, List<R> values) {
    if (prefs.getInt(key) case int index) return values.elementAtOrNull(index);
    return null;
  }

  Future<bool> setAsync<T>(String key, T value) {
    return switch (T) {
      const (int) => prefs.setInt(key, value as int),
      const (double) => prefs.setDouble(key, value as double),
      const (bool) => prefs.setBool(key, value as bool),
      const (String) => prefs.setString(key, value as String),
      const (List<String>) => prefs.setStringList(key, value as List<String>),
      // const (Enum) => prefs.setInt(key, (value as Enum).index),
      _ => throw UnsupportedError('$T'),
    };
  }

  Future<bool> setEnumAsync(String key, Enum value) => prefs.setInt(key, value.index);

  // calling without await will set that cached value
  // do not await propagate to disk, process up to _preferenceCache[key] = value;
  // void set<T>(String key, T value) => _setAsync<T>(key, value);

  // updateAll()
  // loadAll(
}

// abstract interface class Setting<T>  = ServiceKey<T> UnionValueKey<V>

// SettingBase using SharedPreferences
abstract mixin class SharedPrefSetting<T> implements Setting<T> {
  String get key;

  @override
  List<T>? get valueRange; // Enum or options set
  @override
  ({num min, num max})? get numLimits;
  // T get defaultValue;

  // String get key => name; // if implements enum
  @override
  String get label;
  @override
  String get valueString;

  @override
  Type get type => T;
  @override
  R callWithType<R>(R Function<G>() callback) => callback<T>();

  @override
  T? get value {
    return switch (T) {
      const (bool) || const (int) || const (double) || const (String) || const (List<String>) => SharedPrefService.main.get<T>(key),
      const (Enum) => SharedPrefService.main.getEnum<T>(key, valueRange!),
      _ => throw UnsupportedError('$T'),
    };
  }

  // not needed if all settings are loaded at once in the case of sharedPreferences, may keep interface for network settings
  @override
  Future<T?> load() async => value;

  num _boundNum(num newValue) {
    assert(T == int || T == double);
    return (numLimits != null) ? newValue.clamp(numLimits!.min, numLimits!.max) : newValue;
  }

  @override
  set value(T? newValue) {
    if (newValue != null) update(newValue);
  }

  @override
  Future<bool> update(T value) async {
    // return SettingsService.main.update<T>(key, _boundValue(value));
    return switch (T) {
      const (int) || const (double) => SharedPrefService.main.setAsync<T>(key, _boundNum(value as num) as T),
      const (bool) || const (String) || const (List<String>) => SharedPrefService.main.setAsync<T>(key, value),
      const (Enum) => SharedPrefService.main.setEnumAsync(key, value as Enum),
      _ => throw UnsupportedError('$T'),
    };
  }
}
