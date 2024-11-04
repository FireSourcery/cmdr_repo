import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Read Only views
/// possibly change to String,V
class MapRowTiles<K, V> extends StatelessWidget {
  const MapRowTiles({required this.fields, this.title, super.key});
  final Iterable<(K title, V contents)> fields;
  final String? title;
  // Widget Function(K)? keyBuilder;
  // Widget Function(V)? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(title!, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.left),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (title, contents) in fields)
              IntrinsicWidth(
                child: ListTile(
                  // titleAlignment: ListTileTitleAlignment.bottom,
                  subtitle: Text(title.toString()),
                  title: Text(contents.toString()),
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

/// A FormField partitioned corresponding to the map input. Each Map entry is an separate entity
/// Editable views
/// Value should be String or num
class MapFormFields<K, V> extends StatefulWidget {
  const MapFormFields({
    super.key,
    required this.entries,
    required this.onSaved,
    required this.valueParser,
    this.isReadOnly = false,
    this.inputFormatters,
    this.keyStringifier,
    this.numLimits,
    this.leading,
  });

  // todo at min max
  MapFormFields.digits({super.key, required this.entries, this.isReadOnly = false, required this.onSaved, this.keyStringifier, this.numLimits, this.leading})
      : valueParser = switch (V) {
          const (int) => int.tryParse,
          const (double) => double.tryParse,
          const (num) => num.tryParse,
          _ => throw UnsupportedError('$V must be num type'),
        } as V? Function(String),
        inputFormatters = [FilteringTextInputFormatter.digitsOnly];

  final Iterable<(K key, V value)> entries; // MapEntry<K, V>
  final bool isReadOnly;
  final ValueSetter<Map<K, V>> onSaved;

  final String Function(K key)? keyStringifier;
  final V? Function(String textValue) valueParser;

  final List<TextInputFormatter>? inputFormatters;
  final (num min, num max)? numLimits;
  final Widget? leading;

  int? get maxDigits => numLimits?.$2.toString().length;

  static bool isNumeric<T>() => T == int || T == double || T == num;

  @override
  State<MapFormFields<K, V>> createState() => _MapFormFieldsState<K, V>();
}

class _MapFormFieldsState<K, V> extends State<MapFormFields<K, V>> {
  late final Map<K, V> results;
  late final Map<K, TextEditingController> _textEditingControllers;
  late final Map<K, FocusNode> _focusNodes;

  // static Map<K, TextEditingController> _newTextEditingControllers<K, V>(Iterable<(K key, V value)> entries) {
  //   return {for (final (key, value) in entries) key: TextEditingController(text: value.toString())};
  // }

  String labelOf(K key) => widget.keyStringifier?.call(key) ?? key.toString();

  void updateValue(K key, String value) {
    if (value.isEmpty) return;
    if (widget.valueParser(value) case V parsedValue) results[key] = parsedValue;
  }

  void updateOnFocusLoss(K key) {
    if (!_focusNodes[key]!.hasFocus) updateValue(key, _textEditingControllers[key]!.text);
  }

  @override
  void initState() {
    super.initState();
    results = {for (final (key, value) in widget.entries) key: value};
    _textEditingControllers = {for (final (key, value) in widget.entries) key: TextEditingController(text: value.toString())};
    _focusNodes = {for (final (key, _) in widget.entries) key: FocusNode()..addListener(() => updateOnFocusLoss(key))};
  }

  @override
  void dispose() {
    for (final controller in _textEditingControllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Map<K, V>>(
      autovalidateMode: AutovalidateMode.onUnfocus,
      initialValue: results,
      onSaved: (Map<K, V>? newValue) => widget.onSaved.call(newValue!),
      validator: (Map<K, V>? value) {
        if (value == null || value.isEmpty) return 'Empty value';
        if (MapFormFields.isNumeric<V>()) {
          if (widget.numLimits case (num min, num max)) {
            for (final entry in value.entries) {
              if ((entry.value as num).clamp(min, max) case num clamped when clamped != entry.value) {
                _textEditingControllers[entry.key]!.text = clamped.toString();
                results[entry.key] = clamped as V;
                return '$min to $max allowed';
              }
            }
          }
        }
        return null;
      },
      builder: (FormFieldState<Map<K, V>> field) {
        return Row(
          children: [
            if (widget.leading != null) Expanded(child: widget.leading!),
            for (final (index, (key, _)) in widget.entries.indexed) ...[
              Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: labelOf(key), isDense: true, counterText: '', errorText: field.errorText),
                  controller: _textEditingControllers[key]!,
                  onEditingComplete: () => updateValue(key, _textEditingControllers[key]!.text),
                  focusNode: _focusNodes[key]!,
                  onSubmitted: (String value) => updateValue(key, value),
                  // onChanged: (String value) {
                  //   if (MapFormFields.isNumeric<V>()) {
                  //     // if validate on change
                  //     updateValue(key, value); // update cached value
                  //     field.validate(); // display error
                  //   }
                  // },
                  // onTapOutside: (event) {
                  //   // updateValue(key, _textEditingControllers[key]!.text);
                  //   field.didChange(field.value); //sets map object
                  //   // print('onTapOutside'); //field.didChange(field.value),
                  // },
                  inputFormatters: widget.inputFormatters,
                  readOnly: widget.isReadOnly,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  maxLines: 1,
                  maxLength: widget.maxDigits,
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
