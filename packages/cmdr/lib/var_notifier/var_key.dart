part of 'var_notifier.dart';

//remove valuekey if mixin unionkey
@immutable
abstract mixin class VarKey implements ValueKey<int> {
  const VarKey();

  @override
  int get value; // int id of the key, NOT the value of associated Var

  // the varNotifier type parameter
  TypeKey<dynamic> get viewType => binaryFormat!.viewType; // override if binaryFormat is null
  BinaryFormat? get binaryFormat;
  ViewOfData? get viewOfData;
  DataOfView? get dataOfView;

  /// Union type properties.
  ({num min, num max})? get valueNumLimits;
  List<Enum>? get valueEnumRange;
  List<BitField>? get valueBitsKeys;
  int? get valueStringDigits;
  // num? get valueDefault;

  bool get isReadOnly; // isPushing == false

  // should not be both, that would incur real-time loopback
  bool get isPolling; // polling, all readable. Processed by read stream
  bool get isPushing; // pushing, selected writable, other writable updated on change, processed by write stream

  List<VarKey>? get dependents;

  VarStatus varStatusOf(int code); // should only be one. instances shared
  T subtypeOf<T>(num value) => throw UnsupportedError('valueAsSubtype: $T');
  num valueOfSubtype<T>(T value) => throw UnsupportedError('viewOfSubtype: $T');

  // value stringifier
  String stringify<V>(V value);
  // String stringify<V>(V? value);

  /// Tag properties
  // VarTag? get tag;
  String get label;
  String? get suffix;
  String? get tip;
  // Units get units;
  // primaryCategory, secondaryCategory, tertiaryCategory

  /// View Widgets properties

  // @override
  String toString() {
    return '$runtimeType<${binaryFormat?.viewType.type}>(`$label` $value)';
  }
}

// enum VarReadWrite {
//   readOnly,
//   readWrite,
//   writeOnly,
//   ;
// }

extension VarMinMaxs on Iterable<VarKey> {
  Iterable<({num min, num max})?> get viewMinMaxs => map((e) => e.valueNumLimits);
  Iterable<num> get viewMaxs => viewMinMaxs.map((e) => e?.max).nonNulls;
  Iterable<num> get viewMins => viewMinMaxs.map((e) => e?.min).nonNulls;
  num get viewMax => viewMaxs.max;
  num get viewMin => viewMins.min;
}

// generalize as system status, 0 -> ok, -1 -> error
// does not implement Enum, as it can be a union of Enums
abstract mixin class VarStatus implements Exception {
  factory VarStatus.defaultCode(int code) => VarStatusDefault.values.elementAtOrNull(code) ?? VarStatusUnknown.unknown;

  // static const int defaultErrorCode = -1;

  int get code;
  String get message;
  Enum? get enumId; // null or meta default
  bool get isSuccess => code == 0;
  bool get isError => code != 0;
}

// mixin on enum to implement the Status interface
abstract mixin class VarEnumStatus implements VarStatus, Enum {
  int get code => index;
  String get message => name;
  Enum get enumId => this;
}

enum VarStatusDefault with VarStatus, VarEnumStatus {
  success,
  error,
  // warning,
  // info,
  // none,
  ;

  factory VarStatusDefault.of(int code) => VarStatusDefault.values.elementAt(code);
}

enum VarStatusUnknown with VarStatus {
  unknown;

  @override
  int get code => -1;
  @override
  Enum? get enumId => this;
  @override
  String get message => name;
}

// optional properties
// class VarTag {
//   const VarTag({
//     required this.label,
//     // required this.unitsLabel,
//     required this.valueType,
//     required this.valueMin,
//     required this.valueMax,
//     required this.valueDefault,
//     required this.valueList,
//     required this.valueMap,
//     required this.valueEnum,
//   });

//   final String label;
//   final String suffix;
//   final Type valueType;
//   final num valueMin;
//   final num valueMax;
//   final num valueDefault;
//   final List<num> valueList;
//   final Map<num, String> valueMap;
//   final List<Enum> valueEnum;

// typed filter via having()
// }
