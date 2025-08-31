import 'dart:ffi';

import 'package:cmdr/type_ext.dart';
import 'package:type_ext/basic_types.dart';

import 'package:binary_data/binary_data.dart';

import 'num_ext.dart';

/// Data/number format
/// ffi marker constrains type, only use as marker
enum BinaryFormat<S extends NativeType, V extends Object> {
  /// Fixed-point number formats
  /// Q fraction types, view = rawValue * unitsRef/FormatRef
  fract16<Int16, double>(reference: 32767), // Q1.15
  ufract16<Uint16, double>(reference: 32768), // frac16 abs with 2x over-saturation
  uaccum16<Uint16, double>(reference: 128), // Q9.7
  accum16<Int16, double>(reference: 128), // Q9.7

  percent16<Uint16, double>(reference: 65535), // Q0.16
  angle16<Uint16, double>(reference: 65536), // marker for alternative sign handling
  ufixed16<Uint16, double>(reference: null), // caller handle
  // fixed32(reference:   ),
  ///
  scalar10<Int16, double>(reference: 10), // view = Int16/10
  scalarInv10<Int16, int>(reference: 1 / 10), // view = Int16*10
  // scalar100(reference: 100),
  // scalar1000(reference: 1000),

  /// Integer types, transmitted as int or truncated value
  int16<Int16, int>(reference: 1),
  uint16<Uint16, int>(reference: 1),
  // int32(reference: Int32 ),

  /// Type formats, non-numerical view
  /// Reference as null for no conversion. 0 or 1 may execute unnecessary conversions
  boolean<Bool, bool>(reference: null),
  sign<Int, int>(reference: null),
  sign16<Int16, int>(reference: null),

  /// keyed types, has per type dependencies
  /// alternatively int
  bits16<Uint16, BitsBase>(reference: null),
  enum16<Uint16, Enum>(reference: null),
  // bits16<Uint16, int>(reference: null),
  // enum16<Uint16, int>(reference: null),

  /// Not a number format but a value relative to the client platform.
  /// Included here as marker for special handling, simplifies caller defs
  adcu<Uint16, double>(reference: null)
  // never<Void, Never>(reference: null),
  ;

  const BinaryFormat({required this.reference});
  final num? reference; // value equal to 1, conversion divider

  // Type get baseType => S;
  // Type get viewType => V;

  TypeKey<S> get baseType => TypeKey<S>();
  TypeKey<V> get viewType => TypeKey<V>();

  R callTyped<R>(R Function<G>() callback) => callback<V>();

  ({int min, int max}) get baseRange {
    return switch (S) {
      const (Uint16) => (min: 0, max: 65535),
      const (Int16) => (min: -32768, max: 32767),
      const (Bool) => (min: 0, max: 1),
      const (Void) => (min: 0, max: 0),
      _ => throw StateError('Invalid type $S'),
    };
  }

  // represented range
  ({num min, num max}) get valueRange {
    return (reference != null) ? (min: baseRange.min / reference!, max: baseRange.max / reference!) : baseRange;
  }

  /// for sign extension
  /// adcu maybe signed view without sign extension
  bool get isSigned {
    return switch (S) {
      const (Uint16) => false,
      const (Int16) => true,
      const (Int) => true,
      const (Bool) => false,
      const (Void) => false,
      _ => throw StateError('Invalid type $S'),
    };
  }

  static int _signExtension16(int raw16) => raw16.toSigned(16);
  static int _signExtension32(int raw32) => raw32.toSigned(32);
  static int _signExtension8(int raw32) => raw32.toSigned(8);

  int Function(int bytes)? get signExtension {
    return switch (S) {
      const (Int32) => _signExtension32,
      const (Int16) => _signExtension16,
      const (Int) when (this == sign) => _signExtension8, // extend from lowest bit possible
      _ => null,
    };
  }

