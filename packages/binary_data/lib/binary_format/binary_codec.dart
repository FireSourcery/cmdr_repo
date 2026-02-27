// import 'dart:convert';
// import 'dart:ffi';

// import 'package:type_ext/basic_types.dart';

// import 'package:binary_data/binary_data.dart';

// import '_binary_format.dart';

// typedef StatelessCodec<S, T> = ({T Function(S) encoder, S Function(T) decoder});

// ///
// /// [BinaryCodec<V>]
// ///
// abstract interface class BinaryCodec<V> {
//   const BinaryCodec._();
//   factory BinaryCodec({required DataDecoder<V> decoder, required DataEncoder<V> encoder}) = BinaryCodecImpl<V>;

//   V decode(int data);
//   int encode(V view);
// }

// typedef DataDecoder<T> = T Function(int data);
// typedef DataEncoder<T> = int Function(T view);

// // final class BinaryCodecImpl<V> implements BinaryCodec<V> {
// //   const BinaryCodecImpl({required this.decoder, required this.encoder});

// //   final DataDecoder<V> decoder;
// //   final DataEncoder<V> encoder;

// //   V decode(int data) => decoder(data);
// //   int encode(V view) => encoder(view);
// // }

// abstract interface class BinaryFractionCodec<V> {
//   BinaryFormat get format;
//   ({V min, V max})? get numLimits;

//   V decode(int data);
//   int encode(V view);
// }

// abstract mixin class BinaryNumCodecBase<V extends num> implements BinaryCodec<V> {
//   ({V min, V max})? get numLimits;
//   // int signedOf(int binary); // int64Of
//   // V numOf(int data);
//   // int dataOf(V view);

//   BinaryFormat get format;

//   V _clamp(V value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) as V : value;

//   @override
//   V decode(int data) => numOf(signedOf(data));
//   @override
//   int encode(V view) => dataOf(_clamp(view));

//   ///
//   double normalizedOf(num value) => (value / numLimits!.max).clamp(-1.0, 1.0); // only call when numLimits is set
//   double percentOf(num value) => normalizedOf(value) * 100;
// }

// class BinaryNumCodec<V extends num> implements BinaryCodec<V> {
//   const BinaryNumCodec({required this.numOfData, required this.dataOfNum, this.numLimits, this.signExtension = _defaultSignExtension});

//   /// [withConversion] handle case: with signExtension, without conversion
//   BinaryNumCodec.of({BinaryNumConversion? conversion, this.numLimits, this.signExtension = _defaultSignExtension})
//     : numOfData = conversion?.viewOfData ?? _defaultNumOf,
//       dataOfNum = conversion?.dataOfView ?? _defaultDataOf;

//   BinaryNumCodec.linear(BinaryFormat binaryFormat, num unitRef, {this.numLimits})
//     : numOfData = BinaryLinearConversion(unitRef / binaryFormat.reference!).conversion!.viewOfData,
//       dataOfNum = BinaryLinearConversion(unitRef / binaryFormat.reference!).conversion!.dataOfView,
//       signExtension = binaryFormat.signExtension;

//   final NumOfData numOfData;
//   final DataOfNum dataOfNum;
//   final DataOfBytes? signExtension;
//   final ({num min, num max})? numLimits;

//   int _dataOfBinary(int binary) => signExtension?.call(binary) ?? binary;
//   num _clamp(num value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) : value;

//   @override
//   V decode(int data) => numOfData(_dataOfBinary(data)).to<V>();
//   // V decode(int data) => numOfData(signExtension(data)).to<V>();
//   @override
//   int encode(V view) => dataOfNum(_clamp(view));

//   //   ///
//   //   double normalizedOf(num value) => (value / numLimits!.max).clamp(-1.0, 1.0); // only call when numLimits is set
//   //   double percentOf(num value) => normalizedOf(value) * 100;

//   ///
//   static const BinaryNumConversion defaultConversion = (viewOfData: _defaultNumOf, dataOfView: _defaultDataOf);
//   static int _defaultSignExtension(int binary) => binary;
//   static num _defaultNumOf(int data) => data;
//   static int _defaultDataOf(num view) => view.toInt();
// }

