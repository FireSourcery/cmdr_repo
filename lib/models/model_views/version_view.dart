import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../version.dart';

class VersionTile extends StatelessWidget {
  const VersionTile({required this.version, this.label, super.key});
  final Version version;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final name = label ?? version.name;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: null,
      titleAlignment: ListTileTitleAlignment.bottom,
      title: Text(version.toStringAsVersion()),
      subtitle: ((name != null) ? Text(name) : null),
    );
  }
}

class VersionTiles extends StatelessWidget {
  const VersionTiles({required this.versions, this.label = 'Version', super.key});
  final List<Version> versions;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          VerticalDivider(),
          for (final version in versions) Expanded(child: VersionTile(version: version)),
        ],
      ),
    );
  }
}

// input as string literal
class VersionFormFieldString extends StatelessWidget {
  const VersionFormFieldString({required this.version, this.label, super.key, this.isReadOnly = false, this.onSaved});
  final Version version;
  final String? label;
  final bool isReadOnly;
  final ValueSetter<Version>? onSaved;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      initialValue: version.asString,
      readOnly: false,
      onSaved: (String? newValue) => onSaved?.call(Version.string(newValue!)), // validator will reject null
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      maxLength: version.length,
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      },
    );
  }
}

// class VersionFormFieldString extends StatelessWidget {}

class VersionFormFieldChars extends StatelessWidget {
  const VersionFormFieldChars({required this.version, this.label, super.key, this.isReadOnly = false, this.onSaved, this.asString = false, this.isLong = false});
  final Version version;
  final bool isReadOnly;
  final String? label;
  final bool asString;
  final bool isLong;

  final void Function(int charCode, int index)? onSaved;

  String getAsInt(int index) => version.bytes[index].toString(); // 1 => '1'
  String getAsCode(int index) => String.fromCharCode(version.bytes[index]); // 0x31 => '1'

  void setAsInt(String value, int index) => onSaved?.call(int.parse(value), index); // '1' => 1
  void setAsCode(String value, int index) => onSaved?.call(value.runes.single, index); // '1' => 0x31

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var count = 0; count < 4; count++)
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(labelText: label, isDense: true),
              initialValue: asString ? getAsCode(count) : getAsInt(count),
              readOnly: isReadOnly,
              onSaved: (String? newValue) => asString ? setAsCode(newValue!, count) : setAsInt(newValue!, count),
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              maxLength: 3,
              buildCounter: null,
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }
}

// edit as separate fields
// readOnly as single field

// class VersionAdaptive extends StatelessWidget {
//   const VersionAdaptive({required this.version, this.name, super.key});
//   final Version version;
//   final String? name;

//   @override
//   Widget build(BuildContext context) {
//     return (MediaQuery.of(context).size.width < 600) ? VersionTile(version: version, label: name) : VersionFormField(version: version, name: name);
//   }
// }

// class VersionsListView extends StatelessWidget {
//   const VersionsListView({super.key}); 

//   @override
//   Widget build(BuildContext context) {
//     return InputDecorator(
//       decoration: const InputDecoration(),
//       child: Column(
//         children: [
//           ListTile(contentPadding: EdgeInsets.zero, dense: null, subtitle: Text('Model'), title: Text(Reference().motManufacturer.motNameId)),
//           ListTile(contentPadding: EdgeInsets.zero, dense: null, subtitle: Text('Protocol'), title: versionProtocolText()),
//           // ListTile(contentPadding: EdgeInsets.zero, dense: null, subtitle: Text('Library'), title: versionLibraryText()),
//           ListTile(contentPadding: EdgeInsets.zero, dense: null, subtitle: Text('Firmware'), title: versionFirmwareText()),
//           ListTile(contentPadding: EdgeInsets.zero, dense: null, subtitle: Text('Board'), title: versionBoardText()),
//           ListTile(contentPadding: EdgeInsets.zero, subtitle: Text('Serial Number'), title: Text(Reference().motManufacturer.serialNumber.charsMsb.toString())),
//           ListTile(contentPadding: EdgeInsets.zero, subtitle: Text('Manufacture Number'), title: Text(Reference().motManufacturer.manufactureNumber.charsMsb.toString())),
//           // Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: []),
//           // Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: []),
//         ],
//       ),
//     );
//   }
// }


