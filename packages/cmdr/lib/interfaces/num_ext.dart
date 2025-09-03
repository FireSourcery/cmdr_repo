import 'dart:convert';

///

typedef NumConverter = num Function(num);
typedef NumConversion = ({NumConverter decode, NumConverter encode});
typedef NumLimits = ({num min, num max});
typedef NumericLimits<T extends num> = ({T min, T max});

extension NumLimitsOperator on NumLimits {
  NumLimits operator *(num factor) => (min: min * factor, max: max * factor);

  num clamp(num value) => value.clamp(min, max);

  ({double min, double max}) looseToDouble() => (min: min.floorToDouble(), max: max.ceilToDouble());
  ({double min, double max}) tightToDouble() => (min: min.ceilToDouble(), max: max.floorToDouble());

  ({double min, double max}) floorCeilToDouble() => (min: min.floorToDouble(), max: max.ceilToDouble());
  ({double min, double max}) scaleToDouble(num factor) => (this * factor).floorCeilToDouble();
}

// extension NumLimitsClamp on NumLimits? {
//   num clamp(num value) => (this != null) ? value.clamp(this!.min, this!.max) : value;
// }

extension NumTo on num {
  R to<R extends num>() =>
      switch (R) {
            const (int) => toInt(),
            const (double) => toDouble(),
            const (num) || _ => this,
          }
          as R;
}

/// LinearConversion Factory
extension type const LinearConversion(num coefficient) {
  num of(num x) => (x * coefficient);
  num invOf(num y) => (y / coefficient);

  NumConversion? get conversion {
    return switch (coefficient) {
      1 => null, // no conversion
      0 => null, // no conversion
      num(isFinite: false) => null, // no conversion
      _ => (decode: of, encode: invOf),
    };
  }

  // NumConverter? get conversion => (coefficient.isFinite) ? of : null;
  // NumConverter? get invConversion => (coefficient.isFinite && coefficient != 0) ? invOf : null;

  num _viewOf(num dataValue) => (dataValue * coefficient);
  int _dataOf(num viewValue) => (viewValue ~/ coefficient);

  NumConversion? get dataConversion {
    return switch (coefficient) {
      1 => null, // no conversion
      0 => null, // no conversion
      num(isFinite: false) => null, // no conversion
      _ => (decode: _viewOf, encode: _dataOf),
    };
  }
}

// abstract mixin class NumCodec {
//   const NumCodec._();

//   ({num min, num max})? get numLimits;

//   num decode(covariant num data);
//   num encode(covariant num view);
// }

// class NumUnion <V> {
//   BinaryCodecBuilder({required this.decoder, required this.encoder});

//   // V decode(int data) => decoder(data);
//   // int encode(V view) => encoder(view);

//   // Limits as the values the num can take, inclusive, compare with >= and <=
//   ({num min, num max})? numLimits; // must be null for non-num types
//   List<Enum>? enumRange; // EnumSubtype.values must be non-null for Enum types
//   List<BitField>? bitsKeys;
// }
