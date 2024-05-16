import 'package:cmdr/byte_struct.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../byte_struct/word_fields.dart';
import '../byte_struct/word.dart';

/// Read Only views
class MapRowTiles<K, V> extends StatelessWidget {
  const MapRowTiles({required this.fields, this.title, super.key});
  final Iterable<(K key, V value)> fields;
  final String? title;
  // Widget Function(K)? keyBuilder;
  // Widget Function(V)? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      // contentPadding: EdgeInsets.zero,
      // title: (label != null) ? Text(label!) : null,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(title!, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.left),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (key, value) in fields)
              IntrinsicWidth(
                child: ListTile(
                  key: UniqueKey(), //
                  // titleAlignment: ListTileTitleAlignment.bottom,
                  subtitle: Text(key.toString()),
                  title: Text(value.toString()),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// class MapListView extends StatelessWidget {
//   const MapListView({required this.namedFields, this.label = 'Map', super.key});
//   final List<Map> namedFields;
//   final String? label;

//   @override
//   Widget build(BuildContext context) {
//     return InputDecorator(
//       decoration: InputDecoration(labelText: label),
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [for (final namedFields in namedFields) MapTile(namedFields: namedFields)],
//       ),
//     );
//   }
// }

/// Editable views
class MapFormFields<K, V> extends StatelessWidget {
  const MapFormFields({super.key, required this.fields, this.isReadOnly = false, this.onSaved, required this.valueParser, this.inputFormatters, this.keyStringifier});
  MapFormFields.digits({super.key, required this.fields, this.isReadOnly = false, this.onSaved, this.keyStringifier}) //todo at min max
      : valueParser = switch (V) {
          const (int) => int.tryParse,
          const (double) => double.tryParse,
          const (num) => num.tryParse,
          _ => throw UnsupportedError('$V must be num type'),
        } as V? Function(String),
        inputFormatters = [FilteringTextInputFormatter.digitsOnly];

  final Iterable<(K key, V value)> fields; // todo as EnumMap
  final bool isReadOnly;
  final ValueSetter<Map<K, V>>? onSaved;

  final String Function(K key)? keyStringifier;
  final V? Function(String textValue) valueParser;
  final List<TextInputFormatter>? inputFormatters;

  String labelOf(K key) => keyStringifier?.call(key) ?? key.toString();

  @override
  Widget build(BuildContext context) {
    return FormField<Map<K, V>>(
      initialValue: {for (final (key, value) in fields) key: value}, // new editable buffer
      onSaved: (Map<K, V>? newValue) => onSaved?.call(newValue!),
      validator: (Map<K, V>? value) {
        if (value == null || value.isEmpty) return 'Empty value';
        return null;
      },

      builder: (FormFieldState<Map<K, V>> field) {
        return Row(
          children: [
            for (final (index, (key, value)) in fields.indexed) ...[
              Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: labelOf(key), isDense: true, counterText: '' /* , errorText: field.errorText */),
                  controller: TextEditingController(text: field.value?[key].toString()),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      if (valueParser(value) case V value) field.value?[key] = value;
                    }
                  },
                  // onEditingComplete: () => field.didChange(field.value),
                  // onSubmitted: (String value) => field.value?[index] = int.parse(value),

                  //  (String value) {
                  //   if (value.isNotEmpty) {
                  //     final intValue = int.parse(value);
                  //     field.value?[index] = intValue.clamp(0, 255);
                  //     if (intValue > 255) field.validate();
                  //   } else {
                  //     // field.value?[index] = 0;
                  //   }
                  // },
                  inputFormatters: inputFormatters,
                  readOnly: isReadOnly,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  maxLines: 1,
                  // maxLength: 3,

                  // onEditingComplete: () => print('onEditingComplete'),
                  // textInputAction: TextInputAction.next,
                  // onTapOutside: (event) => field.didChange(field.value),
                ),
              ),
              if (index != field.value!.length - 1) const VerticalDivider(),
            ],
          ],
        );
      },
    );
  }
}
