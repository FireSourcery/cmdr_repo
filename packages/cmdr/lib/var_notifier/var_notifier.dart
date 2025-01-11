library var_notifier;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' hide BitField;
import 'package:meta/meta.dart';
import 'package:quiver/cache.dart';
import 'package:type_ext/basic_ext.dart';

import 'package:type_ext/basic_types.dart';
import 'package:type_ext/service_io.dart';
import 'package:binary_data/binary_data.dart';

export 'package:type_ext/basic_types.dart';
export 'package:type_ext/service_io.dart';
export 'package:binary_data/binary_data.dart';

part 'var_cache.dart';
part 'var_key.dart';
part 'var_controller.dart';

// only default status ids need to be overridden
class VarNotifier<V> with ChangeNotifier, VarValueNotifier<V>, VarStatusNotifier {
  VarNotifier({
    required this.varKey,
    int Function(int binary)? signExtension,
    ViewOfData? viewOfData,
    DataOfView? dataOfView,
    ({num min, num max})? numLimits,
    List<Enum>? enumRange,
    List<BitField>? bitsKeys,
  }) {
    this.signExtension = signExtension;
    this.viewOfData = viewOfData;
    this.dataOfView = dataOfView;
    this.numLimits = numLimits;
    this.enumRange = enumRange;
    this.bitsKeys = bitsKeys;
  }

  VarNotifier.ofKey(this.varKey) : assert(V != dynamic) {
    initReferences();
  }

  factory VarNotifier.of(VarKey varKey) {
    assert(V == dynamic, 'V must be dynamic');
    return varKey.viewType(<G>() => VarNotifier<G>.ofKey(varKey) as VarNotifier<V>);
  }

  final VarKey varKey;

  @override
  late final int dataKey = varKey.value; // compute once and cache

  /// Derived from [VarKey] and cached
  void initReferences() {
    signExtension = varKey.binaryFormat?.signExtension;
    viewOfData = varKey.viewOfData;
    dataOfView = varKey.dataOfView;
    numLimits = varKey.valueNumLimits;
    enumRange = varKey.valueEnumRange;
    bitsKeys = varKey.valueBitsKeys;
  }

  /// [VarStatus] type is the same for all vars in most cases.
  /// Compile time const defined in [VarKey]. Does not need to build and cache.
  @override
  VarStatus statusOf(int statusCode) => varKey.varStatusOf(statusCode);

  ////////////////////////////////////////////////////////////////////////////////
  /// Stringify
  ////////////////////////////////////////////////////////////////////////////////
  String get valueString => valueStringAs<V>();

  // stringifyAs
  String valueStringAs<T>() => varKey.stringify<T>(valueAs<T>());

  @override
  T subtypeOf<T>(num value) => varKey.subtypeOf<T>(value);
  @override
  num valueOfSubtype<T>(T value) => varKey.valueOfSubtype<T>(value);

  ////////////////////////////////////////////////////////////////////////////////
  @override
  String toString() => '${describeIdentity(this)}(`${varKey.label}`)($value = $_viewValue)';

  // @override
  // void updateStatusByData(int status) {
  //   super.updateStatusByData(status);
  //   isUpdatedByView = false;
  // }
}

