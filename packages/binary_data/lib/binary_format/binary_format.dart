// ignore_for_file: annotate_overrides

import 'dart:ffi';

import '../bits/bit_struct.dart';
import '../data/basic_types.dart';
import '../data/enum_types.dart';
import 'binary_codec.dart';

export 'binary_codec.dart';

part 'binary_formats.dart';

// Separate descriptor constructable for base data type
mixin class NativeTypeFormat<S extends NativeType> {
  const NativeTypeFormat();

  ({int min, int max}) get range => switch (S) {
    const (Uint8) => (min: 0, max: 0xFF),
    const (Int8) => (min: -0x80, max: 0x7F),
    const (Uint16) => (min: 0, max: 0xFFFF),
    const (Int16) => (min: -0x8000, max: 0x7FFF),
    const (Uint32) => (min: 0, max: 0xFFFFFFFF),
    const (Int32) => (min: -0x80000000, max: 0x7FFFFFFF),
    const (Bool) => (min: 0, max: 1),
    const (Int) => (min: -0x80000000, max: 0x7FFFFFFF),
    _ => throw UnsupportedError('Unsupported type: $S'),
  };

  int get byteSize => switch (S) {
    const (Uint8) || const (Int8) => 1,
    const (Uint16) || const (Int16) => 2,
    const (Uint32) || const (Int32) => 4,
    const (Bool) => 1,
    _ => throw UnsupportedError('Unsupported type: $S'),
  };
  int get bitWidth => byteSize * 8;

  int _signExtend(int raw) => raw.toSigned(bitWidth);
  int _maskUnsigned(int raw) => raw & ((1 << bitWidth) - 1);
  bool get isSigned => range.min < 0;
  int Function(int)? get signExtension => isSigned ? _signExtend : null;

  int clampBase(int raw) => raw.clamp(range.min, range.max);

  // static const NativeTypeFormat<Uint8> uint8 = NativeTypeFormat<Uint8>();
}

/// S handle sign extension. V handle base value conversion
sealed class BinaryFormat<S extends NativeType, V> with NativeTypeFormat<S> implements BinaryCodec<V> {
  const BinaryFormat();

  // NativeTypeFormat<S> get baseType => NativeTypeFormat<S>();

  TypeKey<V> get viewType => TypeKey<V>();
  ({int min, int max}) get binaryRange => range; //accepted range

  int encode(V value);
  V decode(int raw);

  // num clampValue(num value) => value.clamp(valueRange.min, valueRange.max);

  @override
  String toString() => runtimeType.toString();

  //ext
  bool get isFixedPoint => this is FixedPoint;
  bool get isScalarBase10 => this is ScalarBase10;
  bool get isNumeric => this is NumFormat;
  bool get isEnum => this is EnumFormat;
  bool get isBool => this is BoolFormat;
}

/// Hierarchy axis on handling
// BinaryFormat
//  ├─ NumFormat<S, V>          ← has signedness/width
//  │   ├─ IntFormat<S>         ← raw integer pass-through
//  │   └─ FractFormat<S>       ← fractional (reference-based)
//  │       ├─ FixedPoint<S>    ← reference = 2^n  (Q format)
//  │       ├─ ScalarBase10<S>  ← reference = 10^n
//  │       └─ _Angle16         ← wrapping angular
//  ├─ BoolFormat
//  ├─ SignFormat
//  └─ EnumFormat<V>

/// Int/Fract
sealed class NumFormat<S extends NativeType, V extends num> extends BinaryFormat<S, V> {
  const NumFormat();
  num get formatScalar;
  ({num min, num max}) get valueRange => range;

  int signedOf(int raw) => signExtension?.call(raw) ?? raw;

  // int decode(int raw) => signedOf(raw);
  // int encode(int value) => value.clamp(range.min, range.max);
}

final class BoolFormat extends BinaryFormat<Bool, bool> {
  const BoolFormat();
  bool decode(int raw) => raw != 0;
  int encode(bool value) => value ? 1 : 0;
}

// sign as int. alternatively map to EnumOffset
final class SignFormat extends BinaryFormat<Int, int> {
  const SignFormat([List<Enum>? ids]);
  get binaryRange => (min: -1, max: 1);
  int decode(int raw) => raw.toSigned(8); // extend from
  int encode(int value) => value.isNegative ? -1 : 1;
}

