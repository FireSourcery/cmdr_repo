import 'dart:convert';
import 'dart:ffi';

import 'package:type_ext/basic_types.dart';

import 'bits.dart';

/// Data/number format
/// ffi marker constrains type, only use as marker
enum BinaryFormat<S extends NativeType, V extends Object> {
  /// Fixed-point number formats
  /// Q fraction types, view = rawValue * unitsRef/FormatRef
  fract16<Int16, double>(reference: 32767), // Q1.15
  ufract16<Uint16, double>(reference: 32768), // frac16 abs with 2x over-saturation
  percent16<Uint16, double>(reference: 65535), // Q0.16
  ufixed16<Uint16, double>(reference: null),

  // fixed32(reference: 32768, baseType: Int32 ),
  // int32(reference: Int32, baseType: Int32 ),
  ///
  scalar10<Int16, double>(reference: 10), // view = bytesValue/10
  // scalar100(reference: 100),
  // scalar1000(reference: 1000),
  scalarInv10<Int16, int>(reference: 1 / 10), // view = bytesValue*10

  /// Integer types, transmitted as int or truncated value
  int16<Int16, int>(reference: 1),
  uint16<Uint16, int>(reference: 1),

  /// Not a number format but a value relative to the client platform.
  /// Included here as use case is similar and simplifies caller logic, such as unit conversion
  adcu<Uint16, double>(reference: null),

  /// Type formats, non-numerical
  /// Reference as null most directly conveys no conversion. 0 or 1 may execute unnecessary conversions
  boolean<Bool, bool>(reference: null),

  /// keyed types, has type dependencies
  bits16<Uint16, BitsBase>(reference: null),
  enum16<Uint16, Enum>(reference: null),
  never<Void, Never>(reference: null),
  ;

  const BinaryFormat({required this.reference});
  final num? reference; // value equal to 1, conversion divider

  // Type get baseType => S;
  // Type get viewType => V;

  TypeKey<S> get baseType => TypeKey<S>();
  TypeKey<V> get viewType => TypeKey<V>();

  R callTyped<R>(R Function<G>() callback) => callback<V>();

  // base limits
  (int, int) get minMax {
    return switch (S) {
      const (Uint16) => (0, 65535),
      const (Int16) => (-32768, 32767),
      const (Bool) => (0, 1),
      const (Void) => (0, 0),
      _ => throw StateError('Invalid type $S'),
    };
  }

  int get min => minMax.$1;
  int get max => minMax.$2;

  bool get isSigned {
    return switch (S) {
      const (Uint16) => false,
      const (Int16) => true,
      const (Bool) => false,
      const (Void) => false,
      _ => throw StateError('Invalid type $S'),
    };
  }

  int _signExtension16(int raw16) => raw16.toSigned(16);
  int _signExtension32(int raw32) => raw32.toSigned(32);

  int Function(int bytes)? get signExtension => (isSigned) ? _signExtension16 : null;

  bool get isFixedPoint => switch (this) { fract16 || ufract16 || ufixed16 || percent16 => true, _ => false };
  bool get isScalarBase10 => switch (this) { scalar10 || scalarInv10 => true, _ => false };

  // reference != null
  bool get isNumeric => switch (V) { const (int) || const (double) when (this != bits16) => true, _ => false }; // !isEnum && !isBits && !isBoolean;

  // bool get isInteger => switch (this) { int16 || uint16 => true, _ => false };
  // bool get isFraction => isFixedPoint || isScalar || (this == adcu || this == cycles);

  /// direct partial conversion
  // int signed(int raw16) => (isSigned) ? _signExtension16(raw16) : raw16;
  // double decimal(int bytes) => signed(bytes) / reference;
}

//numOfBinary, binaryOfNum
typedef ViewOfData = num Function(int data);
typedef DataOfView = int Function(num view);

// class ConversionPair {
//   const ConversionPair({
//     this.viewOfData,
//     this.dataOfView,
//   });

//   ConversionPair.linear(num coefficient)
//       : viewOfData = BinaryConversion(coefficient).viewOfData,
//         dataOfView = BinaryConversion(coefficient).dataOfView;

//   // num viewOf(int dataValue);
//   // int dataOf(num viewValue);

//   final ViewOfData? viewOfData;
//   final DataOfView? dataOfView;
//   // final Function(int bytes)? get signExtension
// }

extension type const BinaryConversion(num coefficient) {
  BinaryConversion.unitRef(BinaryFormat format, num unitRef) : coefficient = unitRef / format.reference!;

  num viewOf(int dataValue) => (dataValue * coefficient);
  int dataOf(num viewValue) => (viewValue ~/ coefficient);

  ViewOfData? get viewOfData => (coefficient.isFinite) ? viewOf : null;
  DataOfView? get dataOfView => (coefficient.isFinite && coefficient != 0) ? dataOf : null;
}

// Codec<num, int>
