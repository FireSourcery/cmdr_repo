import 'basic_types.dart';

extension CallOnNullAsNull on Function {
  // callIfNotNull
  // R? callOrNull<T, R>(T? arg) => switch (arg) { T value => this(value), null => null };
  R? callOrNull<R>(Object? input, [R Function()? onNull]) => (input != null) ? this(input) : null;
}

// extension IsNotNullThen<T> on Object? { for T consistency check only?
extension IsNotNullThen on Object? {
  // analogous to synchronous Future.then
  //isSetThen
  R? isThen<T, R>(R Function(T value) fn) => switch (this as T?) { T value => fn(value), null => null };
  // R? isThen<R>(R Function(Object value) fn) => (this != null) ? fn(this!) : null;
  R? nullThen<R>(R Function() fn) => (this == null) ? fn() : null;
  bool isAnd<T>(ValueTest test) => switch (this as T?) { T value => test(value), null => false };
}

extension IsThen<T extends Object> on T? {
  /// Executes the given function if the value is non-null.
  ///
  /// This method allows you to perform an operation on a value only if it is non-null.
  ///
  /// Example:
  /// ```dart
  /// int? value = 42;
  /// value.ifNonNull((v) => print(v)); // Prints: 42
  /// ```
  // analogous to synchronous Future.then
  R? ifNonNull<R>(R Function(T) fn, [R Function()? onNull]) => switch (this) { T value => fn(value), null => null };
  R? ifNull<R>(R Function() fn) => (this == null) ? fn() : null;
  bool ifNonNullAnd(ValueTest test) => switch (this) { T value => test(value), null => false };
}

extension NumTo on num {
  R to<R extends num>() => switch (R) { const (int) => toInt(), const (double) => toDouble(), _ => throw TypeError() } as R;
}

extension IterableIntExtensions on Iterable<int> {
  /// Match a sequence of integers in the iterable
  int indexOfSequence(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));
}

extension TrimString on String {
  String trimNulls() => replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  String keepNonNulls() => replaceAll(String.fromCharCode(0), '');
  String keepAlphaNumeric() => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}

// extension MapPairs<K, V> on Iterable<MapEntry<K, V>> {
//   Iterable<(K, V)> asPairs() => map((e) => (e.key, e.value));
// }
