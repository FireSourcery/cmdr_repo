import 'package:cmdr/byte_struct.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../binary_data/word.dart';
import '../../widgets/map_list_view.dart';
import '../version.dart';

/// Read Only views
// class VersionTile extends StatelessWidget {
//   const VersionTile({required this.version, this.label, super.key});
//   final Version version;
//   final String? label;

//   @override
//   Widget build(BuildContext context) {
//     final name = label ?? version.name;
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       dense: null,
//       titleAlignment: ListTileTitleAlignment.bottom,
//       title: Text(version.toStringAsVersion()),
//       subtitle: ((name != null) ? Text(name) : null),
//     );
//   }
// }

class VersionRowTiles extends StatelessWidget {
  const VersionRowTiles({required this.versions, this.title = 'Version', super.key});
  final List<Version> versions;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return MapRowTiles(fields: [for (final version in versions) version.asLabelPair]);
  }
}

/// todo as Map
/// Editable views
class VersionFormFieldChars extends StatelessWidget {
  const VersionFormFieldChars({required this.version, this.label, super.key, this.isReadOnly = false, this.onSaved, this.isCharCode = false});
  final Version version;
  final bool isReadOnly;
  final String? label;
  final bool isCharCode;
  final ValueSetter<Version>? onSaved;

  // todo alternate schemes, remove for enum
  String labelAt(int index) => switch (index) { 0 => 'Opt', 1 => 'Major', 2 => 'Minor', 3 => 'Fix', _ => 'Unknown' };

  @override
  Widget build(BuildContext context) {
    return FormField<Uint8List>(
      initialValue: version.version, // new editable buffer
      onSaved: (Uint8List? newValue) => onSaved?.call(version.updateVersion(newValue!)),
      validator: (Uint8List? value) {
        if (value == null || value.isEmpty) return 'Empty value';
        if (value.any((element) => element > 255)) return 'Max 255 allowed';
        return null;
      },

      builder: (FormFieldState<Uint8List> field) {
        return Row(
          children: [
            for (final (index, byte) in field.value!.indexed) ...[
              Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: label ?? labelAt(index), isDense: true, counterText: '' /* , errorText: field.errorText */),
                  controller: TextEditingController(text: byte.toString()),
                  // onSubmitted: (String value) => field.value?[index] = int.parse(value),
                  onChanged: (String value) {
                    if (value.isNotEmpty) {
                      final intValue = int.parse(value);
                      field.value?[index] = intValue.clamp(0, 255);
                      if (intValue > 255) field.validate();
                    } else {
                      // field.value?[index] = 0;
                    }
                  },
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  readOnly: isReadOnly,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  maxLength: 3,

                  // onEditingComplete: () => print('onEditingComplete'),
                  // textInputAction: TextInputAction.next,
                  // onTapOutside: (event) => field.didChange(field.value),
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
