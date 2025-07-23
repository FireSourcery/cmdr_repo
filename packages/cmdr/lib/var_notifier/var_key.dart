part of 'var_notifier.dart';

/// [VarKey] is an immutable key for [VarNotifier].
/// immutable properties of a VarNotifier
/// == and hash from ValueKey
@immutable
abstract mixin class VarKey implements ValueKey<int> {
  const VarKey();

  @override
  int get value; // int id of the key, NOT the value of associated Var
  int get id => value;

  // the varNotifier type parameter
  TypeKey<dynamic> get viewType; // binaryFormat!.viewType; // override if binaryFormat is null
  // BinaryFormat? get binaryFormat; // can depreciate

  /// Data numeric conversion
  int Function(int binary)? get signExtension;
  ViewOfData? get viewOfData;
  DataOfView? get dataOfView;

  /// Union type properties.
  ({num min, num max})? get valueNumLimits;
  List<Enum>? get valueEnumRange;
  List<BitField>? get valueBitsKeys;

  int? get valueStringDigits;
  // num? get valueDefault;

  T subtypeOf<T>(num value) => throw UnsupportedError('valueAsSubtype: $T');
  num valueOfSubtype<T>(T value) => throw UnsupportedError('viewOfSubtype: $T');

  // optionally override with subtype
  VarStatus varStatusOf(int code); // should only be one. instances shared

  /// Service properties
  // should not be both, that would be real-time loopback
  bool get isPolling; // polling, all readable. Processed by read stream
  bool get isPushing; // pushing, selected writable, other writable updated on change, processed by write stream

  bool get isReadOnly; // isPushing == false
  bool get isWriteOnly;
  // VarReadWriteAccess get access;
  // bool get isReadOnly => access == VarReadWriteAccess.readOnly; // isPushing == false
  // bool get isWriteOnly => access == VarReadWriteAccess.writeOnly;

  List<VarKey>? get dependents;

  /// View Widgets properties
  // value stringifier
  String stringify<V>(V value);
  // String stringify<V>(V? value);

  /// Tag properties
  // VarTag? get tag;
  String get label;
  String? get suffix;
  String? get tip;

  @override
  String toString() => '[$runtimeType<$value>]$label<${viewType.type}>';

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is VarKey && other.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

enum VarReadWriteAccess {
  readOnly,
  writeOnly,
  readWrite;

  bool get isWritable => this != readOnly;
  bool get isReadable => this != writeOnly;
}

extension VarMinMaxs on Iterable<VarKey> {
  Iterable<({num min, num max})?> get viewMinMaxs => map((e) => e.valueNumLimits);
  Iterable<num> get viewMaxs => viewMinMaxs.map((e) => e?.max).nonNulls;
  Iterable<num> get viewMins => viewMinMaxs.map((e) => e?.min).nonNulls;
  num get viewMax => viewMaxs.max;
  num get viewMin => viewMins.min;
}

/// [VarStatus]
// generalize as system status, 0 -> ok, -1 -> error
// does not implement Enum, as it can be a union of Enums
abstract mixin class VarStatus implements Exception {
  factory VarStatus.defaultOf(int code) => VarStatusDefault.values.elementAtOrNull(code) ?? VarStatusUnknown.unknown;

  // static const int defaultErrorCode = -1;

  int get code;
  String get message;
  Enum? get enumId; // null or meta default
  bool get isSuccess => code == 0;
  bool get isError => code != 0;
}

// abstract mixin class VarStatusError implements VarStatus {}

// mixin on enum to implement the Status interface
abstract mixin class VarEnumStatus implements VarStatus, Enum {
  int get code => index;
  String get message => name;
  Enum get enumId => this;
}

enum VarStatusDefault with VarStatus, VarEnumStatus { success, error }

enum VarStatusUnknown with VarStatus, VarEnumStatus {
  unknown;

  @override
  int get code => -1;
}

enum VarHandlerStatus with VarStatus, VarEnumStatus { unknownId, outOfRange }

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
