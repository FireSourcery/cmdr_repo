import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

// typedef MultiWidgetBuilder = Widget Function(BuildContext context, List<Widget> children);
typedef ChipWrapperBuilder = Widget Function(BuildContext context, List<Widget> children);

/// ChipSelection - let user select from a `selection/collection` of chips
/// Caller holds the state of the selected items

/// Single select
// Generic parameter ensures getter and setter are of the exact same type as List<T>
class const SingleSelectChips<T>({
    super.key,
    required final List<T> selectable,
    required final ValueSetter<T?> onSelected,
    required final T? selected,
    final double spacing = 10,
    final ValueWidgetBuilder<T>? labelBuilder,
    final ChipWrapperBuilder? builder,
  }) extends StatelessWidget {
  // final ValueSetter<T?> setSelected;
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
class const MultiSelectChips<T>({
    super.key,
    required final Iterable<T> selectable, // must be a new list
    required final Set<T> selectedState, // externally maintained state
    final int? selectMax,
    final ValueWidgetBuilder<T>? labelBuilder,
    final double spacing = 10,
    final ValueSetter<T>? onSelected, // does not include add/remove info
    final ValueSetter<T>? onAdd, // alternatively ValueSetter<(T,bool)>
    final ValueSetter<T>? onRemove,
    final ChipWrapperBuilder? builder,
  }) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final item in selectable)
        FilterChip(
          label: _Label<T>(chipKey: item, labelBuilder: labelBuilder),
          selected: selectedState.contains(item),
          onSelected: (bool value) {
            if (value) {
              if (selectMax == null || selectedState.length < selectMax!) {
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

class const _Label<T>({super.key, required final ValueWidgetBuilder<T>? labelBuilder, required final T chipKey}) extends StatelessWidget {
  // static Widget _enumLabelBuilder(BuildContext context, dynamic value, Widget? child) => Text(value.name.pascalCase);
  // static Widget _objectLabelBuilder(BuildContext context, dynamic value, Widget? child) => Text(value.toString().pascalCase);

  @override
  Widget build(BuildContext context) {
    if (labelBuilder != null) return labelBuilder!(context, chipKey, null);
    if (chipKey case Enum(:final name)) return Text(name.pascalCase);
    return Text(chipKey.toString().pascalCase);
  }
}