  // const (double) when (this != adcu),  ref > 0
  bool get isFixedPoint => switch (this) {
    fract16 || ufract16 || ufixed16 || percent16 || uaccum16 || accum16 => true,
    _ => false,
  };
  bool get isScalarBase10 => switch (this) {
    scalar10 || scalarInv10 => true,
    _ => false,
  };

  // reference != null || adcu
  bool get isNumeric => switch (V) {
    const (int) || const (double) when (this != bits16) => true,
    _ => false,
  }; // !isEnum && !isBits && !isBoolean;

  // bool get isInteger => switch (this) { int16 || uint16 => true, _ => false };
  // bool get isFraction => isFixedPoint || isScalar || (this == adcu || this == cycles);

  // direct partial conversion
  // int signed(int raw16) => (isSigned) ? _signExtension16(raw16) : raw16;
  // double decimal(int bytes) => signed(bytes) / reference;
}

///
/// [BinaryCodec<V>]
///
abstract interface class BinaryCodec<V> {
  const BinaryCodec._();
  factory BinaryCodec({required DataDecoder<V> decoder, required DataEncoder<V> encoder}) = BinaryCodecImpl<V>;

  V decode(int data);
  int encode(V view);
}

typedef DataDecoder<T> = T Function(int data);
typedef DataEncoder<T> = int Function(T view);

final class BinaryCodecImpl<V> implements BinaryCodec<V> {
  const BinaryCodecImpl({required this.decoder, required this.encoder});

  final DataDecoder<V> decoder;
  final DataEncoder<V> encoder;

  V decode(int data) => decoder(data);
  int encode(V view) => encoder(view);
}

// abstract mixin class BinaryNumCodecBase<V extends num> implements BinaryCodec<V> {
//   ({V min, V max})? get numLimits;
//   int signedOf(int binary); // int64Of
//   V numOf(int data);
//   int dataOf(V view);

//   V _clamp(V value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) as V : value;

//   @override
//   V decode(int data) => numOf(signedOf(data));
//   @override
//   int encode(V view) => dataOf(_clamp(view));

//   ///
//   double normalizedOf(num value) => (value / numLimits!.max).clamp(-1.0, 1.0); // only call when numLimits is set
//   double percentOf(num value) => normalizedOf(value) * 100;
// }

class BinaryNumCodec<V extends num> implements BinaryCodec<V> {
  const BinaryNumCodec({required this.numOfData, required this.dataOfNum, this.numLimits, this.signExtension = _defaultSignExtension});

  /// [withConversion] handle case: with signExtension, without conversion
  BinaryNumCodec.of({BinaryNumConversion? conversion, this.numLimits, this.signExtension = _defaultSignExtension})
    : numOfData = conversion?.viewOfData ?? _defaultNumOf,
      dataOfNum = conversion?.dataOfView ?? _defaultDataOf;

  BinaryNumCodec.linear(BinaryFormat binaryFormat, num unitRef, {this.numLimits})
    : numOfData = BinaryLinearConversion(unitRef / binaryFormat.reference!).conversion!.viewOfData,
      dataOfNum = BinaryLinearConversion(unitRef / binaryFormat.reference!).conversion!.dataOfView,
      signExtension = binaryFormat.signExtension;

  final NumOfData numOfData;
  final DataOfNum dataOfNum;
  final DataOfBytes? signExtension;
  final ({num min, num max})? numLimits;

  int _dataOfBinary(int binary) => signExtension?.call(binary) ?? binary;
  num _clamp(num value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) : value;

  @override
  V decode(int data) => numOfData(_dataOfBinary(data)).to<V>();
  // V decode(int data) => numOfData(signExtension(data)).to<V>();
  @override
  int encode(V view) => dataOfNum(_clamp(view));

  //   ///
  //   double normalizedOf(num value) => (value / numLimits!.max).clamp(-1.0, 1.0); // only call when numLimits is set
  //   double percentOf(num value) => normalizedOf(value) * 100;

