///

/// [NumLimits]
typedef NumLimits = ({num min, num max});
typedef NumericLimits<T extends num> = ({T min, T max});

extension NumLimitsOperator on NumLimits {
  NumLimits operator *(num factor) => (min: min * factor, max: max * factor);
  NumLimits operator /(num factor) => (min: min / factor, max: max / factor);

  num clamp(num value) => value.clamp(min, max);

  ({double min, double max}) looseToDouble() => (min: min.floorToDouble(), max: max.ceilToDouble());
  ({double min, double max}) tightToDouble() => (min: min.ceilToDouble(), max: max.floorToDouble());

  ({double min, double max}) floorCeilToDouble() => (min: min.floorToDouble(), max: max.ceilToDouble());
  ({double min, double max}) scaleToDouble(num factor) => (this * factor).floorCeilToDouble();
}

extension NumTo on num {
  R to<R extends num>() =>
      switch (R) {
            const (int) => toInt(),
            const (double) => toDouble(),
            const (num) || _ => this,
          }
          as R;
}

/// [NumConversion]
typedef NumConverter = num Function(num);
typedef NumConversion = ({NumConverter decode, NumConverter encode});

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
}

///
extension NumExt on num {
  double normalize(int max) => (this / max).clamp(-1.0, 1.0); // throw division by zero if max is 0, otherwise normalize to -1.0 to 1.0
  double percent(int max) => normalize(max) * 100;
}
