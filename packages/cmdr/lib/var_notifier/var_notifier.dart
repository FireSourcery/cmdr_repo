library var_notifier;

import 'dart:async';
import 'package:async/async.dart';
import 'package:binary_data/binary_format/binary_codec.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' hide BitField;
import 'package:recase/recase.dart';

import 'package:binary_data/data/basic_types.dart';
import 'package:binary_data/binary_data.dart';
import 'package:binary_data/binary_format/binary_codec.dart';

import '../interfaces/num_union.dart';
import '../interfaces/service_io.dart';

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
  VarNotifier({required this.varKey, BinaryCodec<V>? codec}) {
    this.codec = codec ?? varKey.buildViewer();
  }

  // withType
  VarNotifier.ofKey(this.varKey) {
    initReferences();
  }

  // derive type from [VarKey]
  factory VarNotifier.of(VarKey<V> varKey) {
    // if (V == dynamic) {
    // return varKey.viewType(<G>() => VarNotifier<G>.ofKey(varKey as VarKey<G>) as VarNotifier<V>);
    //allow dynamic key to create typed notifier need varKey be cast matching
    // } else {
    return VarNotifier<V>.ofKey(varKey);
    // }
  }

  final VarKey<V> varKey;
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
    codec = varKey.buildViewer()!;
    unionCodec = varKey.buildUnionViewer();
    // assert(varKey.buildViewer<V>() != null || V == int || V == bool, 'Unsupported type: $V');
  }

  // void updateCodec(BinaryCodec<V> newCodec) {
  //   codec = newCodec;
  //   // Recompute current values with new conversion
  //   if (_viewValue == null) {
  //     notifyListeners(); // View may have changed due to new conversion
  //   }
  // }

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
  ({num min, num max})? get numLimits => unionCodec?.numLimits; // must be null for non-num types
  List<Enum>? get enumRange => unionCodec?.enumRange; // EnumSubtype.values must be non-null for Enum types
  List<BitField>? get bitsKeys => unionCodec?.bitsKeys;

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

extension VarNotifiers on Iterable<VarNotifier> {
  Iterable<(String, num)> get namedValues => map((e) => (e.varKey.label, e.valueAsNum));
  Iterable<(VarKey, VarNotifier)> get keyed => map((e) => (e.varKey, e));

  Iterable<String> toNamedValueStrings([String divider = ': ', int precision = 2]) {
    return namedValues.map((e) => '${e.$1}$divider${e.$2.toStringAsFixed(precision)}');
  }
}

/// [VarValueNotifier<V>]
/// A notifier combining a ValueNotifier with support for conversion between view types and data values.
///   - Implements [ValueNotifier]
///   - Unit conversion between view and data values
///   - Sync local and remote values, with pending change tracking
/// It be can further combined with a status notifier.
abstract mixin class VarValueNotifier<V> implements VarValue<V>, ValueNotifier<V> {
  ////////////////////////////////////////////////////////////////////////////////
  /// runtime variables
  ////////////////////////////////////////////////////////////////////////////////
  bool get hasPendingChanges => _viewValue != null;

  ////////////////////////////////////////////////////////////////////////////////
  /// Typed view [value] as view side
  ////////////////////////////////////////////////////////////////////////////////
  @override
  V get value => view;
  @override
  set value(V newValue) {
    if (view == newValue) return;
    view = newValue;
    notifyListeners();
  }

  // V get viewValue => view;

  // by user for output
  void updateByView(V newValue) => value = newValue;

  // also clear on updateByDataStatus
  void commitUserChanges() => commitView();

  // Call to discard user changes
  void discardUserChanges() {
    if (_viewValue != null) {
      _viewValue = null; // Value reverts to last update by server value
      notifyListeners();
    }
  }

  void updateByViewAs<T>(T typedValue) {
    updateValueAs<T>(typedValue);
    notifyListeners();
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// [dataValue]
  // Inbound data from server/packets
  ////////////////////////////////////////////////////////////////////////////////
  int get dataValue => data;

  void updateByData(int bytesValue) {
    data = bytesValue; // Always update server value
    if (_viewValue == null) notifyListeners(); // Only notify if effective value changed
  }

  // if separating host and server status
  // bool outOfRange; // value from client out of range
  // Enum syncStatus;
}

/// convenience short hand
extension VarValueNotifierExtensions<V> on VarValueNotifier<V> {
  V _getValue() => value;
  void _setValue(V newValue) => value = newValue;
  ValueGetter<V> get valueGetter => _getValue;
  ValueSetter<V> get valueSetter => _setValue;

  // with known case
  // V1 _getValue<V1>() => value as V1;
  // void _setValue<V1>(V1 newValue) => value = newValue as V;
  // ValueGetter<V> get valueGetter => _getValue;
  // ValueSetter<V> get valueSetter => _setValue;
}

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
//   not triggered by value changes
//   Listeners to the VarNotifier value on another UI component will not be notified of submit
//////////////////////////////////////////////////////////////////////////////
// class VarEventNotifier<V> extends VarNotifier<V> { over valueGetter for simplicity
class VarEventNotifier<V> extends ChangeNotifier {
  VarEventNotifier({required this.varNotifier, required this.onSubmit});
  final VarNotifier<V> varNotifier; // typed by Key. returning as dynamic.
  final ValueSetter<VarNotifier<V>> onSubmit; // handle additional logic on submit
  // final ValueSetter<VarCache > onSubmit (VarCache);

  void submitByView(V varValue) {
    varNotifier.updateByView(varValue);
    onSubmit(varNotifier);
    notifyListeners();
  }

  void submitByViewAs<T>(T varValue) {
    varNotifier.updateByViewAs<T>(varValue);
    onSubmit(varNotifier);
    notifyListeners();
  }

  void call(Function(VarNotifier<V>) submitAction) {
    submitAction(varNotifier);
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
