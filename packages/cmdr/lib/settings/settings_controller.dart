import 'package:flutter/material.dart';

import 'setting.dart';

class SettingsController with ChangeNotifier {
  SettingsController();

  /// Update and persist the settings.
  Future<void> updateSetting<T>(Setting<T> setting, T value) async {
    await setting.update(value);
    notifyListeners();
  }

  /// local cache for page
  // final List<Setting> settings;
  // final Map<Setting, Object?> _notifierMap = {for (final setting in Setting.values) setting: null};
  // R? viewValueOf<R>(Setting<R> setting) => _notifierMap[setting] as R;

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
