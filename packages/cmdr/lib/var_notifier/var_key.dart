part of 'var_notifier.dart';

/// [VarKey] is an immutable key for [VarNotifier].
/// immutable properties of a VarNotifier
/// == and hash from ValueKey
@immutable
abstract mixin class VarKey implements ValueKey<int> {
  // abstract mixin class VarKey<V> implements ValueKey<int> {
  // TypeKey<V> get viewType;
  const VarKey();

  @override
  int get value; // int id of the key, NOT the value of associated Var
  int get id => value;

  // the varNotifier type parameter
  TypeKey<dynamic> get viewType; // binaryFormat!.viewType; // override if binaryFormat is null
  // BinaryFormat? get binaryFormat; // can depreciate

  // VarViewer<dynamic>? get viewer; // null for int

  /// Data numeric conversion
  BinaryUnionCodec<R>? buildViewer<R>(); // null for int

  // optionally override with subtype
  VarStatus varStatusOf(int code); // should only be one. instances shared

  /// Service properties
  // should not be both, that would be real-time loopback
  bool get isPolling; // polling, all readable. Processed by read stream
  bool get isPushing; // pushing, selected writable, other writable updated on change, processed by write stream

  bool get isReadOnly; // isPushing == false
  bool get isWriteOnly;
  // VarReadWriteAccess get access;

  List<VarKey>? get dependents;

  /// Text View Widgets properties
  // value stringifier
  String stringify<V>(V value);
  // String stringify<V>(V? value);

  int? get valueStringDigits;

  String get label;
  String? get suffix;
  String? get tip;
  // VarTag? get tag;

  @override
  String toString() => '[$runtimeType<$value>]$label<${viewType.type}>';

  // strictly by id. subtype casting not considered
  @override
  bool operator ==(covariant VarKey other) => other.value == value;

  @override
  int get hashCode => Object.hash(value, value);
}

enum VarReadWriteAccess {
  disabled,
  readOnly,
  writeOnly,
  readWrite;

  factory VarReadWriteAccess.from(bool isReadable, bool isWritable) {
    return switch ((isReadable, isWritable)) {
      (false, true) => VarReadWriteAccess.writeOnly,
      (true, false) => VarReadWriteAccess.readOnly,
      (true, true) => VarReadWriteAccess.readWrite,
      (false, false) => VarReadWriteAccess.disabled,
    };
  }

  bool get isWritable => this != readOnly;
  bool get isReadable => this != writeOnly;

  bool get isReadOnly => this == readOnly;
  bool get isWriteOnly => this == writeOnly;
}

/// [VarStatus]
// does not implement Enum, as it can be a union of Enums
abstract mixin class VarStatus {
  const VarStatus();
  factory VarStatus.defaultOf(int code) = _VarStatus;

  int get code;
  String get message;
  Enum? get enumId; // null or meta default
  bool get isSuccess;
  bool get isError;
}

class _VarStatus extends VarStatus {
  const _VarStatus(this.code);

  @override
  final int code;

  @override
  Enum? get enumId => VarStatusDefault.values.elementAtOrNull(code) ?? VarStatusUnknown.unknown;
  @override
  bool get isError => code != 0;
  @override
  bool get isSuccess => code == 0;
  @override
  String get message => enumId?.name ?? 'VarStatus: $code';
}

// mixin on enum to implement the Status interface
abstract mixin class VarEnumStatus implements VarStatus, Enum {
  int get code => index;
  String get message => name;
  Enum get enumId => this;
}

// generalize as system status, 0 -> ok, -1 -> error
enum VarStatusDefault with VarStatus, VarEnumStatus {
  success,
  error;

  @override
  bool get isSuccess => code == 0;
  @override
  bool get isError => code != 0;
}

// enum VarStatusOkDefault with VarStatusOk, VarEnumStatus { ok }
// enum VarStatusErrorDefault with VarStatusError, VarEnumStatus { error, unknown }
enum VarStatusUnknown with VarStatus, VarEnumStatus {
  unknown;

  @override
  int get code => -1;

  @override
  bool get isError => true;

  @override
  bool get isSuccess => false;
}

// enum VarHandlerStatus with VarStatus, VarEnumStatus { unknownId, outOfRange, noResponse, 
//   @override
//   int get code => -1; }

// extension VarMinMaxs on Iterable<VarKey> {
//   Iterable<({num min, num max})?> get viewMinMaxs => map((e) => e.viewer?.numLimits);
//   Iterable<num> get viewMaxs => viewMinMaxs.map((e) => e?.max).nonNulls;
//   Iterable<num> get viewMins => viewMinMaxs.map((e) => e?.min).nonNulls;
//   num get viewMax => viewMaxs.max;
//   num get viewMin => viewMins.min;
// }