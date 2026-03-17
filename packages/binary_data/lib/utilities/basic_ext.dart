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
  R? ifNonNull<R>(R Function(T) fn, [R Function()? onNull]) => switch (this) {
    T value => fn(value),
    null => onNull?.call(),
  };
  R? ifNull<R>(R Function() fn) => (this == null) ? fn() : null;

  R? isThen<R>(R Function(T) fn, [R Function()? onNull]) => switch (this) {
    T value => fn(value),
    null => onNull?.call(),
  };
  bool isAnd(bool Function(T input) test) => switch (this) {
    T value => test(value),
    null => false,
  };
}

extension TrimString on String {
  String trimNulls() => replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  String keepNonNulls() => replaceAll(String.fromCharCode(0), '');
  String keepAlphaNumeric() => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}
