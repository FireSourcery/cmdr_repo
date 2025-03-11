import 'package:cmdr/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:binary_data/binary_data.dart';
// applies to Word type. todo generalize or rename

/// A text 'word' that is also a 64-bit integer 'word'.
///

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
