import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kelly_user_app/src/main/pages/pages.dart';
import 'package:kelly_user_app/src/mot_var/model/string_labels.dart';

import '../widgets/io_field.dart';
import 'setting.dart';
import 'settings_controller.dart';

class SettingFieldTile extends StatelessWidget {
  const SettingFieldTile({required this.setting, required this.settingsController, super.key});

  final Setting<dynamic> setting;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(setting.label, style: Theme.of(context).textTheme.bodyLarge),
      Spacer(),
      LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            // width: constraints.maxWidth / 2,
            width: 150,
            child: SettingTypedWidget(setting: setting, settingsController: settingsController),
          );
        },
      ),
    ]);
    // return ListTile(
    //   title: Text(setting.label),
    //   // contentPadding: const EdgeInsets.all(5),
    //   // subtitle: Text(setting.description),
    //   // subtitle: Row(children: [Text(setting.value.toString()), Expanded(child: SettingTypedWidget(setting: setting, settingsController: settingsController))]),
    //   trailing: LayoutBuilder(
    //     builder: (context, constraints) {
    //       return SizedBox(
    //         // width: constraints.maxWidth / 2,
    //         width: 150,
    //         child: SettingTypedWidget(setting: setting, settingsController: settingsController),
    //       );
    //     },
    //   ),
    // );
  }
}

abstract class SettingTypedWidget<T> extends StatelessWidget {
  const SettingTypedWidget._({required this.setting, required this.settingsController, super.key});
  final Setting<T> setting;
  final SettingsController settingsController;

  // auto typed using Setting Type
  factory SettingTypedWidget({required Setting<T> setting, required SettingsController settingsController, Key? key}) {
    if (setting.enumValues != null) {
      return setting.callWithType(<G>() => SettingMenu<G>(setting: setting as Setting<G>, settingsController: settingsController) as SettingMenu<T>);
    }
    return setting.callWithType(<G>() => SettingTextField<G>(setting: setting as Setting<G>, settingsController: settingsController) as SettingTextField<T>);
    // return switch (setting.type) {
    //   // _ when (setting.enumValues != null) => SettingMenu<T>(setting: setting as Setting<T>, settingsController: settingsController),
    //   // const (int) || const (double) || const (num) => SettingSlider<T>(setting: setting, settingsController: settingsController),
    //   const (int) => SettingTextField<int>(setting: setting as Setting<int>, settingsController: settingsController),
    //   const (double) => SettingTextField<double>(setting: setting as Setting<double>, settingsController: settingsController),
    //   // const (bool) => SettingSwitch(setting: setting as Setting<bool>, settingsController: settingsController),
    //   const (Enum) => SettingMenu<Enum>(setting: setting as Setting<Enum>, settingsController: settingsController),
    //   const (String) => SettingTextField<String>(setting: setting as Setting<String>, settingsController: settingsController),
    //   _ => throw UnsupportedError('$T'),
    // } as SettingTypedWidget<T>;
  }
}

//to move to io field
class SettingTextField<T> extends SettingTypedWidget<T> {
  const SettingTextField({required super.setting, required super.settingsController, super.key}) : super._();

  @override
  Widget build(BuildContext context) {
    return IOFieldText<T>(
      listenable: settingsController,
      valueGetter: () => setting.value,
      valueSetter: (value) => settingsController.updateSetting<T>(setting, value),
      decoration: const InputDecoration().applyDefaults(Theme.of(context).inputDecorationTheme).copyWith(isDense: true),
      numMax: setting.numLimits?.max,
      numMin: setting.numLimits?.min,
      tip: setting.key,
    );
  }
}

//change enum to T for with selection set
/// PopupMenu
class SettingMenu<T> extends SettingTypedWidget<T> {
  const SettingMenu({required super.setting, required super.settingsController, super.key}) : super._();