// sign extension size Int32
class EnumFormat<V extends Enum> extends BinaryFormat<Int, V> with EnumCodecByIndex<V> {
  const EnumFormat(this.values);
  final List<V> values;
  get binaryRange => (min: 0, max: values.length - 1);
}

// when without specifying base, extend at byte max value 127 for now
class EnumOffsetFormat<V extends Enum> extends EnumFormat<V> with EnumCodecByOffset<V> {
  const EnumOffsetFormat(super.values, this.zeroIndex);
  final int zeroIndex;
  get binaryRange => (min: 0 - zeroIndex, max: values.length - zeroIndex - 1);

  @override
  V decode(int raw) => values.byIndex(raw.toSigned(8) + zeroIndex);
  @override
  int encode(V view) => view.index - zeroIndex;
}

abstract class FractFormat<S extends NativeType> extends NumFormat<S, double> {
  const FractFormat();
  num get formatScalar;
  get valueRange => (min: binaryRange.min / formatScalar, max: binaryRange.max / formatScalar);
  double decode(int raw) => signedOf(raw) / formatScalar;
  int encode(double value) => (value * formatScalar).round().clamp(binaryRange.min, binaryRange.max);
}

abstract class IntFormat<S extends NativeType> extends NumFormat<S, int> {
  const IntFormat();
  get formatScalar => 1;
  int decode(int raw) => signedOf(raw);
  int encode(int value) => value.clamp(binaryRange.min, binaryRange.max);
}

///
abstract class FixedPoint<S extends NativeType> extends FractFormat<S> {
  const FixedPoint();
  int get fractBits;
  num get formatScalar => (1 << fractBits);
}

abstract class ScalarBase10<S extends NativeType> extends FractFormat<S> {
  const ScalarBase10();
  num get formatScalar;
}

// or FixedPoint
abstract class _Angle16 extends FractFormat<Uint16> {
  const _Angle16();
  double get fullScale;
  num get formatScalar => 65536;
  get valueRange => (min: 0.0, max: fullScale);
  double decode(int raw) => raw * fullScale / formatScalar;
  int encode(double value) => ((value % fullScale) * formatScalar ~/ fullScale);
}

// Concrete fixed-point

final class Fract16 extends FixedPoint<Int16> {
  const Fract16();
  get fractBits => 15;
}

final class Ufract16 extends FixedPoint<Uint16> {
  const Ufract16();
  get fractBits => 15;
}

final class Accum16 extends FixedPoint<Int16> {
  const Accum16();
  get fractBits => 7;
}

final class Uaccum16 extends FixedPoint<Uint16> {
  const Uaccum16();
  get fractBits => 7;
}

/// [0, 65535] -> [0.0, 1.0]
final class Percent16 extends FixedPoint<Uint16> {
  const Percent16();
  get fractBits => 16;
}

/// [0, 65536] -> [0.0, 1)
final class Angle16 extends _Angle16 {
  const Angle16();
  get fullScale => 1.0;
}

/// [0, 65536] -> [0.0, 360.0)
final class Angle16Deg extends _Angle16 {
  const Angle16Deg();
  get fullScale => 360.0;
}

/// [0, 65536] -> [0.0, 2π)
final class Angle16Rad extends _Angle16 {
  const Angle16Rad();
  get fullScale => 6.283185307179586;
}

/// alternatively as int
/// Scalar base-10
final class Scalar10 extends ScalarBase10<Int16> {
  const Scalar10();
  get formatScalar => 10;
}

// fract for now. alternative as int
final class ScalarInv10 extends ScalarBase10<Int16> {
  const ScalarInv10();
  get formatScalar => 0.1;
}

final class Scalar100 extends ScalarBase10<Int16> {
  const Scalar100();
  get formatScalar => 100;
}

/// Raw integer pass-through
final class Int16Int extends IntFormat<Int16> {
  const Int16Int();
}

final class Uint16Int extends IntFormat<Uint16> {
  const Uint16Int();
}

final class Int8Int extends IntFormat<Int8> {
  const Int8Int();
}

final class Uint8Int extends IntFormat<Uint8> {
  const Uint8Int();
}

