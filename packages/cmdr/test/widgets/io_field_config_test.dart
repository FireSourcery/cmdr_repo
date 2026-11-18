import 'package:cmdr/var_notifier/var_notifier.dart';
import 'package:cmdr/var_notifier/widgets/var_io_field.dart';
import 'package:cmdr/widgets/io_field/io_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:struct_data/struct_data.dart';

import '../fakes/fake_service_io.dart';

void _setter(int _) {}
void _changed(int _) {}
void _replacedSetter(int _) {}
void _replacedChanged(int _) {}

/// Every [IOFieldConfig] field, each getter by the value it returns, so a copy compares equal to its original.
Map<String, Object?> fieldsOf(IOFieldConfig<int> config) => {
  'idDecoration': config.idDecoration,
  'isReadOnly': config.isReadOnly,
  'tip': config.tip,
  'valueListenable': config.valueListenable,
  'valueGetter': config.valueGetter(),
  'valueSetter': config.valueSetter,
  'errorGetter': config.errorGetter?.call(),
  'valueStringifier': config.valueStringifier?.call(7),
  'valueEnumRange': config.valueEnumRange,
  'valueNumLimits': config.valueNumLimits,
  'valueChanged': config.valueChanged,
  'useSwitchBorder': config.useSwitchBorder,
  'boolStyle': config.boolStyle,
};

/// Pins [IOFieldConfig.copyWith] on both configs: it mirrors the constructor, field for field.
void main() {
  final replacedListenable = ValueNotifier(0);

  /// Per field: the copy that replaces it, and the replacement as [fieldsOf] reads it; each differs from both originals.
  final copies = <String, (IOFieldConfig<int> Function(IOFieldConfig<int> config), Object?)>{
    'idDecoration': ((config) => config.copyWith(idDecoration: const InputDecoration(labelText: 'Setpoint')), const InputDecoration(labelText: 'Setpoint')),
    'isReadOnly': ((config) => config.copyWith(isReadOnly: false), false),
    'tip': ((config) => config.copyWith(tip: 'replaced'), 'replaced'),
    'valueListenable': ((config) => config.copyWith(valueListenable: replacedListenable), replacedListenable),
    'valueGetter': ((config) => config.copyWith(valueGetter: () => 42), 42),
    'valueSetter': ((config) => config.copyWith(valueSetter: _replacedSetter), _replacedSetter),
    'errorGetter': ((config) => config.copyWith(errorGetter: () => true), true),
    'valueStringifier': ((config) => config.copyWith(valueStringifier: (_) => 'replaced'), 'replaced'),
    'valueEnumRange': ((config) => config.copyWith(valueEnumRange: const [3, 4]), const [3, 4]),
    'valueNumLimits': ((config) => config.copyWith(valueNumLimits: (min: -5, max: 5)), (min: -5, max: 5)),
    'valueChanged': ((config) => config.copyWith(valueChanged: _replacedChanged), _replacedChanged),
    'useSwitchBorder': ((config) => config.copyWith(useSwitchBorder: false), false),
    'boolStyle': ((config) => config.copyWith(boolStyle: IOFieldBoolStyle.momentaryButton), IOFieldBoolStyle.momentaryButton),
  };

  void expectCopyWith(String description, IOFieldConfig<int> Function() original) {
    group(description, () {
      test('copyWith() carries every field', () {
        final config = original();
        expect(fieldsOf(config.copyWith()), fieldsOf(config));
      });

      for (final MapEntry(key: field, value: (copy, replacement)) in copies.entries) {
        test('copyWith($field:) replaces $field only', () {
          final config = original();
          expect(fieldsOf(copy(config)), {...fieldsOf(config), field: replacement});
        });
      }
    });
  }

  expectCopyWith(
    'IOFieldConfig',
    () => IOFieldConfig<int>(
      idDecoration: const InputDecoration(labelText: 'label'),
      isReadOnly: true,
      tip: 'tip',
      valueListenable: ValueNotifier(7),
      valueGetter: () => 7,
      valueSetter: _setter,
      errorGetter: () => false,
      valueStringifier: (_) => 'seven',
      valueEnumRange: const [1, 2],
      valueNumLimits: (min: -1, max: 1),
      valueChanged: _changed,
      boolStyle: IOFieldBoolStyle.textMenu,
    ),
  );

  expectCopyWith('VarIOFieldConfig', () => VarIOFieldConfig<int>(const FakeVarKey(1).create(), readOnly: true));

  test('IOFieldConfig label and units are its decoration\'s', () {
    final config = IOFieldConfig<int>(idDecoration: const InputDecoration(labelText: 'Speed', suffixText: 'rpm'), valueListenable: ValueNotifier(0), valueGetter: () => 0);
    expect((config.label, config.units), ('Speed', 'rpm'));
  });

  test('VarIOFieldConfig label is the key\'s, shown as the decoration shows it', () {
    final varNotifier = const FakeVarKey(1).create();
    expect([for (final showLabel in [true, false]) VarIOFieldConfig<int>(varNotifier, showLabel: showLabel)].map((config) => (config.label, config.idDecoration.labelText)), [
      ('key1', 'key1'),
      (null, null),
    ]);
  });

  test('VarIOFieldConfig.valueNumLimits is the notifier\'s: a quantity codec without limits falls back to its format range', () {
    final varNotifier = VarNotifier<int>(varKey: const FakeVarKey(1), codec: BinaryQuantityCodec<int>.of(const Uint16Int()));
    expect(VarIOFieldConfig<int>(varNotifier).valueNumLimits, (min: 0, max: 65535));
  });
}
