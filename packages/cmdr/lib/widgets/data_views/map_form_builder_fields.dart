import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// A horizontal group of [FormBuilderTextField]s, one per [Map] entry — the
/// `flutter_form_builder` counterpart to `MapFormFields`.
/// Intended for non-negative integer fields (digits-only). [V] may be any [num];
/// the parser picks `int`/`double` accordingly.
class MapFormBuilderFields<K extends Enum, V extends num> extends StatelessWidget {
  const MapFormBuilderFields({super.key, required this.name, required this.entries, this.isReadOnly = false, this.labelStringifier, this.numLimits, this.leading});

  /// Group name. Qualifies each child field as `'$name.${key.name}'`.
  final String name;
  final Iterable<MapEntry<K, V>> entries;
  final bool isReadOnly;

  /// Maps a key to its display label. Defaults to `key.name`.
  final String Function(K key)? labelStringifier;
  final (num min, num max)? numLimits;
  final Widget? leading;

  int? get _maxDigits => numLimits?.$2.toString().length;

  String fieldNameOf(K key) => '$name.${key.name}';
  String labelOf(K key) => labelStringifier?.call(key) ?? key.name;

  V? _parse(String text) => (V == int ? int.tryParse(text) : double.tryParse(text)) as V?;

  String? _validate(String? text) {
    if (text == null || text.isEmpty) return 'Empty value';
    if (_parse(text) case V value) {
      if (numLimits case (num min, num max) when value < min || value > max) return '$min to $max allowed';
      return null;
    }
    return 'Invalid number';
  }

  /// Reconstructs `{key: value}` for [keys] from a saved [FormBuilderState],
  /// reading the namespaced fields written under group [name].
  static Map<K, int> intValuesOf<K extends Enum>(FormBuilderState state, String name, Iterable<K> keys) {
    return {for (final key in keys) key: (state.value['$name.${key.name}'] as num).toInt()};
  }

  @override
  Widget build(BuildContext context) {
    final entryList = entries.toList(growable: false);
    return Row(
      children: [
        if (leading != null) Expanded(child: leading!),
        for (final (index, MapEntry(:key, :value)) in entryList.indexed) ...[
          Expanded(
            child: FormBuilderTextField(
              name: fieldNameOf(key),
              initialValue: value.toString(),
              decoration: InputDecoration(labelText: labelOf(key), isDense: true, counterText: ''),
              readOnly: isReadOnly,
              autovalidateMode: AutovalidateMode.onUnfocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              maxLength: _maxDigits,
              maxLines: 1,
              valueTransformer: (text) => (text == null) ? null : _parse(text),
              validator: _validate,
            ),
          ),
          if (index != entryList.length - 1) const VerticalDivider(),
        ],
      ],
    );
  }
}
