import 'package:flutter/foundation.dart';

///
abstract interface class VarView<V> implements ValueNotifier<V> {
  int get id;
  String get name;
  // move to tag?
  String? get groupName;
  String? get description; // tooltip
  bool get isReadOnly;
  ({num min, num max})? get valueRange;

  // /// num value backing
  // num get valueNum;
  // set valueNum(num value);

  /// the view value, the value as seen by the user
  V get value;
  set value(V value);

  // // for ValueGetter tare off
  // V getValue() => value;

  /// view determines type after accounting fo varId.valueType
  // R valueAs<R>();
  void updateValueChange(V typedValue);
  void updateValueSubmit(V typedValue);

  String get valueString;
  // String valueStringAs<T>();

  int get statusCode;
  bool get statusIsError;
  String get statusString;
}

// typedef ViewOfData = num Function(int data);
// typedef DataOfView = int Function(num view);

// class VarTag<V> {
//   // const VarTag({
//   //   required this.label,
//   //   required this.unitsLabel,
//   //   required this.valueType,
//   //   required this.valueMin,
//   //   required this.valueMax,
//   //   required this.valueDefault,
//   //   required this.valueList,
//   //   required this.valueMap,
//   //   required this.valueEnum,
//   // });

//   final String label;
//   final String suffix;
//   final Type valueType;
//   final num valueMin;
//   final num valueMax;
//   final num valueDefault;
//   final List<num> valueList;
//   final Map<num, String> valueMap;
//   final List<Enum> valueEnum;
// }

/// A notifier combining a value and status code on a single listenable.
///  supports conversion between view and data values.
// class VarNotifier<V> extends VarNotifierBase<V> with ChangeNotifier {
//   VarNotifier({
//     this.viewOfData,
//     this.dataOfView,
//     this.signExtension,
//     required V value,
//     this.viewMin,
//     this.viewMax,
//   });

//   @override
//   int get varId => throw UnimplementedError();
//   final int Function(int bytes)? signExtension;
//   final ViewOfData? viewOfData;
//   final DataOfView? dataOfView;
//   final num? viewMin;
//   final num? viewMax;

//   int dataOfBytes(int bytesValue) => signExtension?.call(bytesValue) ?? bytesValue;
//   num viewOf(int data) => viewOfData?.call(data) ?? data;
//   int dataOf(num view) => dataOfView?.call(view) ?? view.toInt();

//   @override
//   Enum statusIdOf(int statusCode) {
//     throw UnimplementedError();
//   }

//   @override
//   Enum valueNameOf(int value) {
//     throw UnimplementedError();
//   }
// }

// abstract mixin class VarNotifierBase<V> implements ValueNotifier<V> {
//   // VarNotifierBase({
//   //   this.viewOfData,
//   //   this.dataOfView,
//   //   this.signExtension,
//   //   required V value,
//   //   this.viewMin,
//   //   this.viewMax,
//   // });

//   // final int Function(int bytes)? signExtension;
//   // final ViewOfData? viewOfData;
//   // final DataOfView? dataOfView;
//   // final num? viewMin;
//   // final num? viewMax;

//   int get varId;

//   num get viewMin;
//   num get viewMax;

//   // int dataOfBytes(int bytesValue) => signExtension?.call(bytesValue) ?? bytesValue;
//   // num viewOf(int data) => viewOfData?.call(data) ?? data;
//   // int dataOf(num view) => dataOfView?.call(view) ?? view.toInt();
//   // int dataOfBytes(int bytesValue) => signExtension?.call(bytesValue) ?? bytesValue;
//   num viewOf(int data);
//   int dataOf(num view);

//   // these values should have no ViewOfData conversion
//   Enum valueNameOf(int value);
//   Enum statusIdOf(int statusCode);
//   // R valueAsExtension<R>();

//   int viewerCount = 0; // alternatively readStream need parallel list to track duplicates.

//   @override
//   String toString() => '$runtimeType  $numValue $statusCode';

//   ////////////////////////////////////////////////////////////////////////////////
//   ///
//   /// Store as num instead of Generic,
//   ///   a narrower set of types that covers all values
//   ///   consistent DataOfView interface
//   ///   multiple view on the same value will require conversion anyway
//   ///   primitive compatible with ValueNotifier
//   ///   using view side num as notifier, as not all changes are pushed to data
//   ///   some view updates do not need to update dataValue immediately
//   ////////////////////////////////////////////////////////////////////////////////
//   num _numValue = 0;
//   num get numValue => _numValue;
//   set numValue(num value) {
//     _numValue = value;
//     notifyListeners();
//   }

//   @override
//   V get value => valueAs<V>();
//   @override
//   set value(V value) => updateByView<V>(value);

//   String get valueString => valueStringAs<V>();

