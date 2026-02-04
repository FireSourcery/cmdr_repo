import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

// typedef MultiWidgetBuilder = Widget Function(BuildContext context, List<Widget> children);
// typedef MultiWidgetBuilder = Widget Function({List<Widget> children});

typedef ChipWrapperBuilder = Widget Function(BuildContext context, List<Widget> children);

/// ChipSelection - let user select from a `selection/collection` of chips
/// Caller holds the state of the selected items

/// Single select
// Generic parameter ensures getter and setter are of the exact same type as List<T>
class SingleSelectChips<T> extends StatelessWidget {
  const SingleSelectChips({
    super.key,
    required this.selectable,
    required this.onSelected,
    required this.selected,
    this.spacing = 10,
    this.labelBuilder,
    this.builder,
  });

  final List<T> selectable;
  final T? selected;
  final ValueSetter<T?> onSelected;
  // final ValueSetter<T?> setSelected;
  final double spacing;
  final ValueWidgetBuilder<T>? labelBuilder;
  final ChipWrapperBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final item in selectable)
        ChoiceChip(
          label: _Label<T>(chipKey: item, labelBuilder: labelBuilder),
          selected: selected == item,
          onSelected: (bool value) => onSelected(value ? item : null), // common null is sufficient for unselect all
        ),
    ];

    if (builder != null) return builder!(context, chips);
    return Wrap(spacing: spacing, children: chips);
  }
}

/// Caller provide state  `selectedState`
///
//
// optionally wrap in stateful builder to include rebuild on selection change
// StatefulBuilder(
//   builder: (context, setState) {
//     return MultiSelectChips<E>(
//       selectable: selectable,
//       selectedState: selectedState,
//       selectMax: selectMax,
//       labelBuilder: labelBuilder,
//       onSelected: (E value) => setState(() => _onSelected(value)),
//     );
//   },
// ),
class MultiSelectChips<T> extends StatelessWidget {
  const MultiSelectChips({
    super.key,
    required this.selectable,
    required this.selectedState,
    this.selectMax,
    this.labelBuilder,
    this.spacing = 10,
    this.onSelected,
    this.onAdd,
    this.onRemove,
    this.builder,
  });

  final Iterable<T> selectable; // must be a new list, iterable non-primitives may not add to set properly
  final Set<T> selectedState; // externally maintained state

  final ValueSetter<T>? onSelected; // does not include add/remove info
  final ValueSetter<T>? onAdd; // alternatively ValueSetter<(T,bool)>
  final ValueSetter<T>? onRemove;

  final int? selectMax;
  final ValueWidgetBuilder<T>? labelBuilder;
  final double spacing;

  final ChipWrapperBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final item in selectable)
        FilterChip(
          label: _Label<T>(chipKey: item, labelBuilder: labelBuilder),
          selected: selectedState.contains(item),
          onSelected: (bool value) {
            if (value) {
              if (selectMax case int max when selectedState.length < max || selectMax == null) {
                selectedState.add(item);
                onAdd?.call(item);
              }
            } else {
              selectedState.remove(item);
              onRemove?.call(item);
            }
            onSelected?.call(item);
          },
        ),
    ];

    if (builder != null) return builder!(context, chips);
    return Wrap(runSpacing: spacing, spacing: spacing, children: chips);
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
