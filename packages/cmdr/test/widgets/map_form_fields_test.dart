import 'package:cmdr/widgets/data_views/map_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String fieldText(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

/// Types [text] one keystroke at a time into a single entry field, returning what it shows.
Future<String> typeInto<V extends num>(WidgetTester tester, String text, {required (num, num) numLimits}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Form(
          child: MapFormFields<String, V>.digits(entries: {'a': (0.0 is V ? 0.0 : 0) as V}.entries, onSaved: (_) {}, numLimits: numLimits),
        ),
      ),
    ),
  );
  await tester.enterText(find.byType(TextField), '');
  for (final key in text.split('')) {
    await tester.enterText(find.byType(TextField), fieldText(tester) + key);
  }
  return fieldText(tester);
}

void main() {
  testWidgets('int with a negative minimum keeps the sign and the length of the minimum', (tester) async {
    expect(await typeInto<int>(tester, '-1000', numLimits: (-1000, 10)), '-1000');
  });
  testWidgets('double with a negative minimum keeps the sign and full precision', (tester) async {
    expect(await typeInto<double>(tester, '-0.015', numLimits: (-1000.0, 1000.0)), '-0.015');
  });
  testWidgets('num with a negative minimum keeps the sign', (tester) async {
    expect(await typeInto<num>(tester, '-5', numLimits: (-10, 10)), '-5');
  });
  testWidgets('a non-negative minimum drops the sign', (tester) async {
    expect(await typeInto<int>(tester, '-5', numLimits: (0, 10)), '5');
  });
  test('maxDigits is the longer of min and max', () {
    expect(MapFormFields<String, int>.digits(entries: const <MapEntry<String, int>>[], onSaved: (_) {}, numLimits: (-1000, 10)).maxDigits, 5);
    expect(MapFormFields<String, int>.digits(entries: const <MapEntry<String, int>>[], onSaved: (_) {}, numLimits: (0, 65535)).maxDigits, 5);
  });
  testWidgets('double has room for a fraction past the length of the limits', (tester) async {
    expect(await typeInto<double>(tester, '12345.6', numLimits: (0, 65535)), '12345.6');
  });
  testWidgets('a seeded double longer than the limits keeps its digits on the next keystroke', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(child: MapFormFields<String, double>.digits(entries: {'a': 48.828125}.entries, onSaved: (_) {}, numLimits: (0, 65535))),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '${fieldText(tester)}1');
    expect(fieldText(tester), '48.8281251');
  });
}
