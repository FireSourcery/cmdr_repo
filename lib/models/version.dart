// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

import '../byte_struct/word.dart';

class Version extends Word {
  const Version(super.value, [this.name]);
  // const Version.littleEndian(super.value, [this.name]);
  const Version.chars(super.optional, super.major, super.minor, super.fix, [this.name]) : super.value32();
  const Version.fromNullable(int? value, [this.name]) : super(value ?? 0);
  Version.cast(Word word, [this.name]) : super(word.value);

  Version.string(super.string, [this.name]) : super.string();

  final String? name;
  // final bool isExtended = false;

  bool get isZero => (value == 0);
  int get length => (size > 4) ? 8 : 4;

  // @override

  String toStringAsVersion([String left = '', String right = '', String separator = '.']) {
    return (StringBuffer(left)
          ..writeAll(bytesBE.take(length), separator)
          ..write(right))
        .toString();
  }

  /// Json
  factory Version.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
    // return Version(
    //   jsonDecode(json['value'] as String) as List,
    //   json['name'] != null ? json['name'] as String : null,
    //   // json['value'] as int,
    // );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': jsonEncode(bytesBE),
      // 'value': value,
      // 'description': super.toString(),
    };
  }

  factory Version.fromMapEntry(MapEntry<dynamic, dynamic> entry) {
    if (entry case MapEntry<String, int>()) {
      return Version.ofMapEntry(entry);
    } else {
      throw UnsupportedError('Unsupported type');
    }
  }

  factory Version.ofMapEntry(MapEntry<String, int> entry) {
    return Version(entry.value, entry.key);
  }

  MapEntry<String, int> toMapEntry() {
    return MapEntry<String, int>(name ?? '', value);
  }

  @override
  bool operator ==(covariant Version other) => other.value == value;

  @override
  int get hashCode => value.hashCode;

  Version copyWith({
    // String? name,
    int? value,
  }) {
    return Version(
      value ?? this.value,
    );
  }
}
