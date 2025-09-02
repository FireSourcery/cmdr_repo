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

  // VarViewer<dynamic>? get viewer; // null for int

  BinaryUnionCodec<R>? buildViewer<R>(); // null for int

  // remove
  /// Data numeric conversion
  // int Function(int binary)? get signExtension;
  // ViewOfData? get viewOfData;
  // DataOfView? get dataOfView;

  // /// Union type properties.
  // ({num min, num max})? get valueNumLimits;
  // List<Enum>? get valueEnumRange;
  // List<BitField>? get valueBitsKeys;
  // T subtypeOf<T>(num value) => throw UnsupportedError('valueAsSubtype: $T');
  // num valueOfSubtype<T>(T value) => throw UnsupportedError('viewOfSubtype: $T');
  // // num? get valueDefault;
  ///

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

  factory VarReadWriteAccess.of(bool isReadOnly, bool isWriteOnly) {
    return switch ((isReadOnly, isWriteOnly)) {
      (true, false) => VarReadWriteAccess.readOnly,
      (false, true) => VarReadWriteAccess.writeOnly,
      (false, false) => VarReadWriteAccess.readWrite,
      (true, true) => throw RangeError('Invalid read/write access'),
    };
  }

  factory VarReadWriteAccess.from(bool isReadable, bool isWritable) {
    return switch ((isReadable, isWritable)) {
      (false, true) => VarReadWriteAccess.writeOnly,
      (true, false) => VarReadWriteAccess.readOnly,
      (true, true) => VarReadWriteAccess.readWrite,
      (false, false) => throw RangeError('Invalid read/write access'),
    };
  }

  bool get isWritable => this != readOnly;
  bool get isReadable => this != writeOnly;
  bool get isReadOnly => this == readOnly;
  bool get isWriteOnly => this == writeOnly;
}

// extension VarMinMaxs on Iterable<VarKey> {
//   Iterable<({num min, num max})?> get viewMinMaxs => map((e) => e.viewer?.numLimits);
//   Iterable<num> get viewMaxs => viewMinMaxs.map((e) => e?.max).nonNulls;
//   Iterable<num> get viewMins => viewMinMaxs.map((e) => e?.min).nonNulls;
//   num get viewMax => viewMaxs.max;
//   num get viewMin => viewMins.min;
// }

/// [VarStatus]
// generalize as system status, 0 -> ok, -1 -> error
// does not implement Enum, as it can be a union of Enums
abstract mixin class VarStatus {
  factory VarStatus.defaultOf(int code) => VarStatusDefault.values.elementAtOrNull(code) ?? VarStatusUnknown.unknown;

  // static const int defaultErrorCode = -1;

  int get code;
  String get message;
  Enum? get enumId; // null or meta default
  bool get isSuccess => code == 0;
  bool get isError => code != 0;

  //   R statusAs<R>() {
  //   return switch (R) {
  //         const (int) => statusCode,
  //         const (bool) => statusIsSuccess,
  //         const (Enum) => status.enumId ?? VarStatusUnknown.unknown,
  //         const (VarStatus) => status,
  //         // _ when TypeKey<R>().isSubtype<VarStatus>() => statusId, // statusOf must have been overridden for R
  //         // _ when TypeKey<R>().isSubtype<Enum>() => statusId.enumId,
  //         _ => throw UnsupportedError('statusAs: $R'),
  //       }
  //       as R;
  // }

  // void updateStatusAs<T>(T status) {
  //   statusCode = switch (T) {
  //     const (int) => status as int,
  //     const (bool) => (status as bool) ? 1 : 0,
  //     const (Enum) => (status as Enum).index,
  //     const (VarStatus) => (status as VarStatus).code,
  //     _ when status is VarStatus => (status as VarStatus).code,
  //     _ when status is Enum => (status as Enum).index,
  //     _ => throw UnsupportedError('updateStatusByViewAs: $T'),
  //   };
  // }
}

abstract mixin class VarStatusOk implements VarStatus, ValueResult<void> {}

abstract mixin class VarStatusError implements VarStatus, ErrorResult, Exception {}
// enum VarStatusOkDefault with VarStatusOk, VarEnumStatus { ok }
// enum VarStatusErrorDefault with VarStatusError, VarEnumStatus { error, unknown }

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

enum VarHandlerStatus with VarStatus, VarEnumStatus { unknownId, outOfRange, noResponse }