  @override
  Widget build(BuildContext context) {
    String string(T value) => switch (value) { Enum() => value.name.toTitleCase(), _ => value.toString() };

    return IOFieldMenu<T>(
      decoration: const InputDecoration().applyDefaults(Theme.of(context).inputDecorationTheme).copyWith(isDense: true),
      listenable: settingsController,
      valueGetter: () => setting.value,
      valueSetter: (value) async => await settingsController.updateSetting<T>(setting, value),
      stringMap: {for (var e in setting.enumValues ?? []) e: string(e)},
      tip: setting.key,
    );

    // List<PopupMenuEntry<Enum>> entries(BuildContext context) => [for (final entry in setting.enumValues!) PopupMenuItem(value: entry, child: Text(entry.name.toTitleCase()))];
    // return PopupMenuButton<Enum>(
    //   itemBuilder: entries,
    //   initialValue: setting.value,
    //   enabled: true,
    //   onSelected: (value) => settingsController.updateSetting(setting, value),
    //   clipBehavior: Clip.hardEdge,
    //   child: ListenableBuilder(
    //     listenable: settingsController,
    //     builder: (context, child) => InputDecorator(
    //       decoration: const InputDecoration().applyDefaults(Theme.of(context).inputDecorationTheme).copyWith(isDense: true),
    //       child: Text(setting.value?.name.toTitleCase() ?? '', style: Theme.of(context).textTheme.bodyMedium),
    //     ),
    //   ),
    // );
  }
}

// class SettingSlider<T extends num> extends SettingTypedWidget<T> {
//   const SettingSlider({required super.setting, required super.settingsController, super.key}) : super._();

//   T formatValue(double value) => switch (T) { const (int) => value.toInt(), const (double) => value, _ => throw TypeError() } as T;

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: settingsController,
//       builder: (context, child) {
//         return Slider.adaptive(
//           label: setting.label,
//           min: setting.numBounds?.min.toDouble() ?? 0,
//           max: setting.numBounds?.max.toDouble() ?? 1,
//           value: setting.value?.toDouble() ?? 0,
//           divisions: switch (T) {
//             const (int) => setting.numBounds!.max.toInt() - setting.numBounds!.min.toInt(),
//             const (double) => null,
//             _ => throw TypeError(),
//           },
//           onChanged: (value) => setting.value = formatValue(value),
//           onChangeEnd: (value) async => await setting.updateValue(formatValue(value)),
//           // switch (T) {
//           //   const (int) => ((value) => setting.value = value.toInt() as T),
//           //   const (double) => ((value) => setting.value = value as T),
//           //   Type() => throw UnimplementedError(),
//           // },
//           // switch (T) {
//           //   const (int) => ((value) async => await setting.updateValue(value.toInt() as T)),
//           //   const (double) => ((value) async => await setting.updateValue(value as T)),
//           //   Type() => throw UnimplementedError(),
//           // },
//         );
//       },
//     );
//   }
// }

// class SettingSwitch extends SettingTypedWidget<bool> {
//   const SettingSwitch({required super.setting, required super.settingsController, super.key}) : super._();

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: settingsController,
//       builder: (context, child) => Switch.adaptive(value: setting.value as bool, onChanged: ((value) async => await setting.updateValue(value))),
//     );
//   }
// }

// class SettingRadioTile extends SettingTypedWidget<Enum> {
//   const SettingRadioTile({required super.setting, required super.settingsController, super.key}) : super._();

//   @override
//   Widget build(BuildContext context) {
//     retur
//     return ListenableBuilder(
//       listenable: settingsController,
//       builder: (context, child) => Switch.adaptive(value: setting.value as bool, onChanged: ((value) async => await setting.updateValue(value))),
//     );
//   }
// }

// class SettingTextTile<T> extends SettingTypedWidget<T> {
//   const SettingTextTile({required super.setting, required super.settingsController, super.key}) : super._();

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: settingsController,
//       builder: (context, child) => Switch.adaptive(value: setting.value as bool, onChanged: ((value) async => await setting.updateValue(value))),
//     );
//   }
// }

// class SettingButton extends SettingTypedWidget<bool> {
//   const SettingButton({required super.setting, required super.settingsController, super.key}) : super._();
// }