//   /// packet value, convert on transmit only
//   int get dataValue => dataOf(numValue);

//   // MapEntry<int, int> get dataDataPair => MapEntry(varKey.asDataDataId, dataValue);
//   // (int id, int value) get dataDataRecord => (varKey.asDataDataId, dataValue);

//   ////////////////////////////////////////////////////////////////////////////////
//   /// View Side Value
//   ////////////////////////////////////////////////////////////////////////////////
//   num get _valueAsNum => numValue;
//   int get _valueAsInt => (numValue).toInt();
//   double get _valueAsDouble => (numValue).toDouble();
//   bool get _valueAsBool => (numValue != 0);

//   /// view determines type after accounting fo varId.valueType
//   R valueAs<R>() {
//     return switch (R) {
//       const (int) => _valueAsInt,
//       const (double) => _valueAsDouble,
//       const (bool) => _valueAsBool,
//       const (Enum) => valueNameOf(_valueAsInt),
//       _ => valueAsExtension<R>(),
//     } as R;
//   }

//   String valueStringAs<T>() {
//     return switch (T) {
//       const (int) => _valueAsInt.toString(),
//       const (double) => _valueAsDouble.toStringAsFixed(1),
//       const (bool) => _valueAsBool.toString(),
//       // const (Enum) => valueNameOf(_valueAsInt).name,
//       // Uint8List || List => valueAsChars,
//       _ => throw TypeError(),
//     };
//   }

//   // num _clamp(num value) {
//   //   if (viewMin != null && viewMax != null) {
//   //     return value.clamp(viewMin!, viewMax!);
//   //   }
//   //   return value;
//   // }

//   void updateByData(int bytesValue) {
//     // final dataValue = dataOfBytes(bytesValue);
//     final tempViewValue = viewOf(dataValue);
//     if (tempViewValue == tempViewValue.clamp(viewMin, viewMax)) {
//       numValue = tempViewValue;
//     } else {
//       statusCode = 1;
//     }
//   }

//   void updateByView<T>(T typedValue) {
//     // if (viewValue.clamp(varKey.viewMin, varKey.viewMax) != viewValue) return;
//     numValue = switch (T) {
//       const (double) || const (int) => (typedValue as num).clamp(viewMin, viewMax),
//       const (bool) => (typedValue as bool) ? 1 : 0,
//       const (Enum) => (typedValue as Enum).index, // other enum or DataVarDataorFeedbackMode
//       _ => throw TypeError(),
//     };
//     // viewValue bound should keep dataValue within format bounds after conversion
//   }

//   ////////////////////////////////////////////////////////////////////////////////
//   /// DataVarStatus
//   ////////////////////////////////////////////////////////////////////////////////
//   int _statusCode = 0;
//   int get statusCode => _statusCode;
//   set statusCode(int value) {
//     _statusCode = value;
//     notifyListeners();
//   }

//   Enum get statusId => statusIdOf(statusCode);
//   bool get statusIsError => statusCode != 0;
//   bool get statusIsSuccess => statusCode == 0;

//   R statusAs<R>() {
//     return switch (R) {
//       const (int) => statusCode,
//       const (bool) => statusIsSuccess,
//       const (Enum) => statusId,
//       _ => throw TypeError(),
//     } as R;
//   }

//   void updateStatusByData(int status) {
//     statusCode = status;
//   }

//   void updateStatusByView<T>(T status) {
//     statusCode = switch (T) {
//       const (int) => status as int,
//       const (bool) => (status as bool) ? 1 : 0,
//       const (Enum) => (status as Enum).index,
//       Type() => throw TypeError(),
//     };
//   }

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Json param config
//   ////////////////////////////////////////////////////////////////////////////////
//   // Map<String, Object?> toJson() {
//   //   return {
//   //     'varId': varKey.asDataDataId,
//   //     'varValue': numValue,
//   //     'dataValue': dataValue,
//   //     'description': varKey.label,
//   //   };
//   // }

//   // /// init values from json config file, no new/allocation.
//   // void loadFromJson(Map<String, Object?> json) {
//   //   if (json
//   //       case {
//   //         'varId': int _,
//   //         'varValue': num viewValue,
//   //         'dataValue': int _,
//   //         'description': String _,
//   //       }) {
//   //     updateByView<num>(viewValue.clamp(varKey.viewMin, varKey.viewMax));
//   //   } else {
//   //     throw const FormatException('Unexpected JSON');
//   //   }
//   // }
// }

// // abstract mixin class VarNotifierExtension<V> implements VarNotifier<V> {
// //   Enum valueNameOf(int value) => throw UnimplementedError();
// //   Enum statusIdOf(int statusCode) => throw UnimplementedError();
// //   R valueAsExtension<R>() => throw UnimplementedError();
// // }
