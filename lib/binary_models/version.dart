import 'package:cmdr/binary_data/bitfield.dart';
import 'package:cmdr/binary_data/bits_map.dart';

import 'package:cmdr/common/enum_map.dart';

import '../binary_data/word_fields.dart';
import '../binary_data/typed_field.dart';
import '../binary_data/bits.dart';

/// 4 fields [optional, major, minor, fix] by default, 1 or 2 bytes each
/// parameterize T to constrain functions of T key to types the Version is defined with
/// alternatively `class Version extends WordFieldsBase<WordField<NativeType>>` allows for access with any WordField key
abstract class Version<T extends WordField> extends WordFieldsBase<T> with EnumMapAsSubtype<Version<T>, T, int> {
  // uses VersionFieldStandard keys when no keys AND type parameter is specified
  factory Version(int optional, int major, int minor, int fix, {String? name}) => VersionStandard(optional, major, minor, fix, name: name) as Version<T>;
  // factory Version(int optional, int major, int minor, int fix, {String? name}) = VersionStandard  ;
  const factory Version.withKeys(List<T> keys, int value, {String? name}) = _VersionWithKeys<T>;

  // user must manually ensure keys match the width of the constructor. this is the only way to define as compile time const
  const Version.word(super.value, {this.name}) : super(); // e.g. a stored value
  const Version.char8(int optional, int major, int minor, int fix, {this.name}) : super.of8s(fix, minor, major, optional);
  const Version.char16(int optional, int major, int minor, int fix, {this.name}) : super.of16s(fix, minor, major, optional);

  // Version.values(List<T> keys, Iterable<int> values, {String? name}) : this.word(Bits.ofIterables(keys.bitmasks, values), name: name);

  // Version.cast(super.state, {this.name}) : super.cast();
  Version.fromBase(super.state, {this.name}) : super.cast();

  // @override
  // Version<T> copyWith({Bits? bits, String? name}) {
  //   return _VersionWithKeys.word(bits ?? this.bits, name: name ?? this.name, keys: keys);
  // }
  @override
  List<T> get keys;
  // @override
  final String? name; //move this to typedef VersionClassObject<T> = ({Version, String});?

  // @override
  // Version<T> copyWithBits(Bits value, {String? name}) => _VersionWithKeys(keys, bits, name: name ?? this.name);

  // @override
  // Version<T> copyWith( );

  // defaults to 4 fields. alternatively leave undefined
  // @override
  Version<T> copyWithStandard({int? optional, int? major, int? minor, int? fix, String? name}) {
    return _VersionWithKeys(
      keys,
      Bits.ofMap({
        keys[0].bitmask: fix ?? this.fix,
        keys[1].bitmask: minor ?? this.minor,
        keys[2].bitmask: major ?? this.major,
        keys[3].bitmask: optional ?? this.optional,
      }),
      name: name ?? this.name,
    );
    // T size is not known until defined child class
  }

  @override
  int get byteLength => (bits.byteLength > 4) ? 8 : 4;

  // @override
  (String, String) get labelPair => (name ?? '', toStringAsVersion());

  /// alias
  List<int> get numbers => values.toList(); // [fix, minor, major, optional]

  /// order by default, size determined by key type, T.
  int get fix => this[keys[0]];
  int get minor => this[keys[1]];
  int get major => this[keys[2]];
  int get optional => this[keys[3]];

  Version<T> withNumber(T key, int value) => withField(key, value);

  // todo automatic type conversion
  // @override
  // Version<T> withAll(Map<T, int> map) => super.withAll(map) as Version<T>;
  // @override
  // Version<T> withEntries(Iterable<MapEntry<T, int>> entries) => super.withEntries(entries) as Version<T>;
  // @override
  // Version<T> withField(T key, int value) => super.withField(key, value) as Version<T>;

  /// msb first with dot separator `optional.major.minor.fix`
  String toStringAsVersion([String left = '', String right = '', String separator = '.']) {
    return (StringBuffer(left)
          // ..writeAll(numbers.reversed, separator)
          ..writeAll([optional, major, minor, fix], separator)
          ..write(right))
        .toString();
  }

  /// Json
  /// pass keys or alternatively implement in List<T> keys extension
  // factory Version.fromJson(Map<String, dynamic> json, {List<T>? keys}) {
  //   return VersionStandard.init(
  //     json['value'] as int,
  //     name: json['name'] as String?,
  //   ) as Version<T>;
  // }

  // Version<T> withJson(Map<String, dynamic> json) {
  //   return createWith(copyWithMap(map));
  // }

  // @override
  // Map<String, dynamic> toJson() {
  //   // by default returns keyed fields
  //   // {
  //   //   'fix': fix,
  //   //   'minor': minor,
  //   //   'major': major,
  //   //   'optional': optional,
  //   // }
  //   // return <String, dynamic>{
  //   //   'name': name,
  //   //   'value': bits,
  //   //   'description': toStringAsVersion(),
  //   // };
  // }

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

  bool operator <(Version other) => bits < other.bits;
  bool operator >(Version other) => bits > other.bits;
  bool operator <=(Version other) => bits <= other.bits;
  bool operator >=(Version other) => bits >= other.bits;
}

// ignore: missing_override_of_must_be_overridden
class _VersionWithKeys<T extends WordField> extends Version<T> {
  const _VersionWithKeys(this.keys, super.value, {super.name}) : super.word();
  _VersionWithKeys.fromBase(this.keys, super.state, {super.name}) : super.fromBase();

  _VersionWithKeys.fromValues(List<T> keys, Iterable<int> values, {String? name}) : this(keys, Bits.ofIterables(keys.bitmasks, values), name: name);

  // _VersionWithKeys.fromFields(this.keys, int optional, int major, int minor, int fix, {super.name}) : super.fromBase();

  // @override
  // Version<T> copyWith({Iterable<int> values}) {
  //   return _VersionWithKeys(
  //     keys,
  //     Bits.ofMap({
  //       keys[0].bitmask: fix ?? this.fix,
  //       keys[1].bitmask: minor ?? this.minor,
  //       keys[2].bitmask: major ?? this.major,
  //       keys[3].bitmask: optional ?? this.optional,
  //     }),
  //     name: name ?? this.name,
  //   );
  //   // T size is not known until defined child class
  // }

  @override
  final List<T> keys;
}

class VersionStandard extends Version<VersionFieldStandard> {
  const VersionStandard(super.optional, super.major, super.minor, super.fix, {super.name}) : super.char8();
  const VersionStandard.word(super.value, {super.name}) : super.word();

  // VersionStandard.cast(super.state) : super.cast();

  @override
  List<VersionFieldStandard> get keys => VersionFieldStandard.values;

  @override
  String get name => super.name ?? 'Version';

  @override
  int get fix => this[VersionFieldStandard.fix];
  @override
  int get minor => this[VersionFieldStandard.minor];
  @override
  int get major => this[VersionFieldStandard.major];
  @override
  int get optional => this[VersionFieldStandard.optional];

  /// Json
  // factory Version.fromJson(Map<String, dynamic> json) {
  //   return fromJson(json);
  // }

  @override
  Version<VersionFieldStandard> copyWith({int? optional, int? major, int? minor, int? fix, String? name}) {
    return VersionStandard(
      optional ?? this.optional,
      major ?? this.major,
      minor ?? this.minor,
      fix ?? this.fix,
      name: name ?? this.name,
    );
  }

  // @override
  // Version<VersionFieldStandard> copyWithBits(Bits value, {String? name}) => VersionStandard.word(bits, name: name ?? this.name);
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