final class Int32Int extends IntFormat<Int32> {
  const Int32Int();
}

final class Uint32Int extends IntFormat<Uint32> {
  const Uint32Int();
}

/// User-defined fractBits, unsigned
final class Ufixed16 extends FixedPoint<Uint16> {
  const Ufixed16(this.fractBits);
  final int fractBits;
}

/// User-defined fractBits, signed
final class Fixed16 extends FixedPoint<Int16> {
  const Fixed16(this.fractBits);
  final int fractBits;
}

// final class FixedPointFormat<S extends NativeType> extends NumFormat<S, double> with FixedPoint<S> {
//   const FixedPointFormat(this.fractBits);
//   final int fractBits;
// }
// todo special types
// enum signed

/// marker for special handling closing the sealed hierarchy, simplifies caller defs
class Adcu extends NumFormat<Uint16, double> {
  const Adcu();
  ({int max, int min}) get binaryRange => (min: 0, max: 4095);

  double decode(int raw) => raw.toDouble();
  int encode(double value) => value.toInt();

  num get formatScalar => 0;
}

// base type is sufficient for iteration
class BitStructFormat<K extends BitField> extends BinaryFormat<Int, BitStruct<K>> {
  const BitStructFormat(this.fields);
  final List<K> fields;
  get binaryRange => (min: 0, max: 2 ^ fields.totalWidth);
  BitStruct<K> decode(int raw) => BitStruct.view(fields, raw as Bits);
  int encode(BitStruct<K> value) => value.value;
}

// class StructFormat<K extends Field> extends BinaryFormat<Struct, Structure<K>> {
//   const StructFormat(this.fields);
//   final List<K> fields;
//   get baseRange => (min: 0, max: fields.totalWidth);
//   Structure<K>  decode(ByteData raw) => BitStruct.view(fields, raw as Bits);
//   int encode(BitStruct<K> value) => value.value;
// }

// return subtype with constructor
// abstract class BitStructFormat<T extends BitStruct<K >, K extends BitField> extends BinaryFormat<Int, T> {
//   const BitStructFormat();
//   List<T> get fields;
//   get baseRange => (min: 0, max: fields.totalWidth);
//   T decode(int raw) =>  Bits.ofPairs(fields.bitmasks.map((e) => MapEntry(e, (raw & e.mask) >> e.shift)));
//   int encode(T value) =>
// }

// Registry
abstract final class BinaryFormats {
  static const fract16 = Fract16();
  static const ufract16 = Ufract16();
  static const accum16 = Accum16();
  static const uaccum16 = Uaccum16();
  static const percent16 = Percent16();
  static const angle16 = Angle16();
  static const angle16Deg = Angle16Deg();
  static const angle16Rad = Angle16Rad();
  static const scalar10 = Scalar10();
  static const scalar100 = Scalar100();
  static const scalarInv10 = ScalarInv10();
  static const int16 = Int16Int();
  static const uint16 = Uint16Int();
  static const int8 = Int8Int();
  static const uint8 = Uint8Int();
  static const int32 = Int32Int();
  static const uint32 = Uint32Int();
  static const boolean = BoolFormat();
  static const sign = SignFormat();

  static const values = <BinaryFormat>[
    fract16,
    ufract16,
    accum16,
    uaccum16,
    percent16,
    angle16,
    angle16Rad,
    scalar10,
    scalar100,
    scalarInv10,
    int16,
    uint16,
    int8,
    uint8,
    int32,
    uint32,
    boolean,
    sign,
  ];
}

// class BinaryCodec<S extends NativeType, V extends Object> {
//   const BinaryCodec(this.format, {this.endian = Endian.little});

//   final BinaryFormat<S, V> format;
//   final Endian endian;

//   int get byteWidth => format.byteWidth;

//   /// Read raw int from [bytes] at [offset]
//   int readRaw(ByteData bytes, int offset) => switch (byteWidth) {
//         1 => format.isSigned ? bytes.getInt8(offset)   : bytes.getUint8(offset),
//         2 => format.isSigned ? bytes.getInt16(offset, endian) : bytes.getUint16(offset, endian),
//         4 => format.isSigned ? bytes.getInt32(offset, endian) : bytes.getUint32(offset, endian),
//         _ => throw UnsupportedError('Unsupported byteWidth: $byteWidth'),
//       };

