/// Settings management library for the CMDR package.
///
/// This library provides a comprehensive settings system with support for
/// persistent storage, type-safe settings, and reactive updates.
///
/// ## Features
///
/// - Type-safe setting definitions
/// - Automatic persistence to storage
/// - Reactive setting controllers
/// - Flutter integration with settings views
///
/// ## Usage
///
/// ```dart
/// import 'package:cmdr/settings.dart';
///
/// // Define a setting
/// final mySetting = Setting<String>('my_key', defaultValue: 'default');
///
/// // Use settings controller
/// final controller = SettingsController(SettingsService());
/// ```
library cmdr.settings;

export 'settings/setting.dart';
export 'settings/settings_controller.dart';
export 'settings/settings_service.dart';
export 'settings/settings_view.dart';
