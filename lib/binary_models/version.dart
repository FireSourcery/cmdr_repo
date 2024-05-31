import '../binary_data/word_fields.dart';
import '../binary_data/typed_field.dart';

/// standard [optional, major, minor, fix] version
class Version extends WordFieldsBase<WordField<NativeType>> {
// parameterizing T can constrain functions of T key to types the Version is defined with
// class Version<T extends VersionField> extends WordFields<VersionField> {

  const Version._standard(int optional, int major, int minor, int fix, [this.name])
      : keys = VersionFieldStandard.values,
        super.of8s(fix, minor, major, optional);

  const factory Version(int optional, int major, int minor, int fix, [String? name]) = VersionStandard;

  const Version.wide(int optional, int major, int minor, int fix, {this.name, required this.keys}) : super.of16s(fix, minor, major, optional);
  const Version.init(super.value, {this.name, this.keys = VersionFieldStandard.values}) : super(); // e.g. a stored value

  @override
  Version copyWithBase(int state) => Version.init(state, name: name, keys: keys);
  // Version copyWithBase(WordFields state) => Version.init(state.fold(), name: name, keys: keys);
  ///
  // Version.initWith(Map<VersionFieldStandard, int> newValue, [String? name]) : this.value(newValue.fold(), name);
  // Version updateWithMap(Map<VersionFieldStandard, int> newValue) => Version.initWith(newValue, name);

  @override
  final List<WordField<NativeType>> keys;
  @override
  final String? name;
  @override
  (String, String) get labelPair => (name ?? '', toStringAsVersion());
  // @override
  // int get byteLength => (value.byteLength > 4) ? 8 : 4;

  /// alias
  List<int> get numbers => values.toList();
  Version withNumber(WordField key, int value) => modifyEntry(key, value);
  Version withAll(Map<WordField, int> map) => modifyAll(map);
  // Version updateNumbers(Iterable<int> numbers) => modifyEntriesAs( numbers);

  /// msb first with dot separator `optional.major.minor.fix`
  String toStringAsVersion([String left = '', String right = '', String separator = '.']) {
    return (StringBuffer(left)
          ..writeAll(numbers.reversed, separator)
          ..write(right))
        .toString();
  }

  /// Json
  factory Version.fromJson(Map<String, dynamic> json) {
    return Version.init(
      json['value'] as int,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': bits,
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

  factory Version.ofMapEntry(MapEntry<String, int> entry) => Version.init(entry.value, name: entry.key);

  MapEntry<String, int> toMapEntry() => MapEntry<String, int>(name ?? '', bits);

  @override
  bool operator ==(covariant Version other) {
    if (identical(this, other)) return true;

    return other.name == name && other.bits == bits;
  }

  @override
  int get hashCode => name.hashCode ^ bits.hashCode;
}

enum VersionFieldStandard with TypedField<Uint8> implements WordField<Uint8> {
  fix(0),
  minor(1),
  major(2),
  optional(3),
  ;

  const VersionFieldStandard(this.offset);
  @override
  final int offset;
}

class VersionStandard extends Version {
  const VersionStandard(super.optional, super.major, super.minor, super.fix, [super.name]) : super._standard();

  @override
  List<VersionFieldStandard> get keys => VersionFieldStandard.values;

  int get fix => this[VersionFieldStandard.fix];
  int get minor => this[VersionFieldStandard.minor];
  int get major => this[VersionFieldStandard.major];
  int get optional => this[VersionFieldStandard.optional];

  /// Json
  // factory Version.fromJson(Map<String, dynamic> json) {
  //   return fromJson(json);
  // }

  Version copyWith({int? optional, int? major, int? minor, int? fix, String? name}) {
    return Version(optional ?? this.optional, major ?? this.major, minor ?? this.minor, fix ?? this.fix, name ?? this.name);
  }
}

 
// enum VersionFieldStandard<T extends NativeType> with TypedField<T> implements WordField<T> {
//   fix<Uint8>(0),
//   minor<Uint8>(1),
//   major<Uint8>(2),
//   optional<Uint8>(3),
//   ;

//   const VersionFieldStandard(this.offset);
//   @override
//   final int offset;
// }
