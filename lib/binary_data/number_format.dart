import 'dart:ffi';

/// Data/number format
/// ffi marker constrains type, only use as marker
enum NumberFormat<S extends NativeType, V> {
  /// Fixed-point number formats
  /// Q fraction types, view = rawValue * unitsRef/FormatRef
  frac16<Int16, double>(reference: 32767), // Q1.15
  ufrac16<Uint16, double>(reference: 32768), // frac16 abs with 2x over-saturation
  fixed16<Int16, double>(reference: 256), // 256 since base exceeds 8-bits
  scalar16<Uint16, double>(reference: 65535), // Q0.16
  // fixed32(reference: 32768, baseType: Int32 ),
  // int32(reference: Int32, baseType: Int32 ),

  ///
  scalarInv10<Uint16, int>(reference: 1 / 10), // view = bytesValue*10
  scalar10<Uint16, double>(reference: 10), // view = bytesValue/10
  // scalar100(reference: 100),
  // scalar1000(reference: 1000),

  /// integer types, transmitted as int or truncated value
  int16<Int16, int>(reference: 1),
  uint16<Uint16, int>(reference: 1),

  /// Type formats
  /// non cont references
  /// 0 or null or 1, no conversion
  bitField16<Uint16, Map>(reference: null),
  enum16<Uint16, Enum>(reference: null),
  boolean<Bool, bool>(reference: null),

  /// not a number format but a value relative to the client platform.
  /// This way simplifies the unit conversion side label
  adcu<Uint16, double>(reference: null),
  ;

  const NumberFormat({required this.reference});
  final num? reference; // conversion divider

  Type get baseType => S;
  Type get viewType => V;

  (int, int) get minMax {
    return switch (S) {
      const (Uint16) => (0, 65535),
      const (Int16) => (-32768, 32767),
      const (Bool) => (0, 1),
      _ => throw Error(),
    };
  }

  int get min => minMax.$1;
  int get max => minMax.$2;

  bool get isSigned {
    return switch (S) {
      const (Uint16) => false,
      const (Int16) => true,
      const (Bool) => false,
      _ => throw Error(),
    };
  }

  int _signExtension16(int raw16) => raw16.toSigned(16);
  int _signExtension32(int raw32) => raw32.toSigned(32);

  int Function(int bytes)? get signExtension => (isSigned) ? _signExtension16 : null;

  bool get isFixedPoint => switch (this) { frac16 || ufrac16 || fixed16 || scalar16 => true, _ => false };
  bool get isScalarBase10 => switch (this) { scalar10 || scalarInv10 => true, _ => false };

  bool get isNumeric => switch (V) { const (int) || const (double) => true, _ => false }; // !isEnum && !isFlags && !isBoolean;

  R callTyped<R>(R Function<G>() callback) => callback<V>();

  // bool get isInteger => switch (this) { int16 || uint16 => true, _ => false };
  // bool get isFraction => isFixedPoint || isScalar || (this == adcu || this == cycles);

  /// direct conversion
  // int signed(int raw16) => (isSigned) ? _signExtension16(raw16) : raw16;
  // double decimal(int bytes) => signed(bytes) / reference;
}
