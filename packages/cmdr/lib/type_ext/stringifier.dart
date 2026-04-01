import 'package:flutter/foundation.dart';

/// [Stringifier]
typedef Stringifier<T> = String Function(T input);
typedef NullableStringifier<T> = String Function(T? input);
typedef GenericStringifier = String Function<T>(T input);
// typedef GenericStringifier = String Function<T>(T? input); // non-nullable type, with nullable input, cases where T is used for selection

/// Resolves a display string with fallback precedence.
/// valueStringGetter > valueStringifier > valueGetter().toString()
///
/// Implements [call] so it can be used directly as a [ValueGetter<String>].
class StringifierOf<T> {
  const StringifierOf(this.valueGetter, {this.valueStringGetter, this.valueStringifier, this.nullString = ''});

  final ValueGetter<T?> valueGetter;
  final ValueGetter<String>? valueStringGetter;
  final Stringifier<T>? valueStringifier;
  final String nullString;

  Stringifier<T> get effectiveStringifier => valueStringifier ?? _stringifyDefault;

  String call() => valueStringGetter?.call() ?? _stringifyValue();

  String _stringifyValue() {
    if (valueGetter() case T value) return effectiveStringifier(value);
    return nullString;
  }

  static String _stringifyDefault(Object? value) => value.toString();

  // Stringifier<T?> get _effectiveNullableStringifier {
  //   if (valueStringifier case Stringifier<T?> stringifier) stringifier;
  //   return _stringifyDefault;
  // }
}
