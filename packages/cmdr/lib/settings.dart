/// Settings management library for the CMDR package.
///
/// This library provides a comprehensive settings system with support for
/// persistent storage, type-safe settings, and reactive updates.
///
/// ```dart
/// import 'package:cmdr/settings.dart';
///
/// // Settings are an enum with SharedPrefSetting, each member a typed key
/// enum AppSetting<T>() with SharedPrefSetting<T> { ... }
///
/// // The controller updates and persists them, and notifies its listeners
/// final controller = SettingsController();
/// ```
library;

export 'settings/setting.dart';
export 'settings/settings_controller.dart';
export 'settings/settings_service.dart';
export 'settings/settings_view.dart';
