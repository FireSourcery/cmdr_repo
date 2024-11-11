part of 'var_notifier.dart';

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
  // Units get units;
  // num? get valueDefault;

  List<VarKey>? get dependents;

  VarStatus varStatusOf(int code); // should only be one. instances shared

  String stringify<V>(V value);
  // String stringify<V>(V? value);

  /// Union type properties.
  ({num min, num max})? get valueNumLimits;
  List<Enum>? get valueEnumRange;
  List<BitFieldKey>? get valueBitsKeys;
  int? get valueStringDigits;

  // // replace with cache type
  // bool get isRealTime;
  // bool get isConfig;

  bool get isReadOnly; // isPushing == false

  // should not be both, that would incur real-time loopback
  bool get isPolling; // polling, all readable. Processed by read stream
  bool get isPushing; // pushing, selected writable, other writable updated on change, processed by write stream

  /// Tag properties
  // VarTag? get tag;
  String get label;
  // primaryCategory, secondaryCategory, tertiaryCategory
  String? get suffix;
  String? get tip;

  /// View Widgets properties
  ///

  // @override
  // String toString() {
  //   // return '[$runtimeType: <$value>]';
  //   return '[$runtimeType ${binaryFormat?.viewType.type} <$value>]';
  // }
}

extension VarMinMaxs on Iterable<VarKey> {
  ////////////////////////////////////////////////////////////////////////////////
  /// Collective view min max
  ////////////////////////////////////////////////////////////////////////////////
  Iterable<({num min, num max})?> get viewMinMaxs => map((e) => e.valueNumLimits);
  Iterable<num> get viewMaxs => viewMinMaxs.map((e) => e?.max).whereNotNull();
  Iterable<num> get viewMins => viewMinMaxs.map((e) => e?.min).whereNotNull();
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
