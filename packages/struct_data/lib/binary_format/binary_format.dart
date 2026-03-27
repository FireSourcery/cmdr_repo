// ignore_for_file: annotate_overrides

import 'dart:ffi';
import 'dart:math';

import '../utilities/basic_types.dart';
import '../general/enum_types.dart';
import '../bits/bit_struct.dart';
import 'binary_codec.dart';

export 'binary_codec.dart';

/// [NativeTypeBase]
/// Descriptor using NativeType as marker only.
/// Handles size and signed
mixin class NativeTypeBase<S extends NativeType> {
  const NativeTypeBase();
  // static const NativeTypeFormat uint8 = NativeTypeFormat<Uint8>();

  ({int min, int max}) get range => switch (S) {
    const (Uint8) => (min: 0, max: 0xFF),
    const (Int8) => (min: -0x80, max: 0x7F),
    const (Uint16) => (min: 0, max: 0xFFFF),
    const (Int16) => (min: -0x8000, max: 0x7FFF),
    const (Uint32) => (min: 0, max: 0xFFFFFFFF),
    const (Int32) => (min: -0x80000000, max: 0x7FFFFFFF),
    const (Bool) => (min: 0, max: 1),
    const (Int) || const (NativeType) => (min: -0x80000000, max: 0x7FFFFFFF),
    _ => throw UnsupportedError('Unsupported type: $S'),
  };

  int clampBase(int raw) => raw.clamp(range.min, range.max);

  int get byteSize => switch (S) {
    const (Uint8) || const (Int8) => 1,
    const (Uint16) || const (Int16) => 2,
    const (Uint32) || const (Int32) => 4,
    const (Bool) => 1,
    _ => throw UnsupportedError('Unsupported type: $S'),
  };
  int get bitWidth => byteSize * 8;

  int _signExtend(int raw) => raw.toSigned(bitWidth);
  int mask(int raw) => raw & ((1 << bitWidth) - 1);

  bool get isSigned => range.min < 0;
  int Function(int)? get signExtension => isSigned ? _signExtend : null;

  int signedOf(int raw) => signExtension?.call(raw) ?? raw;

  // static const NativeTypeFormat<Uint8> uint8 = NativeTypeFormat<Uint8>();
}

/// Serialization and storage on base [int] type
/// V handle base value conversion
sealed class BinaryFormat<S extends NativeType, V> with NativeTypeBase<S> implements BinaryCodec<V> {
  const BinaryFormat();

  // NativeTypeFormat<S> get baseType => NativeTypeFormat<S>();
  TypeKey<V> get viewType => TypeKey<V>();

  ({int min, int max}) get binaryRange => range;

  int encode(V value);
  V decode(int raw);

  @override
  String toString() => 'BinaryFormat<${S.toString()}, ${V.toString()}>';
}

/// Hierarchy axis on handling
// BinaryFormat
//  ├─ NumFormat<S, V>          ← has signedness/width
//  │   ├─ IntFormat<S>         ← raw integer pass-through
//  │   └─ FractFormat<S>       ← fractional (reference-based)
//  │       ├─ FixedPoint<S>    ← reference = 2^n  (Q format)
//  │       ├─ ScalarBase10<S>  ← reference = 10^n
//  │       └─ Angle16          ← wrapping angular
//  ├─ BoolFormat
//  ├─ SignFormat
//  └─ EnumFormat<V>

/// Int/Fract
sealed class NumFormat<S extends NativeType, V extends num> extends BinaryFormat<S, V> {
  const NumFormat();
  ({num min, num max}) get valueRange => range;
  // num clampValue(num value) => value.clamp(valueRange.min, valueRange.max);
}

class IntFormat<S extends NativeType> extends NumFormat<S, int> {
  const IntFormat();
  int decode(int raw) => signedOf(raw);
  int encode(int value) => value.clamp(binaryRange.min, binaryRange.max);
}

