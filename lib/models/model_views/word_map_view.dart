import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../binary_data/word.dart';

/// Editable views
// input as string literal
class WordFormField extends StatelessWidget {
  const WordFormField({required this.word, this.label, super.key, this.isReadOnly = false, this.onSaved, this.maxLength = 8});
  final Word word;
  final String? label;
  final bool isReadOnly;
  final ValueSetter<Word>? onSaved;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      initialValue: word.asString,
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

class WordStringTile extends StatelessWidget {
  const WordStringTile({required this.nameId, this.label = "Name Id", super.key});
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


// named enum maps
// NamedFieldView