  ///
  static const BinaryNumConversion defaultConversion = (viewOfData: _defaultNumOf, dataOfView: _defaultDataOf);
  static int _defaultSignExtension(int binary) => binary;
  static num _defaultNumOf(int data) => data;
  static int _defaultDataOf(num view) => view as int;
}

/// Numeric value conversion
typedef NumOfData = num Function(int data);
typedef DataOfNum = int Function(num view);
typedef DataOfBytes = int Function(int bytes); // signExtension/dataOfBytes optionally seperate from viewOfData
typedef BinaryNumConversion = ({NumOfData viewOfData, DataOfNum dataOfView});

// Linear conversion between data and view
extension type const BinaryLinearConversion(num coefficient) {
  BinaryLinearConversion.unitRef(BinaryFormat format, num unitRef) : coefficient = unitRef / format.reference!;

  num viewOf(int dataValue) => (dataValue * coefficient);
  int dataOf(num viewValue) => (viewValue ~/ coefficient);

  BinaryNumConversion? get conversion {
    return switch (coefficient) {
      1 => null, // no conversion
      0 => null, // no conversion
      num(isFinite: false) => null, // no conversion
      _ => (viewOfData: viewOf, dataOfView: dataOf),
    };
  }

  // NumOfData? get viewOfData => (coefficient.isFinite) ? viewOf : null;
  // DataOfNum? get dataOfView => (coefficient.isFinite && coefficient != 0) ? dataOf : null;
}

///
class BinaryEnumCodec<V extends Enum> implements BinaryCodec<V> {
  /// Enum subtype, in case a value other than enum.index is selected
  const BinaryEnumCodec({required this.decoder, required this.encoder, required this.enumRange});

  /// [byIndex] returns first on out of range input
  BinaryEnumCodec.of(this.enumRange) : decoder = enumRange.byIndex as DataDecoder<V>, encoder = _defaultEnumEncoder;

  /// [byIndexOrNull] returns null on out of range input
  BinaryEnumCodec.nullable(this.enumRange) : assert(null is V), decoder = enumRange.elementAtOrNull as DataDecoder<V>, encoder = _defaultEnumEncoder;

  /// throw if V is not exactly type Enum, returns non-nullable Enum
  BinaryEnumCodec.base(this.enumRange) : assert(V == Enum), decoder = enumRange.resolveAsBase as DataDecoder<V>, encoder = _defaultEnumEncoder;

  final DataDecoder<V> decoder;
  final DataEncoder<V> encoder;
  final List<V> enumRange;

  static int _defaultEnumEncoder(Enum view) => view.index;

  @override
  V decode(int data) => decoder.call(data);
  @override
  int encode(V view) => encoder.call(view);
}

class BinaryBitStructCodec<V extends BitStruct> implements BinaryCodec<V> {
  const BinaryBitStructCodec({required this.decoder, required this.encoder, required this.bitsKeys});

  /// [standard] V is base type or throw
  BinaryBitStructCodec.base(this.bitsKeys) : assert(V == BitStruct), decoder = bitsKeys.decode as DataDecoder<V>, encoder = bitsKeys.encode as DataEncoder<V>;

  final DataDecoder<V> decoder;
  final DataEncoder<V> encoder;
  final List<BitField> bitsKeys;

  @override
  V decode(int data) => decoder.call(data);
  @override
  int encode(V view) => encoder.call(view);
}

extension on List<BitField> {
  BitStruct encode(int value) => BitStruct.view(this, value as Bits);
  int decode(BitStruct bits) => bits.value;
}

