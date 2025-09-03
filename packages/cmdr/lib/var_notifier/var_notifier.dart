library var_notifier;

import 'dart:async';
import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' hide BitField;

import 'package:type_ext/basic_types.dart';
import 'package:binary_data/binary_data.dart';

import '../interfaces/service_io.dart';
import '../interfaces/binary_format.dart';

export 'package:binary_data/binary_data.dart';
export '../interfaces/service_io.dart';

part 'var_cache.dart';
part 'var_controller.dart';
part 'var_key.dart';
part 'var_value.dart';

///
///
/// each retrievable value as a View Model
// only default status ids need to be overridden
class VarNotifier<V> with ChangeNotifier, VarValue<V>, VarValueNotifier<V>, VarStatusNotifier implements ValueNotifier<V> {
  VarNotifier({required this.varKey, BinaryUnionCodec<V>? codec}) {
    this.codec = codec ?? varKey.buildViewer<V>() ?? BinaryUnionCodec<V>.of();
  }

  // withType
  @protected
  VarNotifier.ofKey(this.varKey) : assert(V != dynamic) {
    initReferences();
  }

  // derive type from [VarKey]
  factory VarNotifier.of(VarKey varKey) {
    assert(V == dynamic, 'V is determined by VarKey.viewType');
    return varKey.viewType(<G>() => VarNotifier<G>.ofKey(varKey) as VarNotifier<V>);
  }

  final VarKey varKey;
  late final int dataKey = varKey.value; // compute once and cache

  /// as outbound data depending on [dataKey]
  MapEntry<int, int> get dataEntry => MapEntry(dataKey, dataValue);
  (int key, int value) get dataPair => (dataKey, dataValue);

  // @override
  // void updateStatusByData(int status) {
  //   super.updateStatusByData(status);
  //   super.commitUserChanges();
  //   // isUpdatedByView = false;
  // }

  /// Derived from [VarKey] and cached
  /// reinit on VarKey update
  void initReferences() {
    // viewer = varKey.viewer as VarViewer<V>?;
    codec = varKey.buildViewer<V>() ?? BinaryUnionCodec<V>.of();
    // assert(varKey.buildViewer<V>() != null || V == int || V == bool, 'Unsupported type: $V');
  }

  void updateCodec(BinaryUnionCodec<V> newCodec) {
    codec = newCodec;
    // Recompute current values with new conversion
    if (_pendingValue == null) {
      notifyListeners(); // View may have changed due to new conversion
    }
  }

  /// [VarStatus] type is the same for all vars in most cases.
  /// Compile time const defined in [VarKey]. Does not need to build and cache.
  @override
  VarStatus statusOf(int statusCode) => varKey.varStatusOf(statusCode);

  ////////////////////////////////////////////////////////////////////////////////
  /// Stringify
  ////////////////////////////////////////////////////////////////////////////////
  String valueStringAs<T>() => varKey.stringify<T>(valueAs<T>());

  String get valueString => valueStringAs<V>();

  @override
  String toString() => '${describeIdentity(this)}(<$V>$value)($numView)';

  // ValueListenable<String> get toTextListenable => ValueNotifier<String>(valueString);

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  ({num min, num max})? get numLimits => codec.numLimits; // must be null for non-num types
  List<Enum>? get enumRange => codec.enumRange; // EnumSubtype.values must be non-null for Enum types
  List<BitField>? get bitsKeys => codec.bitsKeys;

  ////////////////////////////////////////////////////////////////////////////////
  /// Proxy with different view conversion
  // VarNotifier<R> proxyWith<R>({required BinaryUnionCodec<R> codec}) => VarProxyNotifier<R>(this, codec: codec);

  ////////////////////////////////////////////////////////////////////////////////
  /// Json
  ////////////////////////////////////////////////////////////////////////////////
  Map<String, Object?> toJson() {
    return {'varId': dataKey, 'varValue': numView, 'dataValue': dataValue, 'description': varKey.label};
  }

  /// init values from json config file, no new/allocation.
  /// caller may need to reinit references
  void loadFromJson(Map<String, Object?> json) {
    if (json case {'varId': int dataKey, 'varValue': num viewValue, 'dataValue': int _, 'description': String _}) {
      updateByFile(viewValue);

      assert(dataKey == this.dataKey, 'VarKey mismatch: $dataKey != ${this.dataKey}'); // handled by caller
      // viewValue bound should keep dataValue within format bounds after conversion
      // assert((varKey.binaryFormat?.max != null) ? (dataValue <= varKey.binaryFormat!.max) : true);
      // assert((varKey.binaryFormat?.min != null) ? (dataValue >= varKey.binaryFormat!.min) : true);
    }
  }

