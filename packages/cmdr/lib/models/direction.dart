abstract interface class Sign {
  /// Returns the sign of the value.
  /// -1 for negative, 0 for zero, 1 for positive.
  factory Sign.of(int value) = _Sign.of;

  /// Returns the sign of the value.
  int get value;

  // /// Returns true if the sign is negative.
  // bool get isNegative;

  // /// Returns true if the sign is zero.
  // bool get isZero;

  // /// Returns true if the sign is positive.
  // bool get isPositive;
}

// extension on Sign {
//   // R asSign<R extends Sign>() {
//   //   return switch (value) {
//   //     -1 => _Sign.positive as R,
//   //     0 => _Sign.zero as R,
//   //     1 => _Sign.negative as R,
//   //     _ => throw ArgumentError('Invalid sign: $this'),
//   //   };
//   // }
// }

enum _Sign implements Sign {
  negative(-1),
  zero(0),
  positive(1);

  const _Sign(this.value);
  final int value;

  factory _Sign.of(int value) {
    return switch (value.sign) {
      -1 => negative,
      0 => zero,
      1 => positive,
      _ => throw ArgumentError('Invalid sign: $value'),
    };
  }
}

/// enums for alternative labels
enum Direction implements Sign {
  reverse(-1),
  stop(0),
  forward(1);

  const Direction(this.value);
  final int value;

  factory Direction.from(int value) => Direction.of(value.sign);

  factory Direction.of(int sign) {
    return switch (sign) {
      -1 => reverse,
      0 => stop,
      1 => forward,
      _ => throw ArgumentError('Invalid direction sign: $sign'),
    };
  }
}

enum RotaryDirection implements Sign {
  stop,
  cw,
  ccw;

  factory RotaryDirection.of(int value) {
    return switch (value.sign) {
      -1 => cw,
      0 => stop,
      1 => ccw,
      _ => throw StateError('Invalid Direction value: $value'),
    };
  }

  int get value => switch (this) {
    stop => 0,
    cw => -1,
    ccw => 1,
  };
}
