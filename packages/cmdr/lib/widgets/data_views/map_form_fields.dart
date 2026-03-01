import 'package:binary_data/word/word.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:binary_data/data/basic_ext.dart';

/// A singular FormField partitioned corresponding to the Map input.
/// Displays a TextField for each Map entry, with initial values from the map.
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

  MapFormFields.digits({
    super.key,
    required this.entries,
    required this.onSaved,
    this.isReadOnly = false,
    this.keyStringifier,
    this.numLimits,
    this.leading,
  }) : valueParser =
           switch (V) {
                 const (int) => int.tryParse,
                 const (double) => double.tryParse,
                 const (num) => num.tryParse,
                 _ => throw UnsupportedError('$V must be num type'),
               }
               as V? Function(String),
       inputFormatters = [FilteringTextInputFormatter.digitsOnly];

  final Iterable<MapEntry<K, V>> entries; // MapEntry<K, V>
  final bool isReadOnly;
  final ValueSetter<Map<K, V>> onSaved; // returns a new Map that is a HashMap, user may cast to original type

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
  late final Map<K, V> results = {for (final MapEntry(:key, :value) in widget.entries) key: value};
  late final Map<K, TextEditingController> _textEditingControllers;
  late final Map<K, FocusNode> _focusNodes;

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
    _textEditingControllers = {for (final MapEntry(:key, :value) in widget.entries) key: TextEditingController(text: value.toString())};
    _focusNodes = {for (final MapEntry(:key) in widget.entries) key: FocusNode()..addListener(() => updateOnFocusLoss(key))};
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
            for (final (index, MapEntry(:key, :value)) in widget.entries.indexed) ...[
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

/// Read Only views
/// possibly change to String,V
class TextPairs extends StatelessWidget {
  const TextPairs({required this.fields, this.title, this.direction = Axis.horizontal, super.key});
  final Iterable<(String label, String contents)> fields;
  final String? title;
  final Axis direction;
  // Widget Function(K)? keyBuilder;
  // Widget Function(V)? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(title!, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.left),
        Flex(
          direction: direction,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, contents) in fields)
              IntrinsicWidth(
                child: ListTile(
                  // titleAlignment: ListTileTitleAlignment.bottom,
                  subtitle: Text(label),
                  title: Text(contents),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A text 'word' that is also a 64-bit integer 'word'.
/// Editable views
// todo input as string literal
class StringFormField extends StatelessWidget {
  const StringFormField({required this.word, this.label, super.key, this.isReadOnly = false, this.onSaved, this.maxLength = 8});
  final Word word; // change this to use map interface?
  final String? label;
  final bool isReadOnly;
  final ValueSetter<Word>? onSaved;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      initialValue: word.asString().trimNulls(),
      readOnly: false,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      maxLength: maxLength,
      // autofillHints: [''],
      // buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => SizedBox.shrink(),
      onSaved: (String? newValue) => onSaved?.call(Word.string(newValue!)), // validator will reject null
      validator: (String? value) {
        if (value == null || value.isEmpty) return 'Empty value';
        return null;
      },
    );
  }
}

class StringTile extends StatelessWidget {
  const StringTile({required this.nameId, this.label = "Name Id", super.key});
  final Word nameId;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // contentPadding: EdgeInsets.zero,
      // dense: null,
      titleAlignment: ListTileTitleAlignment.bottom,
      title: Text(nameId.asString()),
      subtitle: (label != null) ? Text(label!) : null,
    );
  }
}
