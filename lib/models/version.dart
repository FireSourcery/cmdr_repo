import 'dart:typed_data';

import 'package:cmdr/byte_struct.dart';

import '../byte_struct/word.dart';

class Version extends Word {
  const Version(super.optional, super.major, super.minor, super.fix, [this.name]) : super.value32();
  const Version.value(super.value, [this.name]) : super(); // e.g. a stored value
  const Version.from(int? value, [this.name]) : super(value ?? 0); // e.g. a network value
  // Version.cast(super.word, [this.name]) : super.cast();

  final String? name;

  @override
  int get byteLength => (super.byteLength > 4) ? 8 : 4;

  int get fix => bytesLE[0];
  int get minor => bytesLE[1];
  int get major => bytesLE[2];
  int get optional => bytesLE[3];

  // [0,0,0,0][optional, major, minor, fix]
  // Version.numbers(Uint8List value, [this.name]) : super.byteBuffer(value.buffer, 0, Endian.big);
  Uint8List get version => toBytesAs(Endian.big); // trimmed view on new buffer big endian 8 bytes
  Version updateVersion(Uint8List bytes) => Version.value(bytes.buffer.toInt(0, Endian.big), name);

  // List<int> get numbers => toBytesAs(Endian.big).sublist(0);
  // Version updateNumbers(List<int> numbers) => Version.value(numbers.toBytes().toInt(Endian.big), name);

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
  bool operator ==(covariant Version other) => other.value == value;

  @override
  int get hashCode => value.hashCode;

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

class NameId extends Word {
  NameId(super.string) : super.string();
  // Word.chars(Iterable<int> bytes, [Endian endian = Endian.little])
}