  // for set before loading num limits
  void updateByFile(num newValue) => numView = newValue;
}

/// [VarValueNotifier<V>]
/// A notifier combining a ValueNotifier with support for conversion between view types and data values.
/// It be can further combined with a status notifier.
abstract mixin class VarValueNotifier<V> implements VarValue<V>, ValueNotifier<V> {
  ////////////////////////////////////////////////////////////////////////////////
  /// runtime variables
  ////////////////////////////////////////////////////////////////////////////////
  bool get hasPendingChanges => _pendingValue != null;

  ////////////////////////////////////////////////////////////////////////////////
  /// Typed view [value]
  ////////////////////////////////////////////////////////////////////////////////
  @override
  V get value => view;
  @override
  set value(V newValue) {
    if (view == newValue) return;
    view = newValue;
    notifyListeners();
  }

  // by user for output
  void updateByView(V newValue) => value = newValue;

  V _getValue() => value;
  ValueGetter<V> get valueGetter => _getValue;
  ValueSetter<V> get valueSetter => updateByView;

  void updateByViewAs<T>(T typedValue) {
    updateValueAs<T>(typedValue);
    notifyListeners();
  }

  // also clear on updateByDataStatus
  void commitUserChanges() => commitView();

  // Call to discard user changes
  void discardUserChanges() {
    if (_pendingValue != null) {
      _pendingValue = null; // Value reverts to last update by server value
      notifyListeners();
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// [dataValue]
  ////////////////////////////////////////////////////////////////////////////////
  int get dataValue => data;

  // Inbound data from server/packets
  void updateByData(int bytesValue) {
    data = bytesValue; // Always update server value
    if (_pendingValue == null) notifyListeners(); // Only notify if effective value changed
  }

  // bool hasIndirectListeners = false;
  // bool get hasListenersCombined => hasListeners || hasIndirectListeners;

  // if separating host and server status
  // bool outOfRange; // value from client out of range
  // Enum valueStatus;

  // @override
  // V get value => valueAs<V>();
  // @override
  // set value(V newValue) => updateByViewAs<V>(newValue);

  // num _numValue = 0;
  // num get _viewValue => _numValue;
  // set _viewValue(num value) {
  //   if (_numValue == value) return;
  //   _numValue = value;
  //   notifyListeners();
  // }

  // int get dataValue => dataOf(_viewValue);
  // set _dataValue(int newValue) => _viewValue = viewOf(newValue);

  // performs common conversion on update
  // before sign extension
  // void updateByData(int bytesValue) {
  //   // _dataValue = dataOfBinary(bytesValue);
  //   _viewValue = viewOf(dataOfBinary(bytesValue));
  //   lastUpdate = VarLastUpdate.byData;
  //   // if (numValue != _clampedNumValue) statusCode = 1;
  // }
}

// replace null for over bounds
enum VarValueEnum { unknown }

/// alternatively seperate
// enum VarLastUpdate { clear, byData, byView }

// enum VarValueStatus {
//   outOfRange,
//   outOfRangeView,
//   outOfRangeData,
//   // add more as needed
// }

////////////////////////////////////////////////////////////////////////////////
/// [VarStatusNotifier]
/// implement as mixin
///   optionally mixin to share notifier
///   or compose for seperated value/status, multiple status
///     if status is only updated on value update
///   e.g.status from client side
///
/// alternatively, include code value only, caller handling Enum mapping
///
/// Does not mixin ValueNotifier<VarStatus> to not take up single inheritance
/// S does not have to be generic if all vars share the same status type
///
/// alternatively ValueNotifier<VarStatus>, let VarStatus handle union
////////////////////////////////////////////////////////////////////////////////
abstract mixin class VarStatusNotifier implements ChangeNotifier {
  int _statusCode = 0;
  int get statusCode => _statusCode;
  set statusCode(int value) {
    _statusCode = value;
    notifyListeners();
  }

  /// view typed
  // List<VarStatus> get statusCodes => VarStatusDefault.values;
  VarStatus statusOf(int statusCode) => VarStatus.defaultOf(statusCode);
  // R statusAsSubtype<R extends VarStatus>() => status;
  // R statusAsEnumSubtype<R extends Enum>() => statusAsEnum;

  VarStatus get status => statusOf(statusCode);
  set status(VarStatus newValue) => statusCode = newValue.code;

  Enum? get statusAsEnum => status.enumId;
  bool get statusIsError => statusCode != 0;
  bool get statusIsSuccess => statusCode == 0;

  void updateStatusByData(int status) => statusCode = status;
  void updateStatusByView(VarStatus status) => statusCode = status.code;

  R statusAs<R>() {
    return switch (R) {
          const (int) => statusCode,
          const (bool) => statusIsSuccess,
          const (Enum) => status.enumId ?? VarStatusUnknown.unknown,
          const (VarStatus) => status,
          // _ when TypeKey<R>().isSubtype<VarStatus>() => statusId, // statusOf must have been overridden for R
          // _ when TypeKey<R>().isSubtype<Enum>() => statusId.enumId,
          _ => throw UnsupportedError('statusAs: $R'),
        }
        as R;
  }

  void updateStatusByViewAs<T>(T status) {
    statusCode = switch (T) {
      const (int) => status as int,
      const (bool) => (status as bool) ? 1 : 0,
      const (Enum) => (status as Enum).index,
      const (VarStatus) => (status as VarStatus).code,
      _ when status is VarStatus => (status as VarStatus).code,
      _ when status is Enum => (status as Enum).index,
      _ => throw UnsupportedError('updateStatusByViewAs: $T'),
    };
  }
}

//////////////////////////////////////////////////////////////////////////////
// User submit
//   associated with UI component, instead of VarNotifier value
//   not triggerd by value changes
//   Listeners to the VarNotifier value on another UI component will not be notified of submit
//////////////////////////////////////////////////////////////////////////////
// class VarEventNotifier<V> extends VarNotifier<V> { over valueGetter for simplicity
class VarEventNotifier<V> extends ChangeNotifier {
  VarEventNotifier({required this.varNotifier, required this.onSubmitted});
  final VarNotifier<V> varNotifier; // typed by Key. returning as dynamic.
  final ValueSetter<VarNotifier<V>> onSubmitted;
  // final ValueSetter<VarNotifier<dynamic>> onSubmitted(VarCache);

  void submitByView(V varValue) {
    varNotifier.updateByView(varValue);
    onSubmitted(varNotifier);
    notifyListeners();
  }

  void submitByViewAs<T>(T varValue) {
    varNotifier.updateByViewAs<T>(varValue);
    onSubmitted(varNotifier);
    notifyListeners();
  }
}

/// same id updated codec
// class VarProxyNotifier<V> extends VarNotifier<V> {
//   VarProxyNotifier(this.source, {super.codec}) : super(varKey: source.varKey) {
//     source.addListener(_onSourceUpdate);
//   }

//   // VarProxyNotifier._of(this.source, super.proxyKey) : super.ofKey() {
//   //   source.addListener(_onSourceUpdate);
//   // }

//   // // factory VarProxyNotifier.of(VarNotifier source, VarKey varKey) {
//   // //   assert(V == dynamic, 'V is determined by VarKey.viewType');
//   // //   return varKey.viewType(<G>() => VarProxyNotifier<G>._of(source, varKey) as VarProxyNotifier<V>);
//   // // }

//   // factory VarProxyNotifier.of(VarNotifier source, BinaryUnionCodec<V> codec) {
//   //   assert(V == dynamic, 'V is determined by VarKey.viewType');
//   //   return varKey.viewType(<G>() => VarProxyNotifier<G>._of(source, varKey) as VarProxyNotifier<V>);
//   // }

//   final VarNotifier source;

//   // do not update to the source codec
//   @override
//   void initReferences() {
//     // super.initReferences();
//     // codec = codec ?? source.codec as BinaryUnionCodec<V>;
//     // codec = codec ?? source.codec;
//   }

//   void _onSourceUpdate() {
//     data = source.data; // sync by data value
//     notifyListeners(); // on dataValue change
//   }

//   // @override
//   // void addListener(VoidCallback listener) {
//   //   source.addListener(listener);
//   // }

//   // @override
//   // void removeListener(VoidCallback listener) {
//   //   source.removeListener(listener);
//   // }
// }
