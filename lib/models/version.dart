import 'dart:typed_data';

import 'package:cmdr/byte_struct.dart';
import 'package:cmdr/byte_struct/byte_struct.dart';
import 'package:recase/recase.dart';

import '../byte_struct/word_fields.dart';
import '../byte_struct/typed_field.dart';
import '../byte_struct/word.dart';
import '../common/enum_struct.dart';

/// standard [optional, major, minor, fix] version
class Version extends Word with WordFields<VersionFieldStandard>, EnumStruct<VersionFieldStandard, int> {
  const Version(super.optional, super.major, super.minor, super.fix, [this.name]) : super.msb32();
  const Version.value(super.value, [this.name]) : super(); // e.g. a stored value
  const Version.from(int? value, [Endian endian = Endian.little, this.name]) : super(value ?? 0); // e.g. a network value
  // Version.cast(super.word, [this.name]) : super.cast();
  Version updateFrom(int? value, [Endian endian = Endian.little]) => Version.from(value, endian, name);

  final String? name;

  @override
  int get byteLength => (super.byteLength > 4) ? 8 : 4;

  @override
  String? get varLabel => name;
  @override
  List<VersionFieldStandard<NativeType>> get fields => VersionFieldStandard.values;

  (String, String) get asLabeledPair => (name ?? '', toStringAsVersion());

  int get fix => bytesLE[0];
  int get minor => bytesLE[1];
  int get major => bytesLE[2];
  int get optional => bytesLE[3];

  // new buffer
  // [optional, major, minor, fix][0,0,0,0]
  Uint8List get version => toBytesAs(Endian.big); // trimmed view on new buffer big endian 8 bytes
  Version updateVersion(Uint8List bytes) => Version.value(bytes.buffer.toInt(0, Endian.big), name);

  List<int> get numbers => toBytesAs(Endian.big);
  Version updateNumbers(List<int> numbers) => (numbers is Uint8List) ? updateVersion(version) : Version.value(numbers.toBytes().toInt(Endian.big), name);

  // msb first with dot separator
  String toStringAsVersion([String left = '', String right = '', String separator = '.']) {
    return (StringBuffer(left)
          ..writeAll(version, separator)
          ..write(right))
        .toString();
  }

  /// Json
  factory Version.fromJson(Map<String, dynamic> json) {
    return Version.value(
      json['value'] as int,
      json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': value,
      'description': toStringAsVersion(),
    };
  }

  factory Version.fromMapEntry(MapEntry<dynamic, dynamic> entry) {
    if (entry case MapEntry<String, int>()) {
      return Version.ofMapEntry(entry);
    } else {
      throw UnsupportedError('Unsupported type');
    }
  }

  factory Version.ofMapEntry(MapEntry<String, int> entry) => Version.value(entry.value, entry.key);

  MapEntry<String, int> toMapEntry() => MapEntry<String, int>(name ?? '', value);

  @override
  bool operator ==(covariant Version other) {
    if (identical(this, other)) return true;

    return other.name == name && other.value == value;
  }

  @override
  int get hashCode => name.hashCode ^ value.hashCode;

  // Version copyWith({
  //   // int? optional,
  //   // int? major,
  //   // int? minor,
  //   // int? fix,
  //   String? name,
  // }) {
  //   return Version.value(
  //     value ?? this.value,
  //   );
  // }
}

// /// configurable Version
// abstract mixin class VersionFields implements Word {
//   const VersionFields();

//   List<VersionField<NativeType>> get fields;

//   Iterable<int> get numbers => fields.map((e) => e.valueOfInt(value));
//   Iterable<String> get labels => fields.map((e) => e.label);

//   String toStringAsVersion([String left = '', String right = '', String separator = '.']) {
//     return (StringBuffer(left)
//           ..writeAll(numbers, separator)
//           ..write(right))
//         .toString();
//   }
// }

enum VersionFieldStandard<T extends NativeType> with TypedField<T>, WordField<T> {
  fix<Uint8>(0),
  minor<Uint8>(1),
  major<Uint8>(2),
  optional<Uint8>(3),
  ;

  const VersionFieldStandard(this.offset);
  @override
  final int offset;
}
