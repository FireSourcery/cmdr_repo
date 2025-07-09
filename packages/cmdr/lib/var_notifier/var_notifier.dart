library var_notifier;

// import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' hide BitField;

import 'package:type_ext/basic_types.dart';
import 'package:binary_data/binary_data.dart';
import 'package:cmdr/interfaces/service_io.dart';

export 'package:type_ext/basic_types.dart';
export 'package:binary_data/binary_data.dart';
export 'package:cmdr/interfaces/service_io.dart';

part 'var_key.dart';
part 'var_cache.dart';
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

  //
  VarNotifier.ofKey(this.varKey) : assert(V != dynamic) {
    initReferences();
  }

  // derive type from [VarKey]
  factory VarNotifier.of(VarKey varKey) {
    assert(V == dynamic, 'V must be dynamic');
    return varKey.viewType(<G>() => VarNotifier<G>.ofKey(varKey) as VarNotifier<V>);
  }

  final VarKey varKey;
  late final int dataKey = varKey.value; // compute once and cache
  // final ValueNotifier? eventNotifier = ValueNotifier(null); //optional for user submit

  // alternatively as notifier can update stream
  // num outputValue = 0; // for output value, not used in VarNotifier
  // VarLastUpdate lastUpdate = VarLastUpdate.clear;

  // final VarReferences references;
  /// Derived from [VarKey] and cached
  /// reinit on VarKey update
  void initReferences(/* optionally pass */) {
    signExtension = varKey.signExtension;
    viewOfData = varKey.viewOfData;
    dataOfView = varKey.dataOfView;
    numLimits = varKey.valueNumLimits;
    enumRange = varKey.valueEnumRange;
    bitsKeys = varKey.valueBitsKeys;

    _viewValue = clamp(_viewValue);
  }

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  /// as outbound data depending on [dataKey]
  MapEntry<int, int> get dataEntry => MapEntry(dataKey, dataValue);
  (int key, int value) get dataPair => (dataKey, dataValue);

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
  String toString() => '${describeIdentity(this)}(`${varKey.label}`)($value = $_viewValue)';

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  @override
  T subtypeOf<T>(num value) => varKey.subtypeOf<T>(value);
  @override
  num valueOfSubtype<T>(T value) => varKey.valueOfSubtype<T>(value);

  ////////////////////////////////////////////////////////////////////////////////
  // @override
  // void updateStatusByData(int status) {
  //   super.updateStatusByData(status);
  //   isUpdatedByView = false;
  // }

  ////////////////////////////////////////////////////////////////////////////////
  /// Proxy with different view conversion
  // VarNotifier<V1> cloneWith<V1 extends V>({
  //   int Function(int binary)? signExtension,
  //   ViewOfData? viewOfData,
  //   DataOfView? dataOfView,
  //   ({num min, num max})? numLimits,
  //   List<Enum>? enumRange,
  //   List<BitField>? bitsKeys,
  // }) {
  //   return VarNotifier<V1>(
  //     varKey: this.varKey,
  //     signExtension: signExtension ?? this.signExtension,
  //     viewOfData: viewOfData ?? this.viewOfData,
  //     dataOfView: dataOfView ?? this.dataOfView,
  //     numLimits: numLimits ?? this.numLimits,
  //     enumRange: enumRange ?? this.enumRange,
  //     bitsKeys: bitsKeys ?? this.bitsKeys,
  //   ).._viewValue = viewOfData?.call(dataValue) ?? 0; // copy current value
  //   // ..mergeListeners(this) // copy listeners;

  //   // addListener(listener)
  // }

  ////////////////////////////////////////////////////////////////////////////////
  /// Json
  ////////////////////////////////////////////////////////////////////////////////
  Map<String, Object?> toJson() {
    return {
      'varId': dataKey,
      'varValue': _viewValue,
      'dataValue': dataValue,
      'description': varKey.label,
    };
  }

  /// init values from json config file, no new/allocation.
  void loadFromJson(Map<String, Object?> json) {
    if (json
        case {
          'varId': int dataKey,
          'varValue': num viewValue,
          'dataValue': int _,
          'description': String _,
        }) {
      updateByViewAs<num>(viewValue);

      assert(dataKey == this.dataKey, 'VarKey mismatch: $dataKey != ${this.dataKey}'); // handled by caller
      // viewValue bound should keep dataValue within format bounds after conversion
      // assert((varKey.binaryFormat?.max != null) ? (dataValue <= varKey.binaryFormat!.max) : true);
      // assert((varKey.binaryFormat?.min != null) ? (dataValue >= varKey.binaryFormat!.min) : true);
    }
  }

  // for set before loading num limits
  void updateByFile(num newValue) => _viewValue = newValue;
}

