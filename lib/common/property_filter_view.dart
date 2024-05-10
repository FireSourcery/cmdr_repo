import 'package:flutter/material.dart';

import 'defined_types.dart';

class PropertyChoiceChips extends StatelessWidget {
  const PropertyChoiceChips({super.key, required this.categories, required this.onSelected, required this.selectedCategory});

  final List<PropertyFilter> categories;
  final ValueSetter<PropertyFilter?> onSelected;
  final ValueGetter<PropertyFilter> selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (final category in categories)
          ChoiceChip(
            label: Text(category.label),
            selected: selectedCategory() == category,
            onSelected: (bool value) => onSelected(value ? category : null),
          ),
      ],
    );
  }
}

class PropertyFilterChips extends StatelessWidget {
  const PropertyFilterChips({super.key, required this.properties, required this.onSelected, required this.selectedProperties});

  final List<PropertyFilter> properties;
  final ValueSetter<PropertyFilter?> onSelected;
  final ValueGetter<Set<PropertyFilter>> selectedProperties;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (final property in properties)
          FilterChip(
            label: Text(property.label),
            selected: selectedProperties().contains(property),
            onSelected: (bool value) => onSelected(value ? property : null),
          ),
      ],
    );
  }
}