///
/// A notifier combining a ValueNotifier with support for conversion between view types and data values.
/// It be can further combined with a status notifier.
abstract mixin class VarValueNotifier<V> implements ValueNotifier<V> {
  // int get dataMin;
  // int get dataMax;

  /// caching results for performance. these do not have to be immutable.
  /// values are already nullable
  /// additionally all mutability is contained in a single layer. cache preallocate can be immutable
  /// by default get from varKey. resolve in constructor to cached values derived from varKey
  int get dataKey;
  int Function(int binary)? signExtension;
  ViewOfData? viewOfData; // num conversion only, null for Enum and Bits
  DataOfView? dataOfView;
  ({num min, num max})? numLimits; //  view base limits, still effective for non-num V, if set
  List<Enum>? enumRange; // for enum conversion only. other range bound types, e.g String, provide by enum.
  List<BitField>? bitsKeys; // for bits conversion only.

  @override
  String toString() => '${describeIdentity(this)}($value)';

  ///
  int dataOfBinary(int binary) => signExtension?.call(binary) ?? binary;
  num viewOf(int data) => viewOfData?.call(data) ?? data; // 'view base'
  int dataOf(num view) => dataOfView?.call(view) ?? view.toInt();

  num clamp(num value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) : value;

  Enum enumOf(int value) => enumRange?.elementAtOrNull(value) ?? VarValueEnum.unknown;
  BitStruct bitFieldsOf(int value) => BitConstruct<BitStruct, BitField>(bitsKeys ?? const <BitField>[], value as Bits);

  ////////////////////////////////////////////////////////////////////////////////
  /// User defined subtypes
  /// Returns the as the exact type, to account for user defined method on that type
  T subtypeOf<T>(num value) => throw UnsupportedError('valueAsSubtype: $T');
  num valueOfSubtype<T>(T value) => throw UnsupportedError('viewOfSubtype: $T');

  ////////////////////////////////////////////////////////////////////////////////
  /// runtime variables
  ////////////////////////////////////////////////////////////////////////////////
  VarLastUpdate lastUpdate = VarLastUpdate.clear;

  // clear on response
  // bool isUpdatedByView = false; // isPushPending, isLastUpdateByView
  // void push() => isUpdatedByView = true;
  // void clearPush() => isUpdatedByView = false;

  // cleared by user
  // bool _isPollingMarked = false;
  // bool get isPollingMarked => (_isPollingMarked || hasListeners); // && !isPushPending;
  // set isPollingMarked(bool value) => _isPollingMarked = value;

  // bool isPollComplete = true;
  // void pull() => _isPollingMarked = true;

  bool hasIndirectListeners = false;
  bool get hasListenersCombined => hasListeners || hasIndirectListeners;

  // if separating internal and external status
  // bool outOfRange; // value from client out of range

  /// superclass implementation
  @override
  V get value => valueAs<V>();
  @override
  set value(V newValue) => updateByViewAs<V>(newValue);

  ////////////////////////////////////////////////////////////////////////////////
  /// [_viewValue] The base representation of the value as a num. "view side base"
  ///   since it is the base for all generic types that can be converted to and from,
  ///     [valueAs<R>()] can always return a value without throwing; the closest representation possible.
  ///   primitive/register sized only for now
  ///   consistent DataOfView interface
  ///   multiple view on the same value will require conversion anyway
  ///   using view side num as notifier,
  ///   notify view side listener on all updates, not all changes are pushed to client
  ////////////////////////////////////////////////////////////////////////////////
  num _numValue = 0;
  num get _viewValue => _numValue;
  set _viewValue(num value) {
    if (_numValue == value) return;
    _numValue = value;
    notifyListeners();
  }

  // without checking for change
  // void clearNumValue() {
  //   _numValue = 0;
  //   notifyListeners();
  // }

  ////////////////////////////////////////////////////////////////////////////////
  /// [dataValue] from packet. convert on transmit only. lazy update on updateByView
  ////////////////////////////////////////////////////////////////////////////////
  int get dataValue => dataOf(_viewValue);
  // set dataValue(int value) => numValue = viewOf(dataValue);

  // Always accept client data. correction is handled at client side.
  // value over view boundaries handle by UI

  // after sign extension
  // alternatively alway notify on data update
  void _updateByData(int dataValue) => _viewValue = viewOf(dataValue);
  // if (numValue != _clampedNumValue) {
  //   statusCode = 1;
  // }

  // before sign extension
  // updatedByView wait for push
  void updateByData(int bytesValue) {
    _updateByData(dataOfBinary(bytesValue));
    lastUpdate = VarLastUpdate.byData;
  }

  /// as outbound data
  MapEntry<int, int> get dataEntry => MapEntry(dataKey, dataValue);
  (int key, int value) get dataPair => (dataKey, dataValue);

  ////////////////////////////////////////////////////////////////////////////////
  /// [viewValue] from widgets
  /// The value in real world units and constraints. as seen by the user
  ////////////////////////////////////////////////////////////////////////////////
  /// typed view value
  // V get viewValue => valueAs<V>();
  // set viewValue(V newValue) => updateByViewAs<V>(newValue);

  @protected
  num get valueAsNum => _viewValue;
  @protected
  int get valueAsInt => (_viewValue).toInt();
  @protected
  double get valueAsDouble => (_viewValue).toDouble();
  @protected
  bool get valueAsBool => (_viewValue != 0);
  @protected
  Enum get valueAsEnum => enumOf(valueAsInt);
  @protected
  BitStruct get valueAsBitFields => bitFieldsOf(valueAsInt);
  @protected
  Uint8List get valueAsBytes => Uint8List(8)..buffer.asByteData().setUint64(0, valueAsInt, Endian.big);
  @protected
  String get valueAsString => String.fromCharCodes(valueAsBytes);

  /// generic getter use switch on type literal, and require extension to account for subtypes
  /// generic setter can optionally switch on object type

  /// view determines type after accounting fo varId.valueType
  R valueAs<R>() {
    return switch (R) {
      const (int) => valueAsInt,
      const (double) => valueAsDouble,
      const (num) => valueAsNum,
      const (bool) => valueAsBool,
      const (Enum) => valueAsEnum,
      const (BitsBase) => valueAsBitFields,
      const (BitStruct) => valueAsBitFields,
      const (String) => valueAsString,
      _ => subtypeOf<R>(_viewValue),
    } as R;
  }

  // todo update as Enum subtype check first, in case a value other than enum.index is selected
  // @protected
  // set valueAsEnum(Enum newValue) => numValue = newValue.index;
  // @protected
  // set valueAsBitsMap(BitsBase newValue) => numValue = newValue.bits;
  // void updateAsDynamic(dynamic typedValue) {
  //   numValue = switch (typedValue) {
  //     num value => clamp(value),
  //     bool value => (value) ? 1 : 0,
  //     Enum value => value.index,
  //     BitsBase value => value.bits,
  //     _ => throw UnsupportedError(' '),
  //   };
  // }

  // caller handle display state of over boundary.
  // input bounds checked only to ensure a valid value is sent to client side
  // switch on value will also handle dynamic
  void updateByViewAs<T>(T typedValue, [bool push = false]) {
    _viewValue = switch (T) {
      const (double) || const (int) || const (num) => clamp(typedValue as num),
      const (bool) => (typedValue as bool) ? 1 : 0,
      const (Enum) => (typedValue as Enum).index,
      const (BitsBase) => (typedValue as BitsBase).bits,
      _ => valueOfSubtype<T>(typedValue),
      // _ when typedValue is Enum => (typedValue as Enum).index,
      // _ when typedValue is BitsBase => (typedValue as BitsBase).bits,
      // const (dynamic) => switch (typedValue) {
      //     num value => clamp(value),
      //     bool value => (value) ? 1 : 0,
      //     Enum value => value.index,
      //     BitsBase value => value.bits,
      //     _ => throw UnsupportedError(' '),
      //   },
    };

    // isUpdatedByView = true;
    lastUpdate = VarLastUpdate.byView;

    // if (typedValue case num input when input != numValue) statusCode = 1;
    // asserts view is set with proper bounds
    // assert(!((typedValue is num) && (_clamp(typedValue) != numValue)));
    // viewValue bound should keep dataValue within format bounds after conversion
    // assert((varKey.binaryFormat?.max != null) ? (dataValue <= varKey.binaryFormat!.max) : true);
    // assert((varKey.binaryFormat?.min != null) ? (dataValue >= varKey.binaryFormat!.min) : true);
  }

  // may not be needed after push pending moved
  // convenience for ValueSetter<T>
  // void updateByViewAs<T>(T typedValue) => (this..updateByViewAs<T>(typedValue))..push(); // some chance mark occur initiating pull
  // void updateByView(V typedValue) => updateByViewAs<V>(typedValue);

  ////////////////////////////////////////////////////////////////////////////////
  /// Json param config
  ////////////////////////////////////////////////////////////////////////////////
  Map<String, Object?> toJson() {
    return {
      'varId': dataKey,
      'varValue': _viewValue,
      'dataValue': dataValue,
      // 'description': varKey.toString(),
    };
  }

  /// init values from json config file, no new/allocation.
  void loadFromJson(Map<String, Object?> json) {
    if (json
        case {
          'varId': int _,
          'varValue': num viewValue,
          'dataValue': int _,
          // 'description': String _,
        }) {
      updateByViewAs<num>(viewValue);
    } else {
      throw const FormatException('Unexpected JSON');
    }
  }
}