// /// Numeric value conversion
// typedef NumOfData = num Function(int data);
// typedef DataOfNum = int Function(num view);
// typedef DataOfBytes = int Function(int bytes); // signExtension/dataOfBytes optionally seperate from viewOfData
// typedef BinaryNumConversion = ({NumOfData viewOfData, DataOfNum dataOfView});

// // Linear conversion between data and view
// extension type const BinaryLinearConversion(num coefficient) {
//   BinaryLinearConversion.unitRef(BinaryFormat format, num unitRef) : coefficient = unitRef / format.reference!;

//   num viewOf(int dataValue) => (dataValue * coefficient);
//   int dataOf(num viewValue) => (viewValue ~/ coefficient);

//   BinaryNumConversion? get conversion {
//     return switch (coefficient) {
//       1 => null, // no conversion
//       0 => null, // no conversion
//       num(isFinite: false) => null, // no conversion
//       _ => (viewOfData: viewOf, dataOfView: dataOf),
//     };
//   }

//   // NumOfData? get viewOfData => (coefficient.isFinite) ? viewOf : null;
//   // DataOfNum? get dataOfView => (coefficient.isFinite && coefficient != 0) ? dataOf : null;
// }

// ///
// class BinaryEnumCodec<V extends Enum> implements BinaryCodec<V> {
//   /// Enum subtype, in case a value other than enum.index is selected
//   const BinaryEnumCodec({required this.decoder, required this.encoder, required this.enumRange});

//   /// [byIndex] returns first on out of range input
//   BinaryEnumCodec.of(this.enumRange) : decoder = enumRange.byIndex as DataDecoder<V>, encoder = _defaultEnumEncoder;

//   /// [byIndexOrNull] returns null on out of range input
//   BinaryEnumCodec.nullable(this.enumRange) : assert(null is V), decoder = enumRange.elementAtOrNull as DataDecoder<V>, encoder = _defaultEnumEncoder;

//   /// throw if V is not exactly type Enum, returns non-nullable Enum
//   BinaryEnumCodec.base(this.enumRange) : assert(V == Enum), decoder = enumRange.resolveAsBase as DataDecoder<V>, encoder = _defaultEnumEncoder;

//   final DataDecoder<V> decoder;
//   final DataEncoder<V> encoder;
//   final List<V> enumRange;

//   static int _defaultEnumEncoder(Enum view) => view.index;

//   @override
//   V decode(int data) => decoder.call(data);
//   @override
//   int encode(V view) => encoder.call(view);
// }

// class BinaryBitStructCodec<V extends BitStruct> implements BinaryCodec<V> {
//   const BinaryBitStructCodec({required this.decoder, required this.encoder, required this.bitsKeys});

//   /// [standard] V is base type or throw
//   BinaryBitStructCodec.base(this.bitsKeys) : assert(V == BitStruct), decoder = bitsKeys.decode as DataDecoder<V>, encoder = bitsKeys.encode as DataEncoder<V>;

//   final DataDecoder<V> decoder;
//   final DataEncoder<V> encoder;
//   final List<BitField> bitsKeys;

//   @override
//   V decode(int data) => decoder.call(data);
//   @override
//   int encode(V view) => encoder.call(view);
// }

// extension on List<BitField> {
//   BitStruct encode(int value) => BitStruct.view(this, value as Bits);
//   int decode(BitStruct bits) => bits.value;
// }

// /// UnionNumCodec
// abstract mixin class BinaryUnionCodec<V> implements BinaryCodec<V> {
//   const BinaryUnionCodec();
//   const factory BinaryUnionCodec.of({BinaryCodec<V>? codec, ({num min, num max})? numLimits, List<Enum>? enumRange, List<BitField>? bitsKeys}) = BinaryUnionCodecImpl<V>;

//   BinaryCodec<V>? get codec;
//   // BinaryCodec<num>? get codec;

//   // maintain for view options
//   // Limits as the values the num can take, inclusive, compare with >= and <=
//   ({num min, num max})? get numLimits; // must be null for non-num types
//   List<Enum>? get enumRange; // EnumSubtype.values must be non-null for Enum types
//   List<BitField>? get bitsKeys;
//   // Iterable<V>? get enumRange;
//   // ({V min, V max})? get numLimits; // must be null for non-num types

//   @override
//   V decode(int data) => codec?.decode(data) ?? decodeAsNum<V>(data);
//   @override
//   int encode(V view) => codec?.encode(view) ?? encodeAsNum<V>(view);