/// [VarValueNotifier<V>]
/// A notifier combining a ValueNotifier with support for conversion between view types and data values.
/// It be can further combined with a status notifier.
///
/// alternatively as
/// UnionValueNotifier implements ValueNotifier<num> with conversion methods
abstract mixin class VarValueNotifier<V> implements ValueNotifier<V> {
  // int get dataMin;
  // int get dataMax;
  // final ValueNotifier<num> _valueNotifier;
  // int get dataKey;

  ////////////////////////////////////////////////////////////////////////////////
  /// Config
  ////////////////////////////////////////////////////////////////////////////////
  /// caching results from VarKey for performance. these do not have to be immutable.
  /// values are already nullable
  /// additionally all mutability is contained in a single layer. cache preallocate can be immutable
  /// by default get from varKey. resolve in constructor to cached values derived from varKey
  int Function(int binary)? signExtension;
  ViewOfData? viewOfData; // num conversion only, null for Enum and Bits
  DataOfView? dataOfView;

  ({num min, num max})? numLimits; //  view base limits, still effective for non-num V, if set
  List<Enum>? enumRange; // for enum conversion only. other range bound types, e.g String, provide by enum.
  List<BitField>? bitsKeys; // for bits conversion only.

  @override
  String toString() => '${describeIdentity(this)}($value)';

  /// numeric conversion methods
  int dataOfBinary(int binary) => signExtension?.call(binary) ?? binary;
  num viewOf(int data) => viewOfData?.call(data) ?? data; // 'view base'
  int dataOf(num view) => dataOfView?.call(view) ?? view.toInt();

  num clamp(num value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) : value;

  // optimize away null checks
  // static int _dataOfBinaryNull(int binary) => binary;
  // static num _viewOfNull(int data) => data;
  // static int _dataOfNull(num view) => view.toInt();

  // int Function(int binary) dataOfBinary = _dataOfBinaryNull;
  // ViewOfData viewOf = _viewOfNull;
  // DataOfView dataOf = _dataOfNull;

  ////////////////////////////////////////////////////////////////////////////////
  /// type cast conversion
  /// can be overridden by VarKey
  ////////////////////////////////////////////////////////////////////////////////
  Enum enumOf(int value) => enumRange?.elementAtOrNull(value) ?? VarValueEnum.unknown;
  BitStruct bitFieldsOf(int value) => BitStruct.view(bitsKeys ?? const <BitField>[], value as Bits);

  /// User defined subtypes
  /// Returns the as the exact type, to account for user defined method on that type
  T subtypeOf<T>(num value) => throw UnsupportedError(' : $T');
  num valueOfSubtype<T>(T value) => throw UnsupportedError(' : $T');

  ////////////////////////////////////////////////////////////////////////////////
  /// runtime variables
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  /// Typed [value]
  /// superclass implementation
  /// typed view value
  ////////////////////////////////////////////////////////////////////////////////
  @override
  V get value => valueAs<V>();
  @override
  set value(V newValue) => updateByViewAs<V>(newValue);

  // V valueGetter() => valueAs<V>();

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

  // alternatively mvoe to VarNotifer and wrap update fns
  // or separate output value
  // num outputValue = 0; // for output value, not used in VarNotifier
  VarLastUpdate lastUpdate = VarLastUpdate.clear;

  bool hasIndirectListeners = false;
  bool get hasListenersCombined => hasListeners || hasIndirectListeners;

  // if separating internal and external status
  // bool outOfRange; // value from client out of range

  ////////////////////////////////////////////////////////////////////////////////
  /// [dataValue] from packet. convert on transmit only. lazy update on updateByView
  /// Always accept client data. correction is handled at client side.
  /// value over view boundaries handle by UI
  ////////////////////////////////////////////////////////////////////////////////
  int get dataValue => dataOf(_viewValue);

  set _dataValue(int value) => _viewValue = viewOf(dataValue);

  // before sign extension
  // updatedByView wait for push
  void updateByData(int bytesValue) {
    _dataValue = dataOfBinary(bytesValue);
    lastUpdate = VarLastUpdate.byData;

    // if (numValue != _clampedNumValue) statusCode = 1;
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// [viewValue] from widgets
  /// The value seen by the user
  ////////////////////////////////////////////////////////////////////////////////
  /// num storage value, viewValue, baseValue
  num get numValue => _viewValue;
  set numValue(num newValue) {
    _viewValue = clamp(newValue);
    lastUpdate = VarLastUpdate.byView;
  }
  // void updateByView(num numValue) {
  //   _viewValue = clamp(numValue);
  //   lastUpdate = VarLastUpdate.byView;
  // }

  ///
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
  String get valueAsString => String.fromCharCodes(valueAsBytes);
  @protected
  Uint8List get valueAsBytes => Uint8List(8)..buffer.asByteData().setUint64(0, valueAsInt, Endian.big);

  /// viewAs
  /// caller determines type after accounting for VarKey
  /// generic getter use switch on type literal, and require extension to account for subtypes
  R valueAs<R>() {
    return switch (R) {
      const (int) => valueAsInt,
      const (double) => valueAsDouble,
      const (num) => valueAsNum,
      const (bool) => valueAsBool,
      // match by type literal cannot be subtype
      const (Enum) => valueAsEnum,
      const (BitStruct) => valueAsBitFields,
      const (String) => valueAsString,
      _ => subtypeOf<R>(_viewValue),
    } as R;
  }

  R? valueAsEnumWith<R extends Enum>(List<R> enumValues) => enumValues.elementAtOrNull(valueAsInt);
  BitStruct<K> valueAsBitStructWith<K extends BitField>(List<K> bitsKeys) => BitStruct<K>.view(bitsKeys, valueAsInt as Bits);

  /// update
  // @protected
  // set valueAsEnum(Enum newValue) => _numValue = newValue.index;
  // @protected
  // set valueAsBitFields(BitStruct newValue) => _numValue = newValue.bits;

  // input bounds checked only to ensure a valid value is sent to client side
  // switch on value will also handle dynamic
  /// generic setter can optionally switch on object type
  void updateByViewAs<T>(T typedValue) {
    _viewValue = switch (T) {
      const (double) || const (int) || const (num) => clamp(typedValue as num),
      const (bool) => (typedValue as bool) ? 1 : 0,

      // Enum subtype pass subtype, in case a value other than enum.index is selected
      const (Enum) => (typedValue as Enum).index,
      const (BitStruct) => (typedValue as BitStruct).bits,
      _ => valueOfSubtype<T>(typedValue),
      // const (dynamic) => updateByView(typedValue),
    };

    lastUpdate = VarLastUpdate.byView;
    // if (typedValue case num input when input != numValue) statusCode = 1;
  }
}

/// alternatively seperate
enum VarLastUpdate { clear, byData, byView }

// replace null for over bounds
enum VarValueEnum { unknown }

// enum BitFieldDefault with BitField {
//   unknown(Bitmask(0,64));
// }

////////////////////////////////////////////////////////////////////////////////
/// [VarStatus]
/// implement as mixin
///   optionally mixin to share notifier
///   or compose for seperated value/status, multiple status
/// generally for status from client side
///
/// alternatively, include code value only, caller handling Enum mapping
///
/// Does not mixin ValueNotifier<VarStatus> to not take up single inheritance
/// S does not have to be generic if all vars share the same status type
////////////////////////////////////////////////////////////////////////////////
abstract mixin class VarStatusNotifier implements ChangeNotifier {
  // List<VarStatus> get statusCodes => VarStatusDefault.values;
  @mustBeOverridden
  VarStatus statusOf(int statusCode) => VarStatus.defaultOf(statusCode);

  // R statusAsEnumSubtype<R extends Enum>() => throw UnimplementedError();
  // R statusAsSubtype<R extends VarStatus>() => throw UnimplementedError();

  int _statusCode = 0;
  int get statusCode => _statusCode;
  set statusCode(int value) {
    _statusCode = value;
    notifyListeners();
  }

  /// view typed
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
}

//////////////////////////////////////////////////////////////////////////////
// User submit
//   associated with UI component, instead of VarNotifier value
//   not triggerd by value changes
//   Listeners to the VarNotifier value on another UI component will not be notified of submit
//////////////////////////////////////////////////////////////////////////////
class VarEventNotifier extends ChangeNotifier {
  VarEventNotifier({required this.varNotifier, required this.onSubmitted});
  final VarNotifier<dynamic> varNotifier; // typed by Key. returning as dynamic.
  final ValueSetter<VarNotifier<dynamic>> onSubmitted;
  // final ValueSetter<VarNotifier<dynamic>> onSubmitted(VarCache);

  void submitByViewAs<T>(T varValue) {
    varNotifier.updateByViewAs<T>(varValue);
    onSubmitted(varNotifier);
    notifyListeners();
  }
}

// class VarNotifierProxy<V> extends VarNotifier<V> {
//   VarNotifierProxy({
//     VarNotifier<V>? source,
//     required super.varKey,
//     int Function(int binary)? signExtension,
//     ViewOfData? viewOfData,
//     DataOfView? dataOfView,
//     ({num min, num max})? numLimits,
//     List<Enum>? enumRange,
//     List<BitField>? bitsKeys,
//   }) : super(
//           signExtension: signExtension,
//           viewOfData: viewOfData,
//           dataOfView: dataOfView,
//           numLimits: numLimits,
//           enumRange: enumRange,
//           bitsKeys: bitsKeys,
//         );

//   final VarNotifier<V> source;

//   void _listenSource() {
//     if (source.hasListeners) {
//       source.addListener(notifyListeners);
//       hasIndirectListeners = true;
//     }
//   }

//   @override
//   void addListener(VoidCallback listener) {
//     source.addListener(listener);
//   }

//   VarNotifierProxy.ofKey(VarKey varKey) : super.ofKey(varKey);
// }
