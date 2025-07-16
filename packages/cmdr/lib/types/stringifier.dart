import 'package:flutter/foundation.dart';

/// select based on provided functions
mixin StringifierSelect<T> {
  // ValueGetter<T?> get valueGetter;
  // ValueGetter<String>? get valueStringGetter;
  // Stringifier<T>? get valueStringifier;

  // static String _stringifyDefault(Object? value) => value.toString(); // unhandled null value string
  // Stringifier<T> get _effectiveStringifier => valueStringifier ?? _stringifyDefault;

  // Stringifier<T?> get _effectiveNullableStringifier {
  //   if (valueStringifier case Stringifier<T?> stringifier) stringifier;
  //   return _stringifyDefault;
  // }

  // String _stringifyValue() {
  //   if (valueGetter() case T value) return _effectiveStringifier(value);
  //   return 'Value Error'; // or handle null

  //   // _effectiveNullableStringifier(valueGetter());
  // }

  // ValueGetter<String> get _effectiveValueStringGetter => valueStringGetter ?? _stringifyValue;
}