enum VarLastUpdate { clear, byData, byView }

// default for over bounds
enum VarValueEnum { unknown }

////////////////////////////////////////////////////////////////////////////////
/// VarStatus
/// Optionally mixin or compose for multiple status
/// generally for status from client side
///
/// alternatively, include code value only, caller handling Enum mapping
///
/// Does not mixin ValueNotifier<VarStatus> to not take up single inheritance
/// S does not have to be generic if all vars share the same status type
////////////////////////////////////////////////////////////////////////////////
abstract mixin class VarStatusNotifier implements ChangeNotifier {
  @mustBeOverridden
  VarStatus statusOf(int statusCode) => VarStatus.defaultCode(statusCode);

  R statusAsEnumSubtype<R extends Enum>() => throw UnimplementedError();
  R statusAsSubtype<R extends VarStatus>() => throw UnimplementedError();

  int _statusCode = 0;
  int get statusCode => _statusCode;
  set statusCode(int value) {
    _statusCode = value;
    notifyListeners();
  }

  void updateStatusByData(int status) => statusCode = status;

  /// view typed
  // VarStatus get status => statusAs<VarStatus>(); // not necessary unless Status is generic
  // set status(VarStatus newValue) => updateStatusByViewAs<VarStatus>(newValue);
  VarStatus get status => statusOf(statusCode);

  Enum? get statusAsEnum => status.enumId;
  bool get statusIsError => statusCode != 0;
  bool get statusIsSuccess => statusCode == 0;

  R statusAs<R>() {
    return switch (R) {
      const (int) => statusCode,
      const (bool) => statusIsSuccess,
      const (Enum) => status.enumId ?? VarStatusUnknown.unknown,
      const (VarStatus) => status,
      // _ when TypeKey<R>().isSubtype<VarStatus>() => statusId, // statusOf must have been overridden for R
      // _ when TypeKey<R>().isSubtype<Enum>() => statusId.enumId,
      _ => throw UnsupportedError('statusAs: $R'),
    } as R;
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

  void updateStatusByView(VarStatus status) => updateStatusByViewAs<VarStatus>(status);
}
