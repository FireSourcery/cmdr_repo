import 'package:flutter/foundation.dart';

/// [Stringifier]
typedef Stringifier<T> = String Function(T input);
typedef NullableStringifier<T> = String Function(T? input);
typedef GenericStringifier = String Function<T>(T input);
// typedef GenericStringifier = String Function<T>(T? input); // non-nullable type, with nullable input, cases where T is used for selection

/// The display string of a value without a [Stringifier].
String stringifyDefault(Object? value) => value.toString();

/// [ValueStringGetter]
/// A value's display string as one closure, resolved once from the parameters the caller has:
/// `valueStringGetter` > `valueStringifier` over `valueGetter` > [stringifyDefault].
///
/// Runtime type tests choose the closure. A stringifier that takes null, or a getter that cannot return it, is called
/// directly; only a nullable getter under a non-null stringifier tests each value, showing `nullString` for null.
/// `.call` tears it off as a [ValueGetter<String>].
extension type const ValueStringGetter<T>._(ValueGetter<String> _getter) {
  factory ValueStringGetter.of(ValueGetter<T?> valueGetter, {Stringifier<T>? valueStringifier, ValueGetter<String>? valueStringGetter, String nullString = ''}) {
    return ValueStringGetter._(
      valueStringGetter ??
          switch ((valueStringifier ?? stringifyDefault, valueGetter)) {
            (Stringifier<T?> stringifier, _) => () => stringifier(valueGetter()),
            (final stringifier, ValueGetter<T> getter) => () => stringifier(getter()),
            (final stringifier, _) => () => switch (valueGetter()) {
              T value => stringifier(value),
              null => nullString,
            },
          },
    );
  }

  String call() => _getter();
}
