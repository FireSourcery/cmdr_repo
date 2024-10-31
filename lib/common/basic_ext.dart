import 'dart:collection';

import 'basic_types.dart';

extension CallOnNullAsNull on Function {
  // callIfNotNull
  R? callOrNull<T, R>(T? arg) => switch (arg) { T value => this(value), null => null };
}

extension IsNotNullThen on Object? {
  // analogous to synchronous Future.then
  R? isThen<T, R>(R Function(T value) fn) => switch (this as T?) { T value => fn(value), null => null };
  R? nullThen<R>(R Function() fn) => (this == null) ? fn() : null;
  bool isAnd<T>(ValueTest test) => switch (this as T?) { T value => test(value), null => false };
}

// extension type NumTo<R extends num>(num value) implements num {
//   // NumTo.parse(String string) : value = num.parse(string);
//   NumTo.parse(String string) : value = switch (R) { const (int) => int.parse(string), const (double) => double.parse(string), _ => throw TypeError() };
// }

// extension NumTo on num {
//   R to<R extends num>() => switch (R) { const (int) => toInt(), const (double) => toDouble(), _ => throw TypeError() } as R;
// }

extension MapPairs<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<(K, V)> asPairs() => map((e) => (e.key, e.value));
}

extension TrimString on String {
  // String trimLeft(String chars) => replaceAll(RegExp('^[$chars]+'), '');
  // String trimRight(String chars) => replaceAll(RegExp('[$chars]+\$'), '');

  String trimNulls() => replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  String keepNonNulls() => replaceAll(String.fromCharCode(0), '');
  String keepAlphaNumeric() => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}

extension IterableIntExtensions on Iterable<int> {
  /// Match
  int indexOfSequence(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));
}
