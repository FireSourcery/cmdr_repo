// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

class Version {
  const Version(this.value);
  const Version.chars(int optional, int major, int minor, int fix) : value = optional << 24 | major << 16 | minor << 8 | fix;
  // const Version.from(int? value) : value = value ?? 0;
  factory Version.list(List<int> chars, [Endian endian = Endian.little]) {
    return switch (endian) {
      Endian.big => Version.chars(chars[3], chars[2], chars[1], chars[0]),
      Endian.little => Version.chars(chars[0], chars[1], chars[2], chars[3]),
      _ => throw UnsupportedError('$endian'),
    };
  }

  factory Version.string(String string) => Version.list(string.runes.toList(), Endian.big);

  final int value;
  // final String? label;

  static List<int> charViewOf(int rawValue, [Endian endian = Endian.little]) => Uint8List(4)..buffer.asByteData().setUint32(0, rawValue, endian);
  // final int size;
  // static List<int> charViewOf(int rawValue, [Endian endian = Endian.little]) => Uint8List(size)..buffer.asByteData().setUint32(0, rawValue, endian);

  List<int> get charsMsb => charViewOf(value, Endian.big);
  List<int> get charsLsb => charViewOf(value, Endian.little);

  @override
  String toString([Endian endian = Endian.big]) => charViewOf(value, endian).toString();

  factory Version.fromJson(Map<String, dynamic> json) {
    return Version(
      json['value'] as int,
    );
    // return Version(jsonDecode(json['value'] as String) as int);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'value': value,
      'description': toString(),
    };
    // return <String, dynamic>{'value': charViewOf(value).toString()};
  }

  @override
  bool operator ==(covariant Version other) => other.value == value;

  @override
  int get hashCode => value.hashCode;
}
