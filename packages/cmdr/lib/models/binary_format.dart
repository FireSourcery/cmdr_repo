import 'dart:ffi';

import 'package:type_ext/basic_types.dart';

import 'package:binary_data/binary_data.dart';

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
  // fixed32(reference: 32768, baseType: Int32 ),
  // int32(reference: Int32, baseType: Int32 ),
  ///
  scalar10<Int16, double>(reference: 10), // view = Int16/10
  // scalar100(reference: 100),
  // scalar1000(reference: 1000),
  scalarInv10<Int16, int>(reference: 1 / 10), // view = Int16*10

  /// Integer types, transmitted as int or truncated value
  int16<Int16, int>(reference: 1),
  uint16<Uint16, int>(reference: 1),

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

  int _signExtension16(int raw16) => raw16.toSigned(16);
  int _signExtension32(int raw32) => raw32.toSigned(32);
  int _signExtension8(int raw32) => raw32.toSigned(8);

  int Function(int bytes)? get signExtension {
    return switch (S) {
      const (Int32) => _signExtension32,
      const (Int16) => _signExtension16,
      const (Int) when (this == sign) => _signExtension8, // extend from lowest bit possible
      _ => null,
    };
  }

  //const (double) when (this != adcu),  ref > 0
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

typedef ViewOfData = num Function(int data);
typedef DataOfView = int Function(num view);
typedef DataOfBytes = int Function(int bytes);

///
// signExtension/dataOfBytes optionally seperate from viewOfData
typedef BinaryConversionCodec = ({ViewOfData viewOfData, DataOfView dataOfView});

// Linear conversion between data and view
// const BinaryConversion({this.viewOfData, this.dataOfView})
extension type const BinaryConversion(num coefficient) {
  //   BinaryConversion.of(num coefficient)
  //       : viewOfData = BinaryConversion(coefficient).viewOfData,
  //         dataOfView = BinaryConversion(coefficient).dataOfView;

  BinaryConversion.unitRef(BinaryFormat format, num unitRef) : coefficient = unitRef / format.reference!;

  num viewOf(int dataValue) => (dataValue * coefficient);
  int dataOf(num viewValue) => (viewValue ~/ coefficient);

  ViewOfData? get viewOfData => (coefficient.isFinite) ? viewOf : null;
  DataOfView? get dataOfView => (coefficient.isFinite && coefficient != 0) ? dataOf : null;

  BinaryConversionCodec? get codec {
    return switch (coefficient) {
      1 => null, // no conversion
      0 => null, // no conversion
      num(isFinite: false) => null, // no conversion
      _ => (viewOfData: viewOf, dataOfView: dataOf),
    };
  }
}