// expand to Double and Float as needed
abstract class FractFormat<S extends NativeType> extends NumFormat<S, double> {
  const FractFormat();
  num get scalingFactor;
  get valueRange => (min: binaryRange.min / scalingFactor, max: binaryRange.max / scalingFactor);
  double decode(int raw) => signedOf(raw) / scalingFactor;
  int encode(double value) => (value * scalingFactor).truncate().clamp(binaryRange.min, binaryRange.max);
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

// class EnumFormat<S extends NativeType, V extends Enum> extends BinaryFormat<S, V> with EnumCodecByIndex<V> {
//   const EnumFormat(this.values);
//   final List<V> values;
//   get binaryRange => (min: 0, max: values.length - 1);
// }

// class EnumOffsetFormat<S extends NativeType, V extends Enum> extends EnumFormat<S, V> with EnumCodecByOffset<V> {
//   const EnumOffsetFormat(super.values, this.zeroIndex);
//   final int zeroIndex;
//   get binaryRange => (min: 0 - zeroIndex, max: values.length - zeroIndex - 1);
//   V decode(int data) => values.byIndex(signedOf(data) + zeroIndex);
//   int encode(V view) => (view.index - zeroIndex).clamp(binaryRange.min, binaryRange.max);
// }

// default index and offset handling
// sign extension, effectively ignored, size Int32
class EnumFormat<V extends Enum> extends BinaryFormat<Int, V> with EnumCodecByIndex<V> {
  const EnumFormat(this.values);
  final List<V> values;
  get binaryRange => (min: 0, max: values.length - 1);
}

// without specifying base, extend at byte max value 127 for now
class EnumOffsetFormat<V extends Enum> extends EnumFormat<V> with EnumCodecByOffset<V> {
  const EnumOffsetFormat(super.values, this.zeroIndex);
  final int zeroIndex;
  get binaryRange => (min: 0 - zeroIndex, max: values.length - zeroIndex - 1);
  V decode(int data) => values.byIndex(data.toSigned(8) + zeroIndex);
  int encode(V view) => (view.index - zeroIndex).clamp(binaryRange.min, binaryRange.max);
}

// for custom handling, separate from index-based. include list for view
class EnumFormatByHandlers<V extends Enum> extends EnumFormat<V> {
  const EnumFormatByHandlers(super.values, {required this.decoder, required this.encoder});

  final DataDecoder<V> decoder;
  final DataEncoder<V> encoder;

  V decode(int data) => decoder(data);
  int encode(V view) => encoder(view);
}

///
abstract class FixedPoint<S extends NativeType> extends FractFormat<S> {
  const FixedPoint();
  factory FixedPoint.nBits(int fractBits) = FixedPointN<S>;
  factory FixedPoint.base10(int decimal) = FixedPointBase10<S>;
  num get scalingFactor; // num scale 1.0
}

final class FixedPointN<S extends NativeType> extends FixedPoint<S> {
  const FixedPointN(this.fractBits);
  final int fractBits;
  num get scalingFactor => (1 << fractBits);
}

final class FixedPointBase10<S extends NativeType> extends FixedPoint<S> {
  const FixedPointBase10(this.decimalDigits);
  final int decimalDigits;
  num get scalingFactor => pow(10, decimalDigits);
}

/// base type is sufficient for iteration
class BitStructFormat<K extends BitField> extends BinaryFormat<Int, BitStruct<K>> {
  const BitStructFormat(this.fields);
  final List<K> fields;
  get binaryRange => (min: 0, max: (1 << BitForm(fields).totalWidth) - 1);
  BitStruct<K> decode(int raw) => BitForm(fields).cast(ConstBits(raw as Bits));
  int encode(BitStruct<K> value) => value.value;
}

/// marker for special handling closing the sealed hierarchy, simplifies caller defs
class Adcu extends NumFormat<Uint16, double> {
  const Adcu();

  get binaryRange => (min: 0, max: 4095);
  double decode(int raw) => raw.toDouble();
  int encode(double value) => value.toInt();
}

// Concrete fixed-point

final class Fract16 extends FixedPoint<Int16> {
  const Fract16();
  num get scalingFactor => (1 << 15);
}

final class Ufract16 extends FixedPoint<Uint16> {
  const Ufract16();
  num get scalingFactor => (1 << 15);
}

final class Accum16 extends FixedPoint<Int16> {
  const Accum16();
  num get scalingFactor => (1 << 7);
}

final class Uaccum16 extends FixedPoint<Uint16> {
  const Uaccum16();
  num get scalingFactor => (1 << 7);
}

final class Percent16 extends FixedPoint<Uint16> {
  const Percent16();
  num get scalingFactor => (1 << 16);
}

// or FixedPoint
/// [0, 65536] -> [0.0, 1)
final class Angle16 extends FractFormat<Uint16> {
  const Angle16();
  double get fullScale => 1.0;
  num get scalingFactor => 65536;
  get valueRange => (min: 0.0, max: fullScale);
  double decode(int raw) => raw * fullScale / scalingFactor;
  int encode(double value) => ((value % fullScale) * scalingFactor ~/ fullScale);
}

/// [0, 65536] -> [0.0, 360.0)
final class Angle16Deg extends Angle16 {
  const Angle16Deg();
  get fullScale => 360.0;
}

/// [0, 65536] -> [0.0, 2π)
final class Angle16Rad extends Angle16 {
  const Angle16Rad();
  get fullScale => 6.283185307179586;
}

/// 1 binary is .1f
final class Decimal10 extends FixedPoint<Int16> {
  const Decimal10();
  get scalingFactor => 10;
}

/// 1 binary is 10.0f
// fract for now. alternative as int Integer10
final class DecimalInv10 extends FixedPoint<Int16> {
  const DecimalInv10();
  get scalingFactor => 0.1;
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
final class Ufixed16 extends FixedPointN<Uint16> {
  const Ufixed16(super.fractBits);
}

/// User-defined fractBits, signed
final class Fixed16 extends FixedPointN<Int16> {
  const Fixed16(super.fractBits);
}
