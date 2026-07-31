import 'package:flutter/material.dart';

import 'setting.dart';

// common notifier for settings + collective update

class SettingsController with ChangeNotifier {
  SettingsController();

  // final List<Setting> settings;

  /// Update and persist the settings. A null value is ignored by [Setting.update].
  Future<void> updateSetting<T>(Setting<T> setting, T? value) async {
    await setting.update(value);
    notifyListeners();
  }

  // Future<void> loadSettings() async {
  //   // SettingsService.main.init();
  //   // for (final setting in Setting.values) {
  //   //   _notifierMap[setting] = setting.value;
  //   // }
  //   notifyListeners();
  // }
}
