import 'package:flutter/material.dart';

import 'setting.dart';

class SettingsController with ChangeNotifier {
  SettingsController();

  /// Update view without waiting, guarantee of persisting
  void updateSettingView<T>(Setting<T> setting, T value) {
    setting.value = value;
    notifyListeners();
  }

  /// Update and persist the settings.
  Future<void> updateSetting<T>(Setting<T> setting, T value) async {
    await setting.updateValue(value);
    notifyListeners();
  }

  // final List<Setting> settings;
  /// local cache for page
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
