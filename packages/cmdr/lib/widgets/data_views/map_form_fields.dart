import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:struct_data/word/word.dart';
import 'package:struct_data/utilities/basic_ext.dart';

/// A singular FormField partitioned corresponding to the Map input.
/// Displays a TextFormField for each Map entry, with initial values from the map.
/// Editable views
/// Value should be String or num
///
/// The outer [FormField] is a pure aggregator - it exists only to deliver [onSaved] with the whole
/// map. Validation is per entry, since [numLimits] applies to each entry independently.
///
/// Note the outer [FormField] registers with the enclosing [Form] before its children do, so
/// [Form.save] reaches it first. Entry values are therefore collected on change, not on save.
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
    this.direction = Axis.horizontal,
  });

  MapFormFields.digits({
    super.key,
    required this.entries,
    required this.onSaved,
    this.isReadOnly = false,
    this.keyStringifier,
    this.numLimits,
    this.leading,
    this.direction = Axis.horizontal,
  }) : valueParser =
           switch (V) {
                 const (int) => int.tryParse,
                 const (double) => double.tryParse,
                 const (num) => num.tryParse,
                 _ => throw UnsupportedError('$V must be num type'),
               }
               as V? Function(String),
       inputFormatters = switch (V) {
         const (int) => [FilteringTextInputFormatter.digitsOnly],
         const (double) || const (num) => [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
         _ => null,
       };

  final Iterable<MapEntry<K, V>> entries; // MapEntry<K, V>
  final bool isReadOnly;
  final ValueSetter<Map<K, V>> onSaved; // returns a new Map that is a HashMap, user may cast to original type

  final String Function(K key)? keyStringifier;
  final Widget? leading;

  /// Layout axis of the entry fields. Horizontal shares the width evenly; vertical stacks and sizes
  /// to content, so it is safe inside an unbounded parent.
  final Axis direction;

  // handle internally
  final V? Function(String textValue) valueParser;
  final List<TextInputFormatter>? inputFormatters;

  //
  final (num min, num max)? numLimits;

  int? get maxDigits => numLimits?.$2.toString().length;

  static bool isNumeric<T>() => T == int || T == double || T == num;

  @override
  State<MapFormFields<K, V>> createState() => _MapFormFieldsState<K, V>();
}

class _MapFormFieldsState<K, V> extends State<MapFormFields<K, V>> {
  // Seeded once. Each TextFormField owns its own controller via initialValue, so this map is the
  // only state kept here - updated on change, read by the aggregating FormField on save.
  late final Map<K, V> results = {for (final MapEntry(:key, :value) in widget.entries) key: value};

  String labelOf(K key) => widget.keyStringifier?.call(key) ?? key.toString();

  /// Per entry. [MapFormFields.numLimits] constrains each entry independently, so there is nothing
  /// to check across the map. Pure - clamping a value here would mutate during build.
  String? validateEntry(String? textValue) {
    if (textValue == null || textValue.isEmpty) return 'Empty value';
    if (widget.valueParser(textValue) case V parsedValue) {
      if (widget.numLimits case (num min, num max) when parsedValue is num) {
        if (parsedValue < min || parsedValue > max) return '$min to $max allowed';
      }
      return null;
    }
    return 'Invalid value';
  }

  /// [Expanded] shares the main axis when horizontal. A vertical [Flex] may be unbounded, where a
  /// flex child would throw, so entries size to content instead.
  Widget expandOnAxis(Widget child) => switch (widget.direction) {
    Axis.horizontal => Expanded(child: child),
    Axis.vertical => child,
  };

  /// Separator across the layout axis.
  Widget get separator => switch (widget.direction) {
    Axis.horizontal => const VerticalDivider(),
    Axis.vertical => const Divider(),
  };

  @override
  Widget build(BuildContext context) {
    // Aggregator only. Entry values are collected in onChanged, since Form.save() reaches this
    // outer field before the children it wraps.
    return FormField<Map<K, V>>(
      // A snapshot, not [results] itself - aliasing the live map would make value == initialValue
      // forever, so the field could never read as changed.
      initialValue: Map.of(results),
      onSaved: (_) => widget.onSaved.call(results),
      builder: (FormFieldState<Map<K, V>> field) {
        return Flex(
          direction: widget.direction,
          mainAxisSize: switch (widget.direction) {
            Axis.horizontal => MainAxisSize.max,
            Axis.vertical => MainAxisSize.min,
          },
          children: [
            if (widget.leading != null) expandOnAxis(widget.leading!),
            for (final (index, MapEntry(:key, :value)) in widget.entries.indexed) ...[
              expandOnAxis(
                TextFormField(
                  key: ValueKey(key),
                  initialValue: value.toString(),
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: validateEntry,
                  onChanged: (String textValue) {
                    if (widget.valueParser(textValue) case V parsedValue) field.didChange(results..[key] = parsedValue);
                  },
                  decoration: InputDecoration(labelText: labelOf(key), isDense: true, counterText: ''),
                  inputFormatters: widget.inputFormatters,
                  readOnly: widget.isReadOnly,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  maxLines: 1,
                  maxLength: widget.maxDigits,
                ),
              ),
              if (index != widget.entries.length - 1) separator,
            ],
          ],
        );
      },
    );
  }
}

/// The read-only counterpart to [MapFormFields], as [StringTile] is to [StringFormField].
/// Displays Map entries as a two column key/value [Table], keys left aligned, values right aligned.
/// Suited to confirmation dialogs and summaries, where the same map is shown without a [Form].
class MapTable<K, V> extends StatelessWidget {
  const MapTable({super.key, required this.entries, this.keyStringifier, this.valueStringifier, this.title});

  final Iterable<MapEntry<K, V>> entries;
  final String Function(K key)? keyStringifier;
  final String Function(V value)? valueStringifier;
  final String? title;

  String labelOf(K key) => keyStringifier?.call(key) ?? key.toString();
  String textOf(V value) => valueStringifier?.call(value) ?? value.toString();

  @override
  Widget build(BuildContext context) {
    final table = Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
      children: [
        for (final MapEntry(:key, :value) in entries)
          TableRow(
            children: [
              Text(labelOf(key)),
              Text(textOf(value), textAlign: TextAlign.end),
            ],
          ),
      ],
    );

    if (title == null) return table;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title!, style: Theme.of(context).textTheme.titleMedium),
        table,
      ],
    );
  }
}

/// A text 'word' that is also a 64-bit integer 'word'.
/// Editable views
class StringFormField extends StatelessWidget {
  const StringFormField({required this.word, this.label, super.key, this.isReadOnly = false, this.onSaved, this.maxLength = 8});
  final Word word;
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
      autovalidateMode: AutovalidateMode.onUnfocus,
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
      titleAlignment: ListTileTitleAlignment.bottom,
      title: Text(nameId.asString()),
      subtitle: (label != null) ? Text(label!) : null,
    );
  }
}
