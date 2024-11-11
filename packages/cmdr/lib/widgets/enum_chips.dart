import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

typedef MultiWidgetBuilder = Widget Function(BuildContext context, List<Widget> children);

/// ChipSelection - allows user's `_selection_` from a `_selection_` of chips

// single select
// Generic parameter to ensure getter and setter are of the exact same type as List<Enum>
class SingleSelectChips<T extends Enum> extends StatelessWidget {
  const SingleSelectChips({super.key, required this.categories, required this.onSelected, required this.selectedCategory, this.spacing = 10, this.builder});

  final List<T> categories;
  final ValueSetter<T?> onSelected;
  final ValueGetter<T?> selectedCategory;
  final double spacing;
  final MultiWidgetBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final category in categories)
        ChoiceChip(
          label: Text(category.name.pascalCase),
          selected: selectedCategory() == category,
          onSelected: (bool value) => onSelected(value ? category : null),
        ),
    ];

    if (builder != null) return builder!(context, children);

    return Wrap(spacing: spacing, children: children);
  }
}

class MultiSelectChips<T extends Enum> extends StatelessWidget {
  const MultiSelectChips({super.key, required this.properties, required this.onSelected, required this.selectedProperties});

  final List<T> properties;
  final ValueSetter<({T property, bool isSelected})> onSelected;
  final ValueGetter<Set<T>> selectedProperties; // alternatively change to widget holds state

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (final property in properties)
          FilterChip(
            label: Text(property.name.pascalCase),
            selected: selectedProperties().contains(property),
            onSelected: (bool value) => onSelected((property: property, isSelected: value)),
          ),
      ],
    );

    //   content: Wrap(
    //   runSpacing: 5,
    //   spacing: 5,
    //   children: [
    //     for (final element in widget.selectable)
    //       FilterChip(
    //         label: widget.labelBuilder(element, selected.contains(element)),
    //         onSelected: (bool value) => setState(() {
    //           if (value) {
    //             if (widget.selectedMax != null && selected.length >= widget.selectedMax!) return;
    //             selected.add(element);
    //           } else {
    //             selected.remove(element);
    //           }
    //           // value ? selected.add(element) : selected.remove(element);
    //         }),
    //         selected: selected.contains(element),
    //       ),
    //   ],
    // ),
  }
}