//   num clamp(num value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) : value;
//   Enum? enumOf(int value) => enumRange?.elementAtOrNull(value);
//   BitStruct? bitsOf(int value) => (bitsKeys != null) ? BitStruct.view(bitsKeys!, value as Bits) : null;

//   // default without conversion
//   R decodeAsNum<R>(int data) {
//     return switch (R) {
//           const (int) => data,
//           const (double) => data.toDouble(),
//           const (num) => data,
//           const (bool) => (data != 0),
//           const (Enum) => enumRange?.byIndex(data) ?? EnumUnknown.unknown,
//           const (BitStruct) => BitStruct.view(bitsKeys ?? <BitField>[], data as Bits),
//           _ => throw UnsupportedError('Unsupported type: $R'),
//         }
//         as R;
//   }

//   int encodeAsNum<T>(T view) {
//     return switch (T) {
//       const (int) => view as int,
//       const (double) => (view as double).toInt(),
//       const (num) => (view as num).toInt(),
//       const (bool) => (view as bool) ? 1 : 0,
//       const (Enum) => (view as Enum).index,
//       const (BitStruct) => (view as BitStruct).bits,
//       _ => throw UnsupportedError('Unsupported type: $T'),
//     };
//   }

//   R decodeAs<R>(int data) {
//     if (R == V) return decode(data) as R;
//     return decodeAsNum<R>(data);
//   }

//   int encodeAs<T>(T view) {
//     if (T == V) return encode(view as V);
//     return encodeAsNum(view);
//   }

//   /// update
//   // static num numValueOf<T>(T view) {
//   //   return switch (T) {
//   //     const (int) => view as int,
//   //     const (double) => view as double,
//   //     const (num) => view as num,
//   //     const (bool) => (view as bool) ? 1 : 0,
//   //     const (Enum) => (view as Enum).index,
//   //     const (BitStruct) => (view as BitStruct).bits,
//   //     _ => throw UnsupportedError('Unsupported type: $T'),
//   //   };
//   // }

//   V get valueDefault {
//     return switch (V) {
//           const (int) => 0,
//           const (double) => 0.0,
//           const (String) => '',
//           const (bool) => false,
//           // const (Enum) => Enum.unknown,
//           _ => decode.call(0) ?? (throw UnsupportedError('Unsupported type: $V')),
//         }
//         as V;
//   }
// }

// final class BinaryUnionCodecImpl<V> with BinaryUnionCodec<V> {
//   const BinaryUnionCodecImpl({this.codec, this.numLimits, this.enumRange, this.bitsKeys});

//   @override
//   final BinaryCodec<V>? codec;

//   @override
//   final ({num min, num max})? numLimits;
//   @override
//   final List<Enum>? enumRange;
//   @override
//   final List<BitField>? bitsKeys;
// }

// // class BinaryData<S extends NativeType, V extends Object> with {
// //   const BinaryData(this._format, this.value);
// //   final BinaryFormat<S, V> _format;
// // BinaryUnionCodec<V> get _viewer;
// //   final int rawValue;
// //   V get value => (format.reference != null) ? (rawValue / format.reference!) as V : rawValue as V;
// //   // final V value;
// //   // int get rawValue => (format.reference != null) ? (value as num * format.reference!).round() : (value as num).round();
// // }

// // abstract class ValueData {
// //   BinaryUnionCodec<V> get viewer;

// //   int get data;

// /// mixin value field
// // abstract mixin class NumUnion implements BinaryUnionCodec<V> {
// //   num get numValue;
// //   set numValue(num newValue);

// //   R valueAs<R>() {
// //     if (R == V) return decode(numValue.toInt());
// //     return switch (R) {
// //           const (int) => numValue.toInt() as R,
// //           const (double) => numValue.toDouble() as R,
// //           const (num) => numValue as R,
// //           const (bool) => (numValue != 0) as R,
// //           const (Enum) => enumRange?.byIndex(numValue.toInt()) ?? EnumUnknown.unknown as R,
// //           const (BitStruct) => BitStruct.view(bitsKeys ?? <BitField>[], numValue.toInt() as Bits) as R,
// //           _ => throw UnsupportedError('Unsupported type: $R'),
// //         }
// //         as R;
// //   }
// // }
