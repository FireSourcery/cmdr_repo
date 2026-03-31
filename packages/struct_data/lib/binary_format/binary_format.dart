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

/// [NativeTag] - `StorageType`. Descriptor using NativeType as marker only.
/// NativeType [S] determines the `size` and `signedness` of the underlying binary data.
/// if lets unspecified, defaults to 32-bit signed int (Int32).
mixin class NativeTypeBase<S extends NativeType> {
  const NativeTypeBase();

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
    const (Int) || const (NativeType) => 4, // default to 32-bit for int and NativeType
    _ => throw UnsupportedError('Unsupported type: $S'),
  };
  int get bitWidth => byteSize * 8;

  int _signExtend(int raw) => raw.toSigned(bitWidth);
  // int mask(int raw) => raw & ((1 << bitWidth) - 1);

  bool get isSigned => range.min < 0;
  int Function(int)? get signExtension => isSigned ? _signExtend : null;
  int signedOf(int raw) => signExtension?.call(raw) ?? raw;
}

/// Hierarchy axis on handling, rather than storage
/// Base sttorage type can be "inherited" by typedef with type marker
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

/// Int/Fract
sealed class NumFormat<S extends NativeType, V extends num> extends BinaryFormat<S, V> {
  const NumFormat();
  ({num min, num max}) get valueRange => binaryRange;
  // num clampValue(num value) => value.clamp(valueRange.min, valueRange.max);
}

class IntFormat<S extends NativeType> extends NumFormat<S, int> {
  const IntFormat();
  int decode(int raw) => signedOf(raw);
  int encode(int value) => value.clamp(binaryRange.min, binaryRange.max);
  get valueRange => binaryRange;
}

// expand to Double and Float as needed
abstract class FractFormat<S extends NativeType> extends NumFormat<S, double> {
  const FractFormat();
  num get scalingFactor;
  get valueRange => (min: binaryRange.min / scalingFactor, max: binaryRange.max / scalingFactor);
  double decode(int raw) => signedOf(raw) / scalingFactor;
  int encode(double value) => (value * scalingFactor).round().clamp(binaryRange.min, binaryRange.max);
}

final class BoolFormat extends BinaryFormat<Bool, bool> {
  const BoolFormat();
  bool decode(int raw) => raw != 0;
  int encode(bool value) => value ? 1 : 0;
}

// sign as int. alternatively map to EnumOffset
final class SignFormat extends BinaryFormat<Int, int> {
  const SignFormat();
  get binaryRange => (min: -1, max: 1);
  int decode(int raw) => raw.toSigned(8); // extend from 1 byte, effectively -1, 0, 1
  int encode(int value) => value.isNegative ? -1 : 1; // stores as 64-bit truncated
}

// default index and offset handling
// sign extension, effectively ignored, size Int32
class EnumFormat<S extends NativeType, V extends Enum> extends BinaryFormat<S, V> with EnumCodecByIndex<V> {
  const EnumFormat(this.values);
  final List<V> values;
  get binaryRange => (min: 0, max: values.length - 1); // treated as unsigned
}

// Signed format must specify storage type S
// throws when S is undefined, infered as [NativeType].
class EnumOffsetFormat<S extends NativeType, V extends Enum> extends EnumFormat<S, V> with EnumCodecByOffset<V> {
  const EnumOffsetFormat(super.values, this.zeroIndex) : assert(S != NativeType, 'Must specify storage type S for EnumOffsetFormat');
  final int zeroIndex;
  get binaryRange => (min: 0 - zeroIndex, max: values.length - zeroIndex - 1);
  V decode(int data) => values.byIndex(signedOf(data) + zeroIndex);
  int encode(V view) => (view.index - zeroIndex).clamp(binaryRange.min, binaryRange.max);
}

typedef EnumUint<V extends Enum> = EnumFormat<NativeType, V>;
typedef EnumInt8<V extends Enum> = EnumOffsetFormat<Int8, V>;
typedef EnumInt16<V extends Enum> = EnumOffsetFormat<Int16, V>;
typedef EnumInt32<V extends Enum> = EnumOffsetFormat<Int32, V>;

/// for custom handling, separate from index-based. include list for view
class EnumFormatByHandlers<V extends Enum> extends EnumFormat<Int, V> {
  const EnumFormatByHandlers(super.values, {required this.decoder, required this.encoder});

  final DataDecoder<V> decoder;
  final DataEncoder<V> encoder;

  V decode(int data) => decoder(data);
  int encode(V view) => encoder(view);
}

// add as needed abstract class FloatingPoint<S extends NativeType> extends FractFormat<S> {
abstract class FixedPoint<S extends NativeType> extends FractFormat<S> {
  const FixedPoint();
  // ergonomic const def
  // FixedPoint<Int16>.n(15)
  const factory FixedPoint.n(int fractBits) = FixedPointN<S>;
  const factory FixedPoint.base10(int decimal) = FixedPointBase10<S>;
  num get scalingFactor; // num scale 1.0
}

// define with parameter
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

// base type is sufficient for iteration
class BitStructFormat<K extends BitField> extends BinaryFormat<Int, BitStruct<K>> {
  const BitStructFormat(this.fields);
  final List<K> fields;
  get binaryRange => (min: 0, max: (1 << BitForm(fields).totalWidth) - 1);
  BitStruct<K> decode(int raw) => BitForm(fields).cast(ConstBits(raw as Bits));
  int encode(BitStruct<K> value) => value.value;
}

/// Marker for special handling, closing the sealed hierarchy.
// or move as a part of Quantity codec
class Adcu extends NumFormat<Uint16, double> {
  const Adcu();

  get binaryRange => (min: 0, max: 4095);
  double decode(int raw) => raw.toDouble();
  int encode(double value) => value.toInt();
}

// binary_formats.dart

// Concrete definitions for common formats.
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

final class SAngle16 extends FractFormat<Int16> {
  const SAngle16();
  double get fullScale => 1.0;
  num get scalingFactor => 65536;
  get valueRange => (min: -32768, max: 32767);
  double decode(int raw) => signedOf(raw) * fullScale / scalingFactor;
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

/// 1 binary -> 0.1f
final class Decimal10<S extends NativeType> extends FixedPoint<S> {
  const Decimal10();
  get scalingFactor => 10;
}

final class Decimal100<S extends NativeType> extends FixedPoint<S> {
  const Decimal100();
  get scalingFactor => 100;
}

/// 1 binary -> 10.0f
// fract for now. alternative as int Integer10
final class DecimalInv10<S extends NativeType> extends FixedPoint<S> {
  const DecimalInv10();
  get scalingFactor => 0.1;
}

/// Raw integer pass-through
typedef Integer16 = IntFormat<Int16>;
typedef Integer16U = IntFormat<Uint16>;

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
