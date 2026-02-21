import 'dart:ffi';

import 'package:type_ext/basic_types.dart';

import 'package:binary_data/binary_data.dart';

sealed class BinaryFormat<S extends NativeType, V extends Object> {
  const BinaryFormat({required this.reference});
  // factory BinaryFormat.type()
  // {
  //   return switch (S, V) {
  //     (Uint16, double) => Fract16(),
  //     (Int16, double) => Accum16(),
  //     (Uint16, int) => UInt16AsInt(),
  //     (Int16, int) => Int16AsInt(),
  //     (Bool, bool) => BooleanFormat(),
  //     _ => throw UnimplementedError('No default BinaryFormat for types S=$S, V=$V. Please specify a format or add a default case.'),
  //   };
  // }

  final num? reference;

  // Common helpers (override as needed)
  ({int min, int max}) get baseRange;
  ({num min, num max}) get valueRange => (reference != null) ? (min: baseRange.min / reference!, max: baseRange.max / reference!) : (min: baseRange.min, max: baseRange.max);

  bool get isSigned;
  int Function(int bytes)? get signExtension => null;

  bool get isFixedPoint => false;
  bool get isScalarBase10 => false;

  // Numeric-ness (override for non-numeric variants)
  bool get isNumeric => true;

  TypeKey<S> get baseType => TypeKey<S>();
  TypeKey<V> get viewType => TypeKey<V>();
}

// Width/sign “base” classes to centralize baseRange/sign behaviors.

// abstract class NumberFormat<S ,V extends num> extends BinaryFormat<S, V> {}

abstract class Uint16Format<V extends num> extends BinaryFormat<Uint16, V> {
  const Uint16Format({required super.reference});
  @override
  ({int min, int max}) get baseRange => (min: 0, max: 65535);
  @override
  bool get isSigned => false;
}

abstract class Int16Format<V extends num> extends BinaryFormat<Int16, V> {
  const Int16Format({required super.reference});
  @override
  ({int min, int max}) get baseRange => (min: -32768, max: 32767);
  @override
  bool get isSigned => true;
  @override
  int Function(int bytes)? get signExtension => ((raw) => raw.toSigned(16));
}

abstract class BoolFormat extends BinaryFormat<Bool, bool> {
  const BoolFormat() : super(reference: null);
  @override
  ({int min, int max}) get baseRange => (min: 0, max: 1);
  @override
  bool get isSigned => false;
  @override
  bool get isNumeric => false;
}

mixin FixedPoint on BinaryFormat {
  int get fractBits;
  int get reference => 1 << fractBits; // 2^fractBits
  bool get isFixedPoint => true;
}

// Concrete variants

final class Fract16 extends Int16Format<double> {
  const Fract16() : super(reference: 32767);
  @override
  bool get isFixedPoint => true;
}

final class UFract16 extends Uint16Format<double> {
  const UFract16() : super(reference: 32768);
  @override
  bool get isFixedPoint => true;
}

final class UAccum16 extends Uint16Format<double> {
  const UAccum16() : super(reference: 128);
  @override
  bool get isFixedPoint => true;
}

final class Accum16 extends Int16Format<double> {
  const Accum16() : super(reference: 128);
  @override
  bool get isFixedPoint => true;
}

final class Percent16 extends Uint16Format<double> {
  const Percent16() : super(reference: 65535);
  @override
  bool get isFixedPoint => true;
}

final class Angle16 extends Uint16Format<double> {
  const Angle16() : super(reference: 65536);
  // marker for alternative sign handling if needed
  @override
  bool get isFixedPoint => true;
}

final class UFixed16 extends Uint16Format<double> {
  const UFixed16({required num reference}) : super(reference: reference);
  @override
  bool get isFixedPoint => true;
}

final class Scalar10 extends Int16Format<double> {
  const Scalar10() : super(reference: 10);
  @override
  bool get isScalarBase10 => true;
}

final class ScalarInv10 extends Int16Format<int> {
  const ScalarInv10() : super(reference: 1 / 10);
  @override
  bool get isScalarBase10 => true;
}

final class Int16AsInt extends Int16Format<int> {
  const Int16AsInt() : super(reference: 1);
}

final class UInt16AsInt extends Uint16Format<int> {
  const UInt16AsInt() : super(reference: 1);
}

final class BooleanFormat extends BoolFormat {
  const BooleanFormat();
  @override
  bool get isNumeric => false;
}

final class SignFlag extends BinaryFormat<Int, int> {
  const SignFlag() : super(reference: null);
  @override
  ({int min, int max}) get baseRange => (min: 0, max: 1);
  @override
  bool get isSigned => true;
  @override
  int Function(int bytes)? get signExtension =>
      (raw) => raw.toSigned(8);
  @override
  bool get isNumeric => false;
}

// Example registry to keep an enum-like values list and names.
// abstract final class Formats {
//   static const fract16 = Fract16();
//   static const ufract16 = UFract16();
//   static const uaccum16 = UAccum16();
//   static const accum16 = Accum16();
//   static const percent16 = Percent16();
//   static const angle16 = Angle16();
//   static const scalar10 = Scalar10();
//   static const scalarInv10 = ScalarInv10();
//   static const int16 = Int16AsInt();
//   static const uint16 = UInt16AsInt();
//   static const boolean = BooleanFormat();
//   static const sign = SignFlag();

//   static const values = <BinaryFormat<dynamic, Object>>[fract16, ufract16, uaccum16, accum16, percent16, angle16, scalar10, scalarInv10, int16, uint16, boolean, sign];
// }
