import 'package:flutter/material.dart';

import 'setting.dart';

/// Common interface for setting/settings.

// per setting interface
// abstract interface class Setting<V> {
// }

// common notifier for settings + collective update

class SettingsController with ChangeNotifier {
  SettingsController();

  // final List<Setting> settings;

  /// Update and persist the settings.
  Future<void> updateSetting<T>(Setting<T> setting, T value) async {
    await setting.update(value);
    notifyListeners();
  }

  /// local cache for page
  // final Map<Setting, Object?> _notifierMap = {for (final setting in Setting.values) setting: null};
  // R? viewValueOf<R>(Setting<R> setting) => _notifierMap[setting] as R;

// abstract or pass service
  // /// Update all
  // Future<void> updateSettings() async {
  // }

  // Future<void> loadSettings() async {
  //   // SettingsService.main.init();
  //   // for (final setting in Setting.values) {
  //   //   _notifierMap[setting] = setting.value;
  //   // }
  //   notifyListeners();
  // }
}
