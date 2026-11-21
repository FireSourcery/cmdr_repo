import 'package:cmdr/interfaces/stringifier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins [ValueStringGetter.of]: the precedence, each resolved path, and that the getter reads the value on each call.
void main() {
  int? value = 3;
  int? nullableValue() => value;
  int nonNullValue() => value!;

  test('valueStringGetter wins over valueStringifier', () {
    expect(ValueStringGetter<int>.of(nonNullValue, valueStringifier: (v) => 'v$v', valueStringGetter: () => 'given')(), 'given');
  });

  test('valueStringifier over valueGetter, read on each call', () {
    value = 3;
    final getter = ValueStringGetter<int>.of(nonNullValue, valueStringifier: (v) => 'v$v');
    expect(getter(), 'v3');
    value = 4;
    expect(getter(), 'v4');
  });

  test('no stringifier is toString', () {
    value = 3;
    expect(ValueStringGetter<int>.of(nonNullValue)(), '3');
  });

  test('a nullable getter under a non-null stringifier shows nullString for null', () {
    final getter = ValueStringGetter<int>.of(nullableValue, valueStringifier: (int v) => 'v$v', nullString: '-');
    value = null;
    expect(getter(), '-');
    value = 5;
    expect(getter(), 'v5');
  });

  test('no stringifier shows nullString for null, never "null"', () {
    value = null;
    expect(ValueStringGetter<int>.of(nullableValue)(), '');
    expect(ValueStringGetter<int>.of(nullableValue, nullString: '-')(), '-');
    value = 5;
    expect(ValueStringGetter<int>.of(nullableValue)(), '5');
  });

  test('a stringifier that takes null receives it', () {
    value = null;
    expect(ValueStringGetter<int>.of(nullableValue, valueStringifier: (int? v) => 'got $v', nullString: '-')(), 'got null');
  });

  test('tears off as a ValueGetter<String>', () {
    value = 3;
    final String Function() getter = ValueStringGetter<int>.of(nonNullValue).call;
    expect(getter(), '3');
  });
}
