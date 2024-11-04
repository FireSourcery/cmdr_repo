library var_notifier;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' hide BitField;
import 'package:meta/meta.dart';

import 'package:cmdr_common/basic_types.dart';
import 'package:cmdr_common/service_io.dart';
import 'package:binary_data/binary_data.dart';

export 'package:cmdr_common/basic_types.dart';
export 'package:cmdr_common/service_io.dart';
export 'package:binary_data/binary_data.dart';

part 'var_cache.dart';
// part 'var_context.dart';
part 'var_key.dart';
part 'var_controller.dart';
part 'var_real_time_controller.dart';

// only default status ids need to be overridden
class VarNotifier<V> with ChangeNotifier, VarValueNotifier<V>, VarStatusNotifier {
  VarNotifier({
    required this.varKey,
    // required V value,
    this.viewOfData,
    this.dataOfView,
    this.signExtension,
    this.viewMin,
    this.viewMax,
    this.enumRange,
    this.bitsKeys,
    this.stringDigits,
    this.statusOfCode = VarStatus.defaultCode,
  });

  // VarNotifier.castBase(VarNotifier  base)
  //     : varKey = base.varKey,
  //       enumRange = base.enumRange,
  //       bitsMapKeys = base.bitsMapKeys,
  //       stringDigits = base.stringDigits,
  //       viewOfData = base.viewOfData,
  //       dataOfView = base.dataOfView,
  //       signExtension = base.signExtension,
  //       viewMin = base.viewMin,
  //       viewMax = base.viewMax;

  @protected
  VarNotifier.ofKey(this.varKey)
      : assert(V != dynamic),
        viewOfData = varKey.viewOfData,
        dataOfView = varKey.dataOfView,
        signExtension = varKey.binaryFormat?.signExtension,
        viewMin = varKey.valueNumLimits?.min,
        viewMax = varKey.valueNumLimits?.max,
        enumRange = varKey.valueEnumRange,
        bitsKeys = varKey.valueBitsKeys,
        stringDigits = varKey.valueStringDigits,
        statusOfCode = varKey.varStatusOf;

  factory VarNotifier.of(VarKey varKey) {
    assert(V == dynamic, 'V must be dynamic');
    return varKey.viewType(<G>() => VarNotifier<G>.ofKey(varKey) as VarNotifier<V>);
  }

  @override
  final VarKey varKey;

  /// retain cached values derived from varKey
  @override
  final int Function(int bytes)? signExtension;
  @override
  final ViewOfData? viewOfData; //num conversion only, null for Enum and Bits
  @override
  final DataOfView? dataOfView;
  @override
  final num? viewMin;
  @override
  final num? viewMax;

  // for enum conversion only.
  // although enumerated types can be implemented using other types, it is generally preferred to use enums.
  @override
  final List<Enum>? enumRange;

  // for bit conversion only.
  @override
  final List<BitField>? bitsKeys;

  @override
  final int? stringDigits;

  VarStatus Function(int statusCode) statusOfCode;

  @override
  VarStatus statusOf(int statusCode) => statusOfCode(statusCode);

  @override
  String toString() => '$runtimeType { key: ${varKey.label}, value: $numValue, status: $statusCode }';
}

