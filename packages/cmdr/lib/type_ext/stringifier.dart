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
class StringGetter<T> {
  const StringGetter(this.valueGetter, {this.valueStringGetter, this.valueStringifier, this.nullString = ''});

  final ValueGetter<String>? valueStringGetter;
  final ValueGetter<T?> valueGetter;
  final Stringifier<T>? valueStringifier;
  final String nullString;

  String call() {
    final value = valueGetter();

    // User-supplied stringifier accepts null → defer entirely to it.
    if (valueStringifier case Stringifier<T?> nullable) return nullable(value);

    // Otherwise: only invoke the stringifier on a non-null value.
    if (value is T) return (valueStringifier ?? _stringifyDefault)(value);

    return nullString;
  }

  // String _stringifyValue() {
  //   if (valueGetter() case T value) return effectiveStringifier(value);
  //   return nullString;
  // }

  // Stringifier<T> get _effectiveStringifier => valueStringifier ?? _stringifyDefault;
  // Stringifier<T?> get _effectiveNullableStringifier {
  //   if (valueStringifier case Stringifier<T?> stringifier) return stringifier;
  //   return _stringifyDefault;
  // }

  //resolve the stirnifier
  Stringifier<T> get stringifier {
    // if (valueStringGetter != null) throw StateError('valueStringGetter is provided');
    if (valueGetter case ValueGetter<T> nonNullable) return valueStringifier ?? _stringifyDefault;
    if (valueStringifier case Stringifier<T?> nullableStringifier) return nullableStringifier;
    return _stringifyDefault;
  }

  String _string() => stringifier(valueGetter() as T);

  ValueGetter<String> get stringGetter {
    if (valueStringGetter != null) return valueStringGetter!;
    return _string;
  }

  static String _stringifyDefault(Object? value) => value.toString();
}

extension type const ValueStringGetter<T>._(ValueGetter<String> value) {
  factory ValueStringGetter.from(final ValueGetter<T> valueGetter, {final ValueGetter<String>? valueStringGetter, final Stringifier<T>? valueStringifier, final String nullString = ''}) {
    if (valueStringGetter != null) return ValueStringGetter._(valueStringGetter);

    Stringifier<T> stringifier = valueStringifier ?? _stringifyDefault;
    return ValueStringGetter._(() => stringifier(valueGetter()));
  }

  // full defined
  factory ValueStringGetter._fromTight(final ValueGetter<T> valueGetter, final Stringifier<T?> valueStringifier, {final String nullString = ''}) {
    return ValueStringGetter._(() => valueStringifier(valueGetter()));
  }

  // resolve
  factory ValueStringGetter._fromLoose(final ValueGetter<T?> valueGetter, final Stringifier<T> valueStringifier, {final String nullString = ''}) {
    if (valueStringifier case Stringifier<T?> nullable) return ValueStringGetter._(() => nullable(valueGetter()));
    if (valueGetter case ValueGetter<T> nonNullable) return ValueStringGetter._(() => valueStringifier(nonNullable()));
    return ValueStringGetter._(() {
      if (valueGetter() case T value) return valueStringifier(value);
      return nullString;
    });
  }

  factory ValueStringGetter.fromNullable(final ValueGetter<T?> valueGetter, {final ValueGetter<String>? valueStringGetter, final Stringifier<T>? valueStringifier, final String nullString = ''}) {
    if (valueStringGetter != null) return ValueStringGetter._(valueStringGetter);

    if (valueStringifier case Stringifier<T?> nullableStringifier) {
      return ValueStringGetter._(() => nullableStringifier(valueGetter()));
    }

    if (valueGetter case ValueGetter<T> nonNullable) {
      Stringifier<T> stringifier = valueStringifier ?? _stringifyDefault;
      return ValueStringGetter._(() => stringifier(nonNullable()));
    }
    return ValueStringGetter._(() => nullString);
  }

  static String _stringifyDefault(Object? value) => value.toString();
}
