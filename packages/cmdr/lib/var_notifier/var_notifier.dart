// ignore_for_file: public_member_api_docs, sort_constructors_first
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

///
///
/// each retrievable value as a View Model
// only default status ids need to be overridden
class VarNotifier<V> with ChangeNotifier, VarData<V>, VarValueNotifier<V>, VarStatusNotifier implements ValueNotifier<V> {
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

  ///
  late final int dataKey = varKey.value; // compute once and cache

  /// as outbound data depending on [dataKey]
  MapEntry<int, int> get dataEntry => MapEntry(dataKey, dataValue);
  (int key, int value) get dataPair => (dataKey, dataValue);

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

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  ({num min, num max})? get numLimits => codec.numLimits; // must be null for non-num types
  List<Enum>? get enumRange => codec.enumRange; // EnumSubtype.values must be non-null for Enum types
  List<BitField>? get bitsKeys => codec.bitsKeys;

  // @override
  // void updateStatusByData(int status) {
  //   super.updateStatusByData(status);
  //    super.commitUserChanges();
  //   isUpdatedByView = false;
  // }

  ////////////////////////////////////////////////////////////////////////////////
  /// Proxy with different view conversion
  VarNotifier<R> proxyWith<R>({required BinaryUnionCodec<R> codec}) => VarProxyNotifier<R>(this, codec: codec);

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

/// [VarData<V>]/[VarViewer]
/// UnionCodec + InplaceValue + sync pending buffer
/// handle conversions
/// handling syncing 2 variable representations
mixin class VarData<V> {
  /// Config
  /// caching results from VarKey for performance. does not have to be immutable.
  /// additionally all mutability is contained in a single layer. cache preallocate can be immutable
  /// by default get from varKey. resolve in constructor to cached values derived from varKey
  ///
  /// Handle Return as the exact type, to account for user defined method on that type
  /// codec handles sign extension
  BinaryUnionCodec<V> codec = BinaryUnionCodec<V>.of();

  V viewOf(int data) => codec.decode(data);
  int dataOf(V view) => codec.encode(view);

  /// runtime
  /// Handle syncing server data and local view
  /// `ReadOnly Mode` may directly access serverData. _pendingValue is never updated;
  int serverData = 0; // Source of truth from server // Base storage as server's native type
  V? _pendingValue; // User changes (null = synchronized),   // effectively LastUpdateFlag

  /// [view] the value seen by the user
  V get view => _pendingValue ?? viewOf(serverData); // Single source of truth: pending takes precedence

  /// update view without outputting to server
  set view(V newValue) {
    // _pendingValue = newValue; // let codec handle clamping on [encode], view may be out of bounds
    _pendingValue = switch (V) {
      const (int) => codec.clamp(newValue as int) as V,
      const (double) => codec.clamp(newValue as double) as V,
      const (num) => codec.clamp(newValue as num) as V,
      const (bool) => newValue,
      _ => newValue,
    };
  }

  // void updateView(V newValue) => _pendingValue = newValue;
  // void submitView(V newValue) => serverData = dataOf(newValue);

  /// additional way to clear pending on Status response
  /// restore [get view] to [serverData]
  void commitView() {
    if (_pendingValue case V newValue) {
      serverData = dataOf(newValue); // update in case of write only, no server polling updates
      _pendingValue = null; // allow further [data] updates to determine [view]
      // No notification needed - effective value doesn't change
    }
  }

  /// [data] from packet. convert on transmit only. lazy update on updateByView
  /// Always accept client data.
  /// value over view boundaries handle by [view]
  int get data => (_pendingValue != null) ? dataOf(_pendingValue as V) : serverData;
  // alternatively call commitView() on submit
  // int get data => serverData;

  set data(int newValue) {
    serverData = newValue; // codec handle sign extension
    if (_pendingValue == null) return;
    if (_pendingValue == viewOf(newValue)) _pendingValue = null; // only if user value matches server value, clear pending.
  }

  /// todo move to codec unioinValue
  /// [numView] The num view representation of the [view] value as a num.
  //  BinaryNumCodec<num> numCodec = BinaryNumCodec<num>.of(); optionally include as default num codec

  // /   since it is the base for all generic types that can be converted to and from,
  // /     [valueAs<R>()] can always return a value without throwing; the closest representation possible.
  // /   primitive/register sized only for now
  // /   consistent DataOfView interface
  // /   multiple view on the same value will require conversion anyway
  // /   using view side num as notifier,
  // /   notify view side listener on all updates, not all changes are pushed to client

  num get numView {
    return switch (V) {
      const (int) || const (double) || const (num) => view as num,
      const (bool) => (view as bool) ? 1 : 0,
      _ => data,
    };
  }

  // set pending first
  set numView(num newValue) {
    view = switch (V) {
      const (int) => newValue.toInt() as V,
      const (double) => newValue.toDouble() as V,
      const (num) => newValue as V,
      const (bool) => (newValue != 0) as V,
      _ => viewOf(newValue.toInt()), // decode to view type
    };
  }

  /// assert(V is num);
  double get normalized => (numView / codec.numLimits!.max).clamp(-1.0, 1.0);
  double get percent => normalized * 100;

  /// [valueAs<V>] Generic parameter / union handling
  /// UnionCodec
  /// widgets optionally select
  num get valueAsNum => numView;
  int get valueAsInt => (numView).toInt();
  double get valueAsDouble => (numView).toDouble();
  bool get valueAsBool => (numView != 0);
  Enum get valueAsEnum => codec?.enumOf(numView as int) ?? VarValueEnum.unknown;
  BitStruct get valueAsBitFields => codec?.bitsOf(numView as int) ?? BitStruct.view([], valueAsInt as Bits);
  String get valueAsString => String.fromCharCodes(valueAsBytes);
  Uint8List get valueAsBytes => Uint8List(8)..buffer.asByteData().setUint64(0, numView as int, Endian.little);

  // set valueAsBool(bool newValue) => (numValue = newValue ? 1 : 0);
  // set valueAsNum(num newValue) {
  //   // assert(V == int || V == double, 'Only num types are supported');
  //   if (viewer.numLimits != null) {
  //     value = newValue.clamp(viewer.numLimits!.min, viewer.numLimits!.max) as V;
  //   }
  // }
  // set valueAsEnum(Enum newValue) => _numValue = newValue.index;
  // set valueAsEnum(Enum newValue) {
  //   if (viewer.enumRange != null) {
  //     if (viewer.enumRange![newValue.index] == newValue) value = newValue as V;
  //   }
  // }
  // set valueAsBitFields(BitStruct newValue) => _numValue = newValue.bits;

  ///
  /// caller determines type after accounting for VarKey
  /// generic getter use switch on type literal, and require extension to account for subtypes
  R valueAs<R>() {
    if (R == V) return view as R;
    // codec.decodeAs<R>( numValue.toInt());
    return switch (R) {
          const (int) => valueAsInt,
          const (double) => valueAsDouble,
          const (num) => valueAsNum,
          const (bool) => valueAsBool,
          // match by type literal cannot be subtype
          const (Enum) => valueAsEnum,
          const (BitStruct) => valueAsBitFields,
          const (String) => valueAsString,
          _ => throw UnsupportedError('Unsupported type: $R'),
        }
        as R;
  }

  /// update
  static num numValueOf<T>(T typedValue) {
    return switch (T) {
      const (int) => typedValue as int,
      const (double) => typedValue as double,
      const (num) => typedValue as num,
      const (bool) => (typedValue as bool) ? 1 : 0,
      const (Enum) => (typedValue as Enum).index,
      const (BitStruct) => (typedValue as BitStruct).bits,
      _ => throw UnsupportedError('Unsupported type: $T'),
    };
  }

  // input bounds checked only to ensure a valid value is sent to client side
  // switch on value will also handle dynamic
  /// generic setter can optionally switch on object type
  void updateValueAs<T>(T typedValue) {
    if (T == V) {
      view = typedValue as V;
    } else {
      numView = numValueOf<T>(typedValue);
      // view = decode(numValueOf<T>(typedValue).toInt()),
    }
  }

  // void updateValueAs<T>(T typedValue) {
  //   numValue = switch (T) {
  //     _ when T == V => typedValue as num,
  //     const (double) || const (int) || const (num) => (typedValue as num),
  //     const (bool) => (typedValue as bool) ? 1 : 0,
  //     const (Enum) => (typedValue as Enum).index,
  //     const (BitStruct) => (typedValue as BitStruct).bits,
  //     _ => throw UnsupportedError('Unsupported type: $T'),
  //   };

  //   lastUpdate = VarLastUpdate.byView;
  //   if (typedValue case num input when input != numValue) statusCode = 1;
  // }
}

/// [VarValueNotifier<V>]
/// A notifier combining a ValueNotifier with support for conversion between view types and data values.
/// It be can further combined with a status notifier.
abstract mixin class VarValueNotifier<V> implements VarData<V>, ValueNotifier<V> {
  ////////////////////////////////////////////////////////////////////////////////
  /// runtime variables
  ////////////////////////////////////////////////////////////////////////////////
  bool get hasPendingChanges => _pendingValue != null;

  // bool hasIndirectListeners = false;
  // bool get hasListenersCombined => hasListeners || hasIndirectListeners;

  // if separating host and server status
  // bool outOfRange; // value from client out of range
  // Enum valueStatus;

  ////////////////////////////////////////////////////////////////////////////////
  /// Typed [value]
  /// typed view value
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
  void updateByView(V newValue) {
    value = newValue;
  }

  void submitByView(V newValue) {
    value = newValue;
    commitView();
  }

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

  ////////////////////////////////////////////////////////////////////////////////
  /// [dataValue]
  ////////////////////////////////////////////////////////////////////////////////
  int get dataValue => data;

  // Inbound data from server/packets
  void updateByData(int bytesValue) {
    data = bytesValue; // Always update server value
    if (_pendingValue == null) notifyListeners(); // Only notify if effective value changed
  }

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
class VarProxyNotifier<V> extends VarNotifier<V> {
  VarProxyNotifier(this.source, {super.codec}) : super(varKey: source.varKey) {
    source.addListener(_onSourceUpdate);
  }

  // VarProxyNotifier._of(this.source, super.proxyKey) : super.ofKey() {
  //   source.addListener(_onSourceUpdate);
  // }

  // // factory VarProxyNotifier.of(VarNotifier source, VarKey varKey) {
  // //   assert(V == dynamic, 'V is determined by VarKey.viewType');
  // //   return varKey.viewType(<G>() => VarProxyNotifier<G>._of(source, varKey) as VarProxyNotifier<V>);
  // // }

  // factory VarProxyNotifier.of(VarNotifier source, BinaryUnionCodec<V> codec) {
  //   assert(V == dynamic, 'V is determined by VarKey.viewType');
  //   return varKey.viewType(<G>() => VarProxyNotifier<G>._of(source, varKey) as VarProxyNotifier<V>);
  // }

  final VarNotifier source;

  // do not update to the source codec
  @override
  void initReferences() {
    // super.initReferences();
    // codec = codec ?? source.codec as BinaryUnionCodec<V>;
    // codec = codec ?? source.codec;
  }

  void _onSourceUpdate() {
    data = source.data; // sync by data value
    notifyListeners(); // on dataValue change
  }

  // @override
  // void addListener(VoidCallback listener) {
  //   source.addListener(listener);
  // }

  // @override
  // void removeListener(VoidCallback listener) {
  //   source.removeListener(listener);
  // }
}
