import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../byte_struct/word.dart';

/// Editable views
// input as string literal
class NameIdFormField extends StatelessWidget {
  const NameIdFormField({required this.nameId, this.label, super.key, this.isReadOnly = false, this.onSaved, this.maxLength = 8});
  final Word nameId;
  final String? label;
  final bool isReadOnly;
  final ValueSetter<Word>? onSaved;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      initialValue: nameId.asString,
      readOnly: false,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      maxLength: maxLength.clamp(0, 8),
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

class NameIdTile extends StatelessWidget {
  const NameIdTile({required this.nameId, this.label = "Name Id", super.key});
  final Word nameId;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: null,
      titleAlignment: ListTileTitleAlignment.bottom,
      title: Text(nameId.asString),
      subtitle: ((label != null) ? Text(label!) : null),
    );
  }
}
