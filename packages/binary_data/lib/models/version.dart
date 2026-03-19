import '../word/word_struct.dart';

export '../data/serializable.dart'; // export EnumMap

/// 4 fields [optional, major, minor, fix] by default, 1 or 2 bytes each
/// parameterize T to constrain functions of T key to types the Version is defined with
abstract base class Version<K extends WordField> extends WordBase<Version<K>, K> {
  // uses VersionFieldStandard keys when no keys AND type parameter is specified
  factory Version(int optional, int major, int minor, int fix, {String? name}) => VersionStandard(optional, major, minor, fix, name: name) as Version<K>;
  // prototype object that can be copied
  // Version.prototype
  const factory Version.withType(List<K> keys, {int value, String? name}) = VersionConstruct<K>;

  // for inherting classe
  const Version.withData(super.word) : super();
  const Version.value(int value) : super.value(value);
  const Version.char8(int optional, int major, int minor, int fix) : this.value(fix | (minor << 8) | (major << 16) | (optional << 24));
  const Version.char16(int optional, int major, int minor, int fix) : this.value(fix | (minor << 16) | (major << 32) | (optional << 48));

  @override
  List<K> get keys;

  String? get name => runtimeType.toString();

  Bits get bits => word;
  int get byteLength => (word.byteLength > 4) ? 8 : 4;

  /// alias
  Iterable<int> get values => fields;
  List<int> get numbers => [optional, major, minor, fix]; // in big endian order // [fix, minor, major, optional]

  /// order by default, size determined by key type, T.
  int get fix => this[keys[0]];
  int get minor => this[keys[1]];
  int get major => this[keys[2]];
  int get optional => this[keys[3]];

  (String, String) get labelPair => (name ?? '', toStringAsVersion());

  MapEntry<String, int> toMapEntryByName() => MapEntry<String, int>(name ?? '', bits);

  /// msb first with dot separator `optional.major.minor.fix`
  String toStringAsVersion([String left = '', String right = '', String separator = '.']) {
    return (StringBuffer(left)
          ..writeAll(numbers, separator)
          ..write(right))
        .toString();
  }

  MapEntry<String, String> toStringAsVersionEntry([String left = '', String right = '', String separator = '.']) {
    return MapEntry<String, String>(name ?? 'version', toStringAsVersion(left, right, separator));
  }

  // factory Version.fromMapEntry(MapEntry<dynamic, dynamic> entry) {
  //   if (entry case MapEntry<String, int>()) {
  //     return Version.init(entry.value, name: entry.key);
  //   } else {
  //     throw UnsupportedError('Unsupported type');
  //   }
  // }

  /// Json
  /// pass keys or alternatively implement in List<K> keys extension
  // factory Version.fromJson(Map<String, dynamic> json, {List<K>? keys}) {
  //   return VersionStandard.init(
  //     json['value'] as int,
  //     name: json['name'] as String?,
  //   ) as Version<K>;
  // }

  // same as implemented by WordStruct
  // Map<String, Object> toJsonVerbose() => toMap().toJson();
  Map<String, Object> toJsonVerbose() {
    return <String, Object>{
      'fix': fix,
      'minor': minor,
      'major': major,
      'optional': optional,
    };
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'name': name ?? K.toString(),
      'value': bits,
      'description': numbers,
    };
  }

  MapEntry<String, Object> toJsonAsEntry() {
    return MapEntry<String, Object>(name!, numbers.toString());
  }

  @override
  bool operator ==(covariant Version<K> other) {
    if (identical(this, other)) return true;
    return other.name == name && other.bits == bits;
  }

  @override
  int get hashCode => name.hashCode ^ bits.hashCode;

  bool operator <(Version other) => bits < other.bits;
  bool operator >(Version other) => bits > other.bits;
  bool operator <=(Version other) => bits <= other.bits;
  bool operator >=(Version other) => bits >= other.bits;

  @override
  String toString() => toStringAsVersion();
}

/// flexible keys
// ignore: missing_override_of_must_be_overridden
base class VersionConstruct<K extends WordField> extends Version<K> {
  const VersionConstruct(this.keys, {this.name, int value = 0}) : super.value(value);
  const VersionConstruct.withData(this.keys, super.data, {this.name}) : super.withData();
  @override
  final List<K> keys;
  @override
  final String? name;

  Version<K> copyWithData(WordStruct<K> data, {String? name}) {
    return VersionConstruct.withData(keys, data, name: name ?? this.name);
  }
}

// byte size chars
base class VersionStandard extends Version<VersionFieldStandard> {
  const VersionStandard(super.optional, super.major, super.minor, super.fix, {this.name = 'Version'}) : super.char8();
  const VersionStandard.withData(super.data, {this.name = 'Version'}) : super.withData();
  const VersionStandard.value(super.value, {this.name = 'Version'}) : super.value();

  @override
  List<VersionFieldStandard> get keys => VersionFieldStandard.values;

  @override
  final String? name;

  int get fix => this[VersionFieldStandard.fix];
  int get minor => this[VersionFieldStandard.minor];
  int get major => this[VersionFieldStandard.major];
  int get optional => this[VersionFieldStandard.optional];

  // generates withX, WordBase handles copy
  VersionStandard copyWithData(WordStruct<VersionFieldStandard> data, {String? name}) {
    return VersionStandard.withData(data, name: name ?? this.name);
  }

  VersionStandard copyWith({int? optional, int? major, int? minor, int? fix, String? name}) {
    return VersionStandard(
      optional ?? this.optional,
      major ?? this.major,
      minor ?? this.minor,
      fix ?? this.fix,
      name: name ?? this.name,
    );
  }
}

enum VersionFieldStandard with TypedField<Uint8>, WordField<Uint8> {
  fix(0),
  minor(1),
  major(2),
  optional(3);

  const VersionFieldStandard(this.offset);
  @override
  final int offset;
}
