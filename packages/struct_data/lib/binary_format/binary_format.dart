// ignore_for_file: annotate_overrides

import 'dart:ffi';
import 'dart:math';

import '../utilities/basic_types.dart';
import '../general/enum_types.dart';
import '../bits/bit_struct.dart';
import '../src/type_markers.dart';
import 'binary_codec.dart';

export 'binary_codec.dart';
export '../src/type_markers.dart';

/// [BinaryFormat<S, V>] defines `value` handling
/// type V to and from a binary representation as an [int],
/// It provides a declarative way to handle various data formats,
/// including integers, fixed-point numbers, booleans, signs, and enums,
/// with support for custom encoding/decoding logic through handlers.
/// [V] determines value conversion

/// Hierarchy axis on handling, rather than storage
/// `Base storage type can be "inherited" by typedef with type marker`
// BinaryFormat
//  ├─ NumFormat<S, V>          ← (num) has signedness/width
//  │   ├─ IntFormat<S>         ← (int) raw integer pass-through
//  │   └─ FractFormat<S>       ← (double) fractional (reference-based)
//  │       ├─ FixedPoint<S>    ← reference = 2^n  (Q format)
//  │       ├─ FixedBase10<S>   ← reference = 10^n
//  ├─ EnumFormat<V>
//  ├─ BoolFormat
//  ├─ SignFormat
//
//  return switch (_format) {
//   EnumFormat() =>
//   FractFormat() =>
//   IntFormat() =>
//   BoolFormat() =>
//   SignFormat() =>
//   BitStructFormat() =>
//   Adcu() =>
// }
sealed class const BinaryFormat<S extends NativeType, V>() with NativeTypeBase<S> implements BinaryCodec<V> {
  // NativeTypeBase<S> get baseType => NativeTypeBase<S>();
  TypeKey<V> get viewType => TypeKey<V>();

  int binaryOf(int raw) => signExtension?.call(raw) ?? raw;

  int encode(V value);
  V decode(int raw);

  @override
  String toString() => 'BinaryFormat<${S.toString()}, ${V.toString()}>';
}

