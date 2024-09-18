import '../binary_data/word_fields.dart';
import '../binary_data/typed_field.dart';
import '../binary_data/bits.dart';

/// standard [optional, major, minor, fix] version
// class Version extends WordFieldsBase<WordField<NativeType>> {
// parameterize to constrain functions of T key to types the Version is defined with
abstract class Version<T extends WordField> extends WordFieldsBase<T> {
  // const factory Version(int optional, int major, int minor, int fix, [String? name]) = VersionStandard;
  factory Version(int optional, int major, int minor, int fix, [String? name]) => VersionStandard(optional, major, minor, fix, name: name) as Version<T>;

  /// [List<T> keys] effectively infers type parameter T
  // uses VersionFieldStandard keys when no keys AND type parameter is specified
  // const Version(int optional, int major, int minor, int fix, {this.name, this.keys = VersionFieldStandard.values}) : super.of8s(fix, minor, major, optional);
  // const Version.init(super.value, {this.name, this.keys = VersionFieldStandard.values as List<T>}) : super(); // e.g. a stored value

  // // withKeys, alternatively make abstract
  // // key width must match constructor init width
  // // 4 bytes with 4 bytes padding
  // const Version.char8(int optional, int major, int minor, int fix, {this.name, required this.keys}) : super.of8s(fix, minor, major, optional);
  // const Version.char16(int optional, int major, int minor, int fix, {this.name, required this.keys}) : super.of16s(fix, minor, major, optional);
  // const Version(int optional, int major, int minor, int fix, {this.name}) : super.of8s(fix, minor, major, optional);

  const Version.word(super.value, {this.name}) : super(); // e.g. a stored value
  const Version.char8(int optional, int major, int minor, int fix, {this.name}) : super.of8s(fix, minor, major, optional);
  const Version.char16(int optional, int major, int minor, int fix, {this.name}) : super.of16s(fix, minor, major, optional);

  @override
  Version<T> copyWith({Bits? bits, String? name}) {
    return VersionWithKeys.word(bits ?? this.bits, name: name ?? this.name, keys: keys);
    // return createWith(super.copyWith(bits ?? this.bits));
  }

  @override
  // final List<T> keys; // alternatively make abstract and keep as getter
  List<T> get keys; // alternatively make abstract and keep as getter
  // @override
  final String? name;

  // @override
  (String, String) get labelPair => (name ?? '', toStringAsVersion());
  // @override
  // int get byteLength => (value.byteLength > 4) ? 8 : 4;

  /// alias
  List<int> get numbers => values.toList(); // [fix, minor, major, optional]
  Version<T> withNumber(T key, int value) => copyWithEntry(key, value) as Version<T>;
  Version<T> withAll(Map<T, int> map) => copyWithMap(map) as Version<T>;
  // Version<T> withVersion(Version<T> version) => copyWithMap(version) as Version<T>;

  /// msb first with dot separator `optional.major.minor.fix`
  String toStringAsVersion([String left = '', String right = '', String separator = '.']) {
    return (StringBuffer(left)
          ..writeAll(numbers.reversed, separator)
          ..write(right))
        .toString();
  }

  /// Json
  // factory Version.fromJson(Map<String, dynamic> json) {
  //   return VersionStandard.init(
  //     json['value'] as int,
  //     name: json['name'] as String?,
  //   ) as Version<T>;
  // }

  // Version<T> withJson(Map<String, dynamic> json) {
  //   return createWith(copyWithMap(map));
  // }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': bits,
      'description': toStringAsVersion(),
    };
  }

  // factory Version.fromMapEntry(MapEntry<dynamic, dynamic> entry) {
  //   if (entry case MapEntry<String, int>()) {
  //     return Version.ofMapEntry(entry);
  //   } else {
  //     throw UnsupportedError('Unsupported type');
  //   }
  // }

  // factory Version.ofMapEntry(MapEntry<String, int> entry) => Version.init(entry.value, name: entry.key);

  MapEntry<String, int> toMapEntry() => MapEntry<String, int>(name ?? '', bits);

  @override
  bool operator ==(covariant Version<T> other) {
    if (identical(this, other)) return true;

    return other.name == name && other.bits == bits;
  }

  @override
  int get hashCode => name.hashCode ^ bits.hashCode;
}

class VersionWithKeys<T extends WordField> extends Version<T> {
  const VersionWithKeys.word(super.value, {super.name, required this.keys}) : super.word();
  const VersionWithKeys.char8(int optional, int major, int minor, int fix, {super.name, required this.keys}) : super.char8(fix, minor, major, optional);
  const VersionWithKeys.char16(int optional, int major, int minor, int fix, {super.name, required this.keys}) : super.char16(fix, minor, major, optional);

  @override
  final List<T> keys;
}

class VersionStandard extends Version<VersionFieldStandard> {
  const VersionStandard(super.optional, super.major, super.minor, super.fix, {super.name}) : super.char8();
  const VersionStandard.word(super.value, {super.name}) : super.word();

  // VersionStandard.createWith(BitsMap<VersionFieldStandard, int> state) : super.createWith(state);

  @override
  List<VersionFieldStandard> get keys => VersionFieldStandard.values;

  int get fix => this[VersionFieldStandard.fix];
  int get minor => this[VersionFieldStandard.minor];
  int get major => this[VersionFieldStandard.major];
  int get optional => this[VersionFieldStandard.optional];

  // VersionStandard createWith(BitsMap<VersionFieldStandard, int> state) => VersionStandard.create(state);

  /// Json
  // factory Version.fromJson(Map<String, dynamic> json) {
  //   return fromJson(json);
  // }

  @override
  Version<VersionFieldStandard> copyWith({Bits? bits, int? optional, int? major, int? minor, int? fix, String? name}) {
    // bits is unused
    return VersionStandard(
      optional ?? this.optional,
      major ?? this.major,
      minor ?? this.minor,
      fix ?? this.fix,
      name: name ?? this.name,
    );
  }
}

enum VersionFieldStandard with TypedField<Uint8>, WordField<Uint8> implements WordField<Uint8> {
  fix(0),
  minor(1),
  major(2),
  optional(3),
  ;

  const VersionFieldStandard(this.offset);
  @override
  final int offset;
}
