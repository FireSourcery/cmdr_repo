// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

import '../widgets/io_field/io_field.dart';
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
      const Spacer(),
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

class SettingWidgetsList extends StatelessWidget {
  const SettingWidgetsList({super.key, required this.settingsController, required this.settings});

  final SettingsController settingsController;
  final List<Setting> settings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(5),
      children: [for (final setting in settings) SettingFieldTile(setting: setting, settingsController: settingsController)],
    );
  }
}

// auto typed IOField + others
abstract class SettingTypedWidget extends StatelessWidget {
  // const SettingTypedWidget._({required this.setting, required this.settingsController, super.key});
  // final Setting setting;
  // final SettingsController settingsController;

  // auto typed using Setting Type
  factory SettingTypedWidget({required Setting setting, required SettingsController settingsController, Key? key}) {
    // if (setting.enumRange != null) {
    //   return setting.callWithType(<G>() => SettingMenu<G>(setting: setting as Setting<G>, settingsController: settingsController) as SettingMenu<T>);
    // }
    // return setting.callWithType(<G>() => SettingTextField<G>(setting: setting as Setting<G>, settingsController: settingsController) as SettingTextField<T>);

    _SettingTypedWidget<V> local<V>() {
      final config = IOFieldConfig<V>(
        valueListenable: settingsController,
        valueGetter: () => setting.value as V?,
        valueNumLimits: setting.numLimits,
        valueEnumRange: setting.valueRange as List<V>?,
        valueSetter: (value) async => await settingsController.updateSetting<V>(setting as Setting<V>, value),
        // label: setting.label,
        // valueStringGetter: () => setting.valueString,
        valueStringifier: (setting is Setting<Enum>) ? (value) => (value as Enum).name.titleCase : (value) => value.toString(),
        tip: setting.tip ?? '',
      );
      return _SettingTypedWidget<V>(config);
    }

    return setting.callWithType(<G>() => local<G>() as SettingTypedWidget);
  }
  // static String _stringify(Object value) => value.toString();
  // static String _stringifyEnum(Enum value) => value.name.titleCase;
}

class _SettingTypedWidget<V> extends StatelessWidget implements SettingTypedWidget {
  const _SettingTypedWidget(this.config, {super.key});
  final IOFieldConfig<V> config;

  @override
  Widget build(BuildContext context) {
    return IOField<V>(config);
  }
}

//to move to io field
// class SettingTextField<T> extends SettingTypedWidget<T> {
//   const SettingTextField({required super.setting, required super.settingsController, super.key}) : super._();

//   @override
//   Widget build(BuildContext context) {
//     return IOFieldText<T>(
//       listenable: settingsController,
//       valueGetter: () => setting.value,
//       valueSetter: (value) => settingsController.updateSetting<T>(setting, value),
//       decoration: const InputDecoration().applyDefaults(Theme.of(context).inputDecorationTheme).copyWith(isDense: true),
//       numLimits: setting.numLimits,
//       // numMax: setting.numLimits?.max,
//       // numMin: setting.numLimits?.min,
//       tip: setting.label,
//     );
//   }
// }

// //change enum to T for with selection set
// /// PopupMenu
// class SettingMenu<T> extends SettingTypedWidget<T> {
//   const SettingMenu({required super.setting, required super.settingsController, super.key}) : super._();

//   @override
//   Widget build(BuildContext context) {
//     String string(T value) => switch (value) { Enum() => value.name.titleCase, _ => value.toString() };

//     return IOFieldMenu<T>(
//       decoration: const InputDecoration().applyDefaults(Theme.of(context).inputDecorationTheme).copyWith(isDense: true),
//       listenable: settingsController,
//       valueGetter: () => setting.value,
//       valueSetter: (value) async => await settingsController.updateSetting<T>(setting, value),
//       // stringMap: {for (var e in setting.enumValues ?? []) e: string(e)},
//       valueEnumRange: setting.enumRange! as List<T>,
//       tip: setting.label,
//     );
//   }
// }

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

/// move to io field
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
