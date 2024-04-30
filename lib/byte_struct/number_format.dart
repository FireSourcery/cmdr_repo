import 'dart:ffi';

import 'package:flutter/foundation.dart';

/// Data/number format
/// ffi marker constrains type, only use as marker
enum NumberFormat<T extends NativeType, S> {
  /// Q fraction types, view = rawValue * unitsRef/FormatRef
  frac16<Int16, double>(reference: 32767), // Q1.15
  ufrac16<Uint16, double>(reference: 32767), // frac16 abs with 2x over-saturation
  fixed16<Int16, double>(reference: 256), // 256 since base exceeds 8-bits
  scalar16<Uint16, double>(reference: 65535), // Q0.16
  // fixed32(reference: 32768, baseType: Int32 ),
  // int32(reference: Int32, baseType: Int32 ),

  ///
  invScalar10<Uint16, int>(reference: 1 / 10), // view = motValue*10
  scalar10<Uint16, int>(reference: 10), // view = motValue/10
  // scalar100(reference: 100), // view = motValue/10
  // scalar1000(reference: 1000), // view = motValue/10

  /// integer types, transmitted as int or truncated value
  int16<Int16, int>(reference: 1),
  uint16<Uint16, int>(reference: 1),

  /// non standard/const formats
  /// 0 or null, no conversion
  flags16<Uint16, BitField>(reference: null),
  enum16<Uint16, Enum>(reference: null),
  boolean<Bool, bool>(reference: null),

  /// not a number format but a value relative to the client platform,
  /// special conversion via function or mapped value
  adcu<Uint16, double>(reference: null), // may be adcu literal or case for special conversion
  cycles<Uint16, int>(reference: null), // cycles per second
  ;

  const NumberFormat({required this.reference});
  final num? reference; // conversion divider

  Type get baseType => T;
  Type get viewType => S;

  (int, int) get minMax {
    return switch (T) {
      const (Uint16) => (0, 65535),
      const (Int16) => (-32768, 32767),
      const (Bool) => (0, 1),
      _ => throw Error(),
    };
  }

  int get min => minMax.$1;
  int get max => minMax.$2;

  bool get isSigned {
    return switch (T) {
      const (Uint16) => false,
      const (Int16) => true,
      const (Bool) => false,
      _ => throw Error(),
    };
  }

  int _signExtension16(int raw16) => raw16.toSigned(16);
  int Function(int bytes)? get signExtension => (isSigned) ? _signExtension16 : null;

  bool get isFixedPoint => switch (this) { frac16 || ufrac16 || fixed16 || scalar16 => true, _ => false };
  bool get isScalarBase10 => switch (this) { scalar10 || invScalar10 => true, _ => false };

  bool get isNumeric => switch (S) { const (int) || const (double) => true, _ => false };
  R callTyped<R>(R Function<G>() callback) => callback<S>();

  // bool get isInteger => switch (this) { int16 || uint16 => true, _ => false };
  // bool get isFraction => isFixedPoint || isScalar || (this == adcu || this == cycles);

  /// direct conversion
  // int signed(int raw16) => (isSigned) ? _signExtension16(raw16) : raw16;
  // double decimal(int bytes) => signed(bytes) / reference;
}

// typedef GenericFunction<R, A> = R Function<G>(A args);