/// UnionNumCodec
abstract mixin class BinaryUnionCodec<V> implements BinaryCodec<V> {
  const BinaryUnionCodec();
  const factory BinaryUnionCodec.of({BinaryCodec<V>? codec, ({num min, num max})? numLimits, List<Enum>? enumRange, List<BitField>? bitsKeys}) = BinaryUnionCodecImpl<V>;

  BinaryCodec<V>? get codec;
  // BinaryCodec<num>? get codec;

  // maintain for view options
  // Limits as the values the num can take, inclusive, compare with >= and <=
  ({num min, num max})? get numLimits; // must be null for non-num types
  List<Enum>? get enumRange; // EnumSubtype.values must be non-null for Enum types
  List<BitField>? get bitsKeys;
  // Iterable<V>? get enumRange;
  // ({V min, V max})? get numLimits; // must be null for non-num types

  @override
  V decode(int data) => codec?.decode(data) ?? decodeAsNum<V>(data);
  @override
  int encode(V view) => codec?.encode(view) ?? encodeAsNum<V>(view);

  num clamp(num value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) : value;
  Enum? enumOf(int value) => enumRange?.elementAtOrNull(value);
  BitStruct? bitsOf(int value) => (bitsKeys != null) ? BitStruct.view(bitsKeys!, value as Bits) : null;

  // default without conversion
  R decodeAsNum<R>(int data) {
    return switch (R) {
          const (int) => data,
          const (double) => data.toDouble(),
          const (num) => data,
          const (bool) => (data != 0),
          const (Enum) => enumRange?.byIndex(data) ?? EnumUnknown.unknown,
          const (BitStruct) => BitStruct.view(bitsKeys ?? <BitField>[], data as Bits),
          _ => throw UnsupportedError('Unsupported type: $R'),
        }
        as R;
  }

  int encodeAsNum<T>(T view) {
    return switch (T) {
      const (int) => view as int,
      const (double) => (view as double).toInt(),
      const (num) => (view as num).toInt(),
      const (bool) => (view as bool) ? 1 : 0,
      const (Enum) => (view as Enum).index,
      const (BitStruct) => (view as BitStruct).bits,
      _ => throw UnsupportedError('Unsupported type: $T'),
    };
  }

  R decodeAs<R>(int data) {
    if (R == V) return decode(data) as R;
    return decodeAsNum<R>(data);
  }

  int encodeAs<T>(T view) {
    if (T == V) return encode(view as V);
    return encodeAsNum(view);
  }

  /// update
  // static num numValueOf<T>(T view) {
  //   return switch (T) {
  //     const (int) => view as int,
  //     const (double) => view as double,
  //     const (num) => view as num,
  //     const (bool) => (view as bool) ? 1 : 0,
  //     const (Enum) => (view as Enum).index,
  //     const (BitStruct) => (view as BitStruct).bits,
  //     _ => throw UnsupportedError('Unsupported type: $T'),
  //   };
  // }

  V get valueDefault {
    return switch (V) {
          const (int) => 0,
          const (double) => 0.0,
          const (String) => '',
          const (bool) => false,
          // const (Enum) => Enum.unknown,
          _ => decode.call(0) ?? (throw UnsupportedError('Unsupported type: $V')),
        }
        as V;
  }
}

final class BinaryUnionCodecImpl<V> with BinaryUnionCodec<V> {
  const BinaryUnionCodecImpl({this.codec, this.numLimits, this.enumRange, this.bitsKeys});

  @override
  final BinaryCodec<V>? codec;

  @override
  final ({num min, num max})? numLimits;
  @override
  final List<Enum>? enumRange;
  @override
  final List<BitField>? bitsKeys;
}

/// mixin value field
// abstract mixin class NumUnion implements BinaryUnionCodec<V> {
//   num get numValue;
//   set numValue(num newValue);

//   R valueAs<R>() {
//     if (R == V) return decode(numValue.toInt());
//     return switch (R) {
//           const (int) => numValue.toInt() as R,
//           const (double) => numValue.toDouble() as R,
//           const (num) => numValue as R,
//           const (bool) => (numValue != 0) as R,
//           const (Enum) => enumRange?.byIndex(numValue.toInt()) ?? EnumUnknown.unknown as R,
//           const (BitStruct) => BitStruct.view(bitsKeys ?? <BitField>[], numValue.toInt() as Bits) as R,
//           _ => throw UnsupportedError('Unsupported type: $R'),
//         }
//         as R;
//   }
// }