/// [NativeTag] - `StorageType`. Descriptor using NativeType as marker only.
/// NativeType [S] determines the `size` and `signedness` of the underlying binary data.
/// if lets unspecified, defaults to 32-bit signed int (Int32).
mixin class const NativeTypeBase<S extends NativeType>() {
  ({int min, int max}) get binaryRange => switch (S) {
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

  int clampBase(int value) => value.clamp(binaryRange.min, binaryRange.max);

  int get byteSize => switch (S) {
    const (Uint8) || const (Int8) => 1,
    const (Uint16) || const (Int16) => 2,
    const (Uint32) || const (Int32) => 4,
    const (Bool) => 1,
    const (Int) || const (NativeType) => 4, // default to 32-bit for int and NativeType
    _ => throw UnsupportedError('Unsupported type: $S'),
  };
  int get bitWidth => byteSize * 8;

  int _signExtend(int raw) => raw.toSigned(bitWidth);
  // int mask(int raw) => raw & ((1 << bitWidth) - 1);

  bool get isSigned => binaryRange.min < 0;
  int Function(int)? get signExtension => isSigned ? _signExtend : null;
  int signedOf(int raw) => signExtension?.call(raw) ?? raw;
}

/// Int/Fract
sealed class const NumFormat<S extends NativeType, V extends num>() extends BinaryFormat<S, V> {
  ({num min, num max}) get valueRange => binaryRange;
  num clampValue(num value) => value.clamp(valueRange.min, valueRange.max);
}

class const IntFormat<S extends NativeType>() extends NumFormat<S, int> {
  int decode(int raw) => signedOf(raw);
  int encode(int value) => value.clamp(binaryRange.min, binaryRange.max);
  get valueRange => binaryRange;
}

// expand to Double and Float as needed
abstract class const FractFormat<S extends NativeType>() extends NumFormat<S, double>;

final class const BoolFormat() extends BinaryFormat<Bool, bool> {
  bool decode(int raw) => raw != 0;
  int encode(bool value) => value ? 1 : 0;
}

// sign as int. alternatively map to EnumOffset
final class const SignFormat() extends BinaryFormat<Int, int> {
  get binaryRange => (min: -1, max: 1);
  int decode(int raw) => raw.toSigned(8); // extend from 1 byte, effectively -1, 0, 1
  int encode(int value) => value.isNegative ? -1 : 1; // stores as 64-bit truncated
}

// default index and offset handling
// sign extension, effectively ignored, size Int32
class const EnumFormat<S extends NativeType, V extends Enum>(final List<V> values) extends BinaryFormat<S, V> with EnumCodecByIndex<V> {
  get binaryRange => (min: 0, max: values.length - 1); // treated as unsigned
}

// Signed format must specify storage type S
// throws when S is undefined, infered as [NativeType].
class const EnumOffsetFormat<S extends NativeType, V extends Enum>(super.values, final int zeroIndex) extends EnumFormat<S, V> with EnumCodecByOffset<V> {
  this : assert(S != NativeType, 'Must specify storage type S for EnumOffsetFormat');
  get binaryRange => (min: 0 - zeroIndex, max: values.length - zeroIndex - 1);
  V decode(int data) => values.byIndex(signedOf(data) + zeroIndex);
  int encode(V view) => (view.index - zeroIndex).clamp(binaryRange.min, binaryRange.max);
}

typedef EnumUint<V extends Enum> = EnumFormat<NativeType, V>;
typedef EnumInt8<V extends Enum> = EnumOffsetFormat<Int8, V>;
typedef EnumInt16<V extends Enum> = EnumOffsetFormat<Int16, V>;
typedef EnumInt32<V extends Enum> = EnumOffsetFormat<Int32, V>;

/// for custom handling, separate from index-based. include list for view
class const EnumFormatByHandlers<V extends Enum>(
  super.values, {
  required final DataDecoder<V> decoder,
  required final DataEncoder<V> encoder,
}) extends EnumFormat<Int, V> {
  V decode(int data) => decoder(data);
  int encode(V view) => encoder(view);
}

abstract class const FixedPoint<S extends NativeType>() extends FractFormat<S> {
  // ergonomic const def
  // FixedPoint<Int16>.n(15)
  const factory FixedPoint.n(int fractBits) = FixedPointN<S>;
  // FixedPoint<Int16>.d(2) scaling factor 100
  // FixedPoint<Int16>.da(2) scaling factor 1/100
  const factory FixedPoint.d(int decimal) = FixedPointBase10<S>;
  num get scalingFactor;
  get valueRange => (min: binaryRange.min / scalingFactor, max: binaryRange.max / scalingFactor);
  double decode(int raw) => signedOf(raw) / scalingFactor;
  int encode(double value) => (value * scalingFactor).round().clamp(binaryRange.min, binaryRange.max);
}

// define with parameter
final class const FixedPointN<S extends NativeType>(final int fractBits) extends FixedPoint<S> {
  num get scalingFactor => (1 << fractBits);
}

final class const FixedPointBase10<S extends NativeType>(final int decimalDigits) extends FixedPoint<S> {
  num get scalingFactor => pow(10, decimalDigits);
}

// final class FloatingPoint  extends FractFormat<Float> {
//   const FloatingPoint();
//   get valueRange => (min: double.negativeInfinity, max: double.infinity);
//   double decode(int raw) =>
//   int encode(double value) =>
// }

// base type is sufficient for iteration
class const BitStructFormat<K extends BitField>(final List<K> fields) extends BinaryFormat<Int, BitStruct<K>> {
  get binaryRange => (min: 0, max: (1 << BitForm(fields).totalWidth) - 1);
  BitStruct<K> decode(int raw) => BitForm(fields).cast(ConstBits(raw as Bits));
  int encode(BitStruct<K> value) => value.value;
}

/// Marker for special handling, closing the sealed hierarchy.
// or move as a part of Quantity codec
class const Adcu() extends NumFormat<Uint16, double> {
  get binaryRange => (min: 0, max: 4095);
  double decode(int raw) => raw.toDouble();
  int encode(double value) => value.toInt();
}

// binary_formats.dart
// Concrete definitions for common formats.
final class const Fract16() extends FixedPoint<Int16> {
  num get scalingFactor => (1 << 15);
}

final class const Ufract16() extends FixedPoint<Uint16> {
  num get scalingFactor => (1 << 15);
}

final class const Accum32() extends FixedPoint<Int32> {
  num get scalingFactor => (1 << 15);
}

final class const Uaccum32() extends FixedPoint<Uint32> {
  num get scalingFactor => (1 << 15);
}

final class const Accum16() extends FixedPoint<Int16> {
  num get scalingFactor => (1 << 7);
}

final class const Uaccum16() extends FixedPoint<Uint16> {
  num get scalingFactor => (1 << 7);
}

// Sat16
final class const Percent16() extends FixedPoint<Uint16> {
  num get scalingFactor => (1 << 16);
}

// Wrap16
final class const _Angle16<S extends NativeType>() extends FractFormat<S> {
  double get fullScale => 1.0;
  num get scalingFactor => 65536;
  get valueRange => (min: 0.0, max: fullScale);
  double decode(int raw) => signedOf(raw) * fullScale / scalingFactor;
  int encode(double value) => ((value % fullScale) * scalingFactor ~/ fullScale);
}

// or FixedPoint
/// [0, 65536] -> [0.0, 1)
typedef SAngle16 = _Angle16<Int16>;
typedef UAngle16 = _Angle16<Uint16>;
typedef Angle16 = _Angle16<Uint16>;

/// [0, 65536] -> [0.0, 360.0)
final class const Angle16Deg() extends Angle16 {
  get fullScale => 360.0;
}

/// [0, 65536] -> [0.0, 2π)
final class const Angle16Rad() extends Angle16 {
  get fullScale => 6.283185307179586;
}

/// 1 binary -> 0.1f
final class const Decimal10<S extends NativeType>() extends FixedPoint<S> {
  get scalingFactor => 10;
}

final class const Decimal100<S extends NativeType>() extends FixedPoint<S> {
  get scalingFactor => 100;
}

/// 1 binary -> 10.0f
// fract for now. alternative as int Integer10
final class const DecimalInv10<S extends NativeType>() extends FixedPoint<S> {
  get scalingFactor => 0.1;
}

/// Raw integer pass-through
// typedef Integer16 = IntFormat<Int16>;
// typedef Integer16U = IntFormat<Uint16>;

final class const Int16Int() extends IntFormat<Int16>;

final class const Uint16Int() extends IntFormat<Uint16>;

final class const Int8Int() extends IntFormat<Int8>;

final class const Uint8Int() extends IntFormat<Uint8>;

final class const Int32Int() extends IntFormat<Int32>;

final class const Uint32Int() extends IntFormat<Uint32>;
