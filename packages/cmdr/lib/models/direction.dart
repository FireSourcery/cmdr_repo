enum Sign {
  negative(-1),
  zero(0),
  positive(1);

  const Sign(this.value);
  final int value;

  factory Sign.of(num value) {
    return switch (value.sign) {
      -1 => negative,
      0 => zero,
      1 => positive,
      _ => throw ArgumentError('Invalid sign: $value'),
    };
  }

  // zero,
  // positive,
  // negative,
  // ;

  // factory Sign.of(int value) {
  //   return switch (value.sign) {
  //     -1 => negative,
  //     0 => zero,
  //     1 => positive,
  //     _ => throw StateError('Invalid Direction value: $value'),
  //   };
  // }

  // int get value => switch (this) { zero => 0, negative => -1, positive => 1 };
}

enum Direction {
  reverse(-1),
  stop(0),
  forward(1);

  const Direction(this.value);
  final int value;

  factory Direction.fromSign(int sign) {
    return switch (sign) {
      -1 => reverse,
      0 => stop,
      1 => forward,
      _ => throw ArgumentError('Invalid direction sign: $sign'),
    };
  }
}


// or move to common
// enum RotaryDirection {
//   stop,
//   cw,
//   ccw,
//   ;

//   factory Direction.of(int value) {
//     return switch (value.sign) {
//       -1 => Direction.cw,
//       0 => Direction.stop,
//       1 => Direction.ccw,
//       _ => throw StateError('Invalid Direction value: $value'),
//     };
//   }

//   int get value => switch (this) { stop => 0, cw => -1, ccw => 1 };
// }