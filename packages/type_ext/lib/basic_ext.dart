// callIfNotNull
// extension CallOnNullAsNull on Function {
//   // callOnNullable
//   R? callOrNull<R>(Object? input, [R Function()? onNull]) => (input != null) ? this(input) : null;
// }

// existsThen, isThen
extension IsThen<T extends Object?> on T? {
  /// Executes the given function if the value is non-null.
  ///
  /// This method allows you to perform an operation on a value only if it is non-null.
  ///
  /// Example:
  /// ```dart
  /// int? value = 42;
  /// value.ifNonNull((v) => print(v)); // Prints: 42
  /// ```
  ///
  // analogous to synchronous Future.then
  R? ifNonNull<R>(R Function(T) fn, [R Function()? onNull]) => switch (this) { T value => fn(value), null => onNull?.call() };
  R? ifNull<R>(R Function() fn) => (this == null) ? fn() : null;

  R? isThen<R>(R Function(T) fn, [R Function()? onNull]) => switch (this) { T value => fn(value), null => onNull?.call() };
  bool isAnd(bool Function(T input) test) => switch (this) { T value => test(value), null => false };
}

extension NumTo on num {
  // R to<R extends num>() => switch (R) { const (int) => toInt(), const (double) => toDouble(), const (num) => this, _ => throw StateError(' ') } as R;
}

extension NumExt on num {
  double normalize(int max) => (this / max).clamp(-1.0, 1.0); // throw division by zero if max is 0, otherwise normalize to -1.0 to 1.0
  double percent(int max) => normalize(max) * 100;
}

extension TrimString on String {
  String trimNulls() => replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  String keepNonNulls() => replaceAll(String.fromCharCode(0), '');
  String keepAlphaNumeric() => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}

// extension IterableIntExtensions on Iterable<int> {
//   /// Match a sequence of integers in the iterable
//   int indexOfSequence(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));
// }

// extension ReverseMap<T> on Iterable<T> {
//   // Map<V, T> asMapWith<V>(V Function(T) mappedValueOf) {
//   Map<V, T> _asReverseMap<V>(V Function(T) mappedValueOf) {
//     return Map.unmodifiable(<V, T>{for (var value in this) mappedValueOf(value): value});
//   }

//   Map<V, T> asReverseMap<V>([V Function(T)? mappedValueOf]) {
//     if (mappedValueOf == null) {
//       return (this as List<T>).asMap();
//     } else {
//       return _asReverseMap(mappedValueOf);
//     }
//   }
// }