/// A notifier combining a value and status code on a single listenable.
///  supports conversion between view and data values.
abstract mixin class VarValueNotifier<V> implements ValueNotifier<V> {
  VarKey get varKey; // allow varKey to be assigned as dynamic

  /// by default get from varKey. resolve in constructor to cache
  /// retain cached values derived from varKey
  int Function(int bytes)? get signExtension;
  ViewOfData? get viewOfData; //num conversion only, null for Enum and Bits
  DataOfView? get dataOfView;

  // still effective if set for a non num V
  num? get viewMin;
  num? get viewMax;
  // doubles only
  int? get stringDigits;
  // for enum conversion only.
  // although range bound types can include other types, it is generally preferred to use enums.
  List<Enum>? get enumRange;
  // for bits conversion only.
  List<BitField>? get bitsKeys;

  int dataOfBytes(int bytes) => signExtension?.call(bytes) ?? bytes;
  num viewOf(int data) => viewOfData?.call(data) ?? data; // 'view base'
  int dataOf(num view) => dataOfView?.call(view) ?? view.toInt();

  num clamp(num value) => switch ((viewMin, viewMax)) { (num min, num max) => value.clamp(min, max), _ => value };

  Enum? enumOf(int value) => enumRange?.elementAtOrNull(value); // returns null if varName is not associated with enum value type
  BitFields? bitFieldsOf(int value) => BitStructClass(bitsKeys ?? <BitField>[]).castBits(value);

  // @override
  // String toString() => '$runtimeType $numValue'; // $statusCode

  /// runtime variables
  // same as ChangeNotifier._count
  // alternatively cache need parallel list to track duplicates.
  int viewerCount = 0;
  bool isUpdatedByView = false; // pushUpdateFlag
  // bool outOfRange; // value from client out of range

  /// superclass implementation
  @override
  V get value => valueAs<V>();
  @override
  set value(V newValue) => updateByViewAs<V>(newValue);

  ////////////////////////////////////////////////////////////////////////////////
  /// [numValue] The base representation of the value as a num. "view side base"
  ///   since it is the base for all generic types that can be converted to and from,
  ///     [valueAs<R>()] can always return a value without throwing; the closest representation possible.
  ///   primitive/register sized only for now
  ///   consistent DataOfView interface
  ///   multiple view on the same value will require conversion anyway
  ///   using view side num as notifier,
  ///   notify view side listener on all updates, not all changes are pushed to client
  ////////////////////////////////////////////////////////////////////////////////
  num _numValue = 0;
  num get numValue => _numValue;
  set numValue(num value) {
    if (_numValue == value) return;
    _numValue = value;
    notifyListeners();
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// [dataValue] from packet. convert on transmit only. lazy update on updateByView
  ////////////////////////////////////////////////////////////////////////////////
  int get dataValue => dataOf(numValue);
  // set dataValue(int value) => updateByData(value);

  // Always accept client data. correction is handled at client side.
  // value over view boundaries handle by UI

  // after sign extension
  void _updateByData(int dataValue) => numValue = viewOf(dataValue);
  // if (numValue != _clampedNumValue) {
  //   statusCode = 1;
  // }

  // before sign extension
  void updateByData(int bytesValue) => _updateByData(dataOfBytes(bytesValue));

  // Var as Entry including key
  // outbound data
  int get dataKey => varKey.value;
  MapEntry<int, int> get dataEntry => MapEntry(dataKey, dataValue);
  (int key, int value) get dataPair => (dataKey, dataValue);

  ////////////////////////////////////////////////////////////////////////////////
  /// [viewValue] from widgets
  /// The value in real world units and constraints. as seen by the user
  ////////////////////////////////////////////////////////////////////////////////
  /// typed view value
  V get viewValue => valueAs<V>();
  // set viewValue(V newValue) => updateByViewAs<V>(newValue);

  @protected
  num get valueAsNum => numValue;
  @protected
  int get valueAsInt => (numValue).toInt();
  @protected
  double get valueAsDouble => (numValue).toDouble();
  @protected
  bool get valueAsBool => (numValue != 0);
  @protected
  Enum get valueAsEnum => enumOf(valueAsInt)!;
  @protected
  BitFields get valueAsBitFields => bitFieldsOf(valueAsInt)!;
  @protected
  Uint8List get valueAsBytes => Uint8List(8)..buffer.asByteData().setUint64(0, valueAsInt, Endian.big);

  // These should return the proper type as long as V is correct
  T valueAsEnumType<T>() => valueAsEnum as T;
  T valueAsBitsType<T>() => valueAsBitFields as T;

  /// view determines type after accounting fo varId.valueType
  R valueAs<R>() {
    return switch (R) {
      const (int) => valueAsInt,
      const (double) => valueAsDouble,
      const (num) => valueAsNum,
      const (bool) => valueAsBool,
      const (Enum) => valueAsEnum,
      const (BitFields) => valueAsBitFields,
      // const (String) => valueAsInt.toStringAsCode(),
      _ when TypeKey<R>().isSubtype<Enum>() => valueAsEnumType<R>(),
      _ when TypeKey<R>().isSubtype<BitsBase>() => valueAsBitsType<R>(),
      // _ => valueAsExtension<R>(),
      _ => throw UnsupportedError('valueAs: $R'),
    } as R;
  }

  // @protected
  // set valueAsEnum(Enum newValue) => numValue = newValue.index;
  // @protected
  // set valueAsBitsMap(BitsBase newValue) => numValue = newValue.bits;

  // caller handle display state of over boundary.
  // input bounds checked only to ensure a valid value is sent to client side
  void updateByViewAs<T>(T typedValue) {
    numValue = switch (T) {
      const (double) || const (int) || const (num) => clamp(typedValue as num),
      const (bool) => (typedValue as bool) ? 1 : 0,
      // update as Enum subtype check first, in case a value other than enum is selected
      _ when TypeKey<T>().isSubtype<Enum>() => (typedValue as Enum).index,
      _ when TypeKey<T>().isSubtype<BitsBase>() => (typedValue as BitsBase).bits,
      _ => throw UnsupportedError('valueAs: $T'),
    };

    isUpdatedByView = true;
    // if (typedValue case num input when input != numValue) statusCode = 1;

    // asserts view is set with proper bounds
    // assert(!((typedValue is num) && (_clamp(typedValue) != numValue)));

    // viewValue bound should keep motValue within format bounds after conversion
    assert((varKey.binaryFormat?.max != null) ? (dataValue <= varKey.binaryFormat!.max) : true);
    assert((varKey.binaryFormat?.min != null) ? (dataValue >= varKey.binaryFormat!.min) : true);
  }

  void updateByView(V typedValue) => updateByViewAs<V>(typedValue);

  ////////////////////////////////////////////////////////////////////////////////
  /// Stringify
  ////////////////////////////////////////////////////////////////////////////////
  String get valueString => valueStringAs<V>();

  // stringifyAs
  String valueStringAs<T>() => varKey.stringify<T>(valueAs<T>());

  ////////////////////////////////////////////////////////////////////////////////
  /// Json param config
  ////////////////////////////////////////////////////////////////////////////////
  Map<String, Object?> toJson() {
    return {
      'varId': varKey.value,
      'varValue': numValue,
      'dataValue': dataValue,
      'description': varKey.toString(),
    };
  }

  /// init values from json config file, no new/allocation.
  void loadFromJson(Map<String, Object?> json) {
    if (json
        case {
          'varId': int _,
          'varValue': num viewValue,
          'dataValue': int _,
          'description': String _,
        }) {
      updateByViewAs<num>(viewValue);
    } else {
      throw const FormatException('Unexpected JSON');
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
/// VarStatus
/// Optionally mixin or compose for multiple status
/// generally for status from client side
///
/// alternatively, include code value only, caller handling Enum mapping
///
///
////////////////////////////////////////////////////////////////////////////////
/// S does not have to be generic if all vars share the same status
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
  VarStatus get status => statusAs<VarStatus>(); // not necessary unless Status is generic
  set status(VarStatus newValue) => updateStatusByViewAs<VarStatus>(newValue);
  VarStatus get statusId => statusOf(statusCode);

  Enum? get statusAsEnum => statusId.enumId;
  bool get statusIsError => statusCode != 0;
  bool get statusIsSuccess => statusCode == 0;

  R statusAs<R>() {
    return switch (R) {
      const (int) => statusCode,
      const (bool) => statusIsSuccess,
      const (Enum) => statusId.enumId ?? VarStatusUnknown.unknown,
      const (VarStatus) => statusId,
      // _ when TypeKey<R>().isSubtype<VarStatus>() => statusId, // statusOf must have been overridden for R
      // _ when TypeKey<R>().isSubtype<Enum>() => statusId.enumId,
      _ => throw TypeError(),
    } as R;
  }

  void updateStatusByViewAs<T>(T status) {
    statusCode = switch (T) {
      const (int) => status as int,
      const (bool) => (status as bool) ? 1 : 0,
      const (Enum) => (status as Enum).index,
      const (VarStatus) => (status as VarStatus).code,
      _ when TypeKey<T>().isSubtype<VarStatus>() => (status as VarStatus).code,
      _ when TypeKey<T>().isSubtype<Enum>() => (status as Enum).index,
      _ => throw TypeError(),
    };
  }

  void updateStatusByView(VarStatus status) => updateStatusByViewAs<VarStatus>(status);
}