//   /// Write raw int to [bytes] at [offset]
//   void writeRaw(ByteData bytes, int offset, int raw) => switch (byteWidth) {
//         1 => format.isSigned ? bytes.setInt8(offset, raw)   : bytes.setUint8(offset, raw),
//         2 => format.isSigned ? bytes.setInt16(offset, endian: endian, raw) : bytes.setUint16(offset, raw, endian),
//         4 => format.isSigned ? bytes.setInt32(offset, raw, endian) : bytes.setUint32(offset, raw, endian),
//         _ => throw UnsupportedError('Unsupported byteWidth: $byteWidth'),
//       };

//   /// Decode value from [bytes] at [offset]
//   V read(ByteData bytes, int offset) => format.decode(readRaw(bytes, offset));

//   /// Encode value to [bytes] at [offset]
//   void write(ByteData bytes, int offset, V value) => writeRaw(bytes, offset, format.encode(value));

//   /// Decode from a flat byte list at field [index] (stride = byteWidth)
//   V readAt(ByteData bytes, int index) => read(bytes, index * byteWidth);

//   /// Encode to a flat byte list at field [index] (stride = byteWidth)
//   void writeAt(ByteData bytes, int index, V value) => write(bytes, index * byteWidth, value);

//   /// Decode all values from [bytes] (full buffer)
//   List<V> readAll(ByteData bytes) => [
//         for (var i = 0; i < bytes.lengthInBytes ~/ byteWidth; i++) readAt(bytes, i),
//       ];

//   /// Encode all [values] into a new [ByteData]
//   ByteData encodeAll(List<V> values) {
//     final bytes = ByteData(values.length * byteWidth);
//     for (var i = 0; i < values.length; i++) writeAt(bytes, i, values[i]);
//     return bytes;
//   }

//   /// Copy single value into a new [ByteData]
//   ByteData encodeSingle(V value) => encodeAll([value]);

//   /// Decode single value from the start of [bytes]
//   V decodeSingle(ByteData bytes) => read(bytes, 0);

//   @override
//   String toString() => 'BinaryCodec<${format.runtimeType}>(endian: $endian)';
// }
// abstract class _BoolFormat extends BinaryFormat<Bool, bool> {
//   const _BoolFormat();
//   get baseRange => (min: 0, max: 1);
//   bool decode(int raw) => raw != 0;
//   int encode(bool value) => value ? 1 : 0;
// }

// abstract class _SignFormat extends BinaryFormat<Int, int> {
//   const _SignFormat();
//   get baseRange => (min: -1, max: 1);
//   int decode(int raw) => raw.toSigned(8);
//   int encode(int value) => value.isNegative ? -1 : 1;
// }

// abstract class _EnumFormat<V extends Enum> extends BinaryFormat<Int, V> {
//   const _EnumFormat();
//   List<V> get values;
//   get baseRange => (min: 0, max: values.length - 1);
//   V decode(int raw) => values[raw.clamp(baseRange.min, baseRange.max)];
//   int encode(V value) => value.index;
// }

/// NumFormat Mixins
// mixin FractFormat<S extends NativeType> on NumFormat<S, double> {
//   num get reference;
//   get valueRange => (min: baseRange.min / reference, max: baseRange.max / reference);
//   double decode(int raw) => signedOf(raw) / reference;
//   int encode(double value) => (value * reference).round().clamp(baseRange.min, baseRange.max);
// }
// mixin IntFormat<S extends NativeType> on NumFormat<S, int> {
//   get reference => 1;
//   int decode(int raw) => signedOf(raw);
//   int encode(int value) => value.clamp(baseRange.min, baseRange.max);
// }

// mixin FixedPoint<S extends NativeType> on FractFormat<S> {
//   int get fractBits;
//   num get reference => (1 << fractBits);
// }

// mixin ScalarBase10<S extends NativeType> on FractFormat<S> {
//   num get reference;
// }

// mixin _Angle16 on NumFormat<Uint16, double> {
//   double get fullScale;
//   num get reference => 65536;
//   get valueRange => (min: 0.0, max: fullScale);
//   double decode(int raw) => raw * fullScale / reference;
//   int encode(double value) => ((value % fullScale) * reference ~/ fullScale);
// }
