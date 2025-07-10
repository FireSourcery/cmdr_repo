import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

typedef MultiWidgetBuilder = Widget Function(BuildContext context, List<Widget> children);

/// ChipSelection - allows user's `_selection_` from a `_selection_` of chips

/// Caller holds the state of the selected items

// single select
// Generic parameter to ensure getter and setter are of the exact same type as List<T>
class SingleSelectChips<T> extends StatelessWidget {
  const SingleSelectChips({
    super.key,
    required this.selectable,
    required this.onSelected,
    required this.selected,
    this.spacing = 10,
    this.builder,
    this.labelBuilder,
  });

  final List<T> selectable;
  final ValueSetter<T?> onSelected;
  final T? selected; // change to Listenable for use with getter
  final double spacing;
  final MultiWidgetBuilder? builder;
  final ValueWidgetBuilder<T>? labelBuilder;
  // final Listenable? listenable;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final key in selectable)
        ChoiceChip(
          label: _Label<T>(chipKey: key, labelBuilder: labelBuilder),
          selected: selected == key,
          onSelected: (bool value) => onSelected(value ? key : null),
        ),
    ];

    if (builder != null) return builder!(context, children);

    return Wrap(spacing: spacing, children: children);
  }
}

// Caller provide buffer and setState
class MultiSelectChips<T> extends StatelessWidget {
  const MultiSelectChips({
    super.key,
    required this.selectable,
    required this.selectionState,
    this.selectMax,
    // this.initialSelected,
    this.labelBuilder,
    this.spacing = 10,
    this.onSelected,
  });

  final List<T> selectable;
  // final ValueSetter<({T property, bool isSelected})> onSelected;
  // final ValueGetter<Set<T>> selectedProperties; // alternatively change to widget holds state

  // final ValueSetter<T>? onAdd;
  // final ValueSetter<T>? onRemove;
  final ValueSetter<T>? onSelected;
  final Set<T> selectionState;
  final int? selectMax;
  // final Iterable<T>? initialSelected;
  final ValueWidgetBuilder<T>? labelBuilder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: spacing,
      spacing: spacing,
      // runAlignment: WrapAlignment.spaceEvenly,
      // crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final key in selectable)
          FilterChip(
            label: _Label<T>(chipKey: key, labelBuilder: labelBuilder),
            selected: selectionState.contains(key),
            onSelected: (bool value) {
              if (value) {
                if (selectMax case int max when selectionState.length < max) selectionState.add(key);
              } else {
                selectionState.remove(key);
              }
              onSelected?.call(key);
            },
          ),
      ],
    );
  }
}

class _Label<T> extends StatelessWidget {
  const _Label({super.key, required this.labelBuilder, required this.chipKey});

  final ValueWidgetBuilder<T>? labelBuilder;
  final T chipKey;

  // static Widget _enumLabelBuilder(BuildContext context, dynamic value, Widget? child) => Text(value.name.pascalCase);
  // static Widget _objectLabelBuilder(BuildContext context, dynamic value, Widget? child) => Text(value.toString().pascalCase);

  @override
  Widget build(BuildContext context) {
    if (labelBuilder != null) return labelBuilder!(context, chipKey, null);
    if (chipKey case Enum(:final name)) return Text(name.pascalCase);
    return Text(chipKey.toString().pascalCase);
  }
}
