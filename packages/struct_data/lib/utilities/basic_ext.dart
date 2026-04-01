extension NullableOps<T extends Object?> on T? {
  /// Executes the given function if the value is non-null.
  /// Analogous to synchronous Future.then
  ///
  /// This method allows you to perform an operation on a value only if it is non-null.
  ///
  /// Example:
  /// ```dart
  /// int? value = 42;
  /// value.ifNonNull((v) => print(v)); // Prints: 42
  /// ```
  ///
  R? ifNonNull<R>(R Function(T) fn, [R Function()? onNull]) => switch (this) {
    T value => fn(value),
    null => onNull?.call(),
  };
  R? ifNull<R>(R Function() fn) => (this == null) ? fn() : null;

  bool isAnd(bool Function(T) test) => switch (this) {
    T value => test(value),
    null => false,
  };
}

extension ObjectOps<T extends Object> on T {
  // obj.passTo(fn) returns the result of fn
  // obj..passTo(fn) returns obj
  R? chain<R>(R? Function(T) fn) => fn(this);

  T? acceptIf(bool Function(T) test) => test(this) ? this : null;
  T? reject(bool Function(T) test) => test(this) ? null : this;
}

extension StringTrimming on String {
  String trimNulls() => replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  String keepNonNulls() => replaceAll(String.fromCharCode(0), '');
  String keepAlphaNumeric() => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}
