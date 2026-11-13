import 'package:cmdr/widgets/io_field/io_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

String fieldText(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

/// Clears the field, then types [text] one keystroke at a time, as a keyboard edits the current text.
Future<void> typeKeys(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), '');
  for (final key in text.split('')) {
    await tester.enterText(find.byType(TextField), fieldText(tester) + key);
  }
}

bool fieldError(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).statesController!.value.contains(WidgetState.error);

void main() {
  /// Types [text] into a field with limits [min]..10, expects it to show [shows], then submits and expects [writes].
  Future<void> expectTyped<T extends num>(WidgetTester tester, String text, {required num min, required String shows, List<T> writes = const []}) async {
    final written = <T>[];
    final value = ValueNotifier<T>((0.0 is T ? 0.0 : 0) as T);
    await tester.pumpWidget(
      host(IOFieldText<T>.config(IOFieldConfig<T>(valueListenable: value, valueGetter: () => value.value, valueSetter: written.add, valueNumLimits: (min: min, max: 10)))),
    );
    await typeKeys(tester, text);
    expect(fieldText(tester), shows);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    if (writes.isNotEmpty) expect(written, writes);
  }

  group('typing a negative value with a negative minimum', () {
    testWidgets('int', (tester) => expectTyped<int>(tester, '-5', min: -10, shows: '-5', writes: [-5]));
    testWidgets('double', (tester) => expectTyped<double>(tester, '-5', min: -10, shows: '-5', writes: [-5.0]));
    testWidgets('num', (tester) => expectTyped<num>(tester, '-5', min: -10, shows: '-5', writes: [-5]));
  });

  group('full decimal precision', () {
    testWidgets('double keeps 0.015', (tester) => expectTyped<double>(tester, '0.015', min: -10, shows: '0.015', writes: [0.015]));
    testWidgets('num keeps 0.015', (tester) => expectTyped<num>(tester, '0.015', min: -10, shows: '0.015', writes: [0.015]));
  });

  group('a non-negative minimum drops the sign', () {
    testWidgets('int', (tester) => expectTyped<int>(tester, '-5', min: 0, shows: '5'));
    testWidgets('double', (tester) => expectTyped<double>(tester, '-5', min: 0, shows: '5'));
    testWidgets('num', (tester) => expectTyped<num>(tester, '-5', min: 0, shows: '5'));
  });

  testWidgets('the tooltip shows the clamp range', (tester) async {
    await expectTyped<int>(tester, '', min: -10, shows: '');
    expect(find.byWidgetPredicate((widget) => widget is Tooltip && widget.message == '-10..10'), findsOneWidget);
  });

  testWidgets('a notification does not overwrite typing while focused, and resyncs after focus loss', (tester) async {
    final value = ValueNotifier<int>(1);
    await tester.pumpWidget(host(IOFieldText<int>.config(IOFieldConfig<int>(valueListenable: value, valueGetter: () => value.value, valueNumLimits: (min: -10, max: 10)))));

    await typeKeys(tester, '3');
    value.value = 7;
    await tester.pump();
    expect(fieldText(tester), '3');

    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    expect(fieldText(tester), '7');

    value.value = 8;
    await tester.pump();
    expect(fieldText(tester), '8');
  });

  testWidgets('a notification keeps the parse error alongside errorGetter', (tester) async {
    final value = ValueNotifier<int>(1);
    await tester.pumpWidget(
      host(IOFieldText<int>.config(IOFieldConfig<int>(valueListenable: value, valueGetter: () => value.value, errorGetter: () => false, valueNumLimits: (min: -10, max: 10)))),
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(fieldError(tester), isTrue);

    value.value = 2;
    await tester.pump();
    expect(fieldError(tester), isTrue);
  });

  testWidgets('a new listenable replaces the old one, and dispose stops listening', (tester) async {
    final first = ValueNotifier<int>(1);
    final second = ValueNotifier<int>(2);
    Widget field(ValueNotifier<int> value) => host(IOFieldText<int>.config(IOFieldConfig<int>(valueListenable: value, valueGetter: () => value.value, valueNumLimits: (min: -10, max: 10))));

    await tester.pumpWidget(field(first));
    await tester.pumpWidget(field(second));
    expect(fieldText(tester), '2');

    first.value = 5;
    await tester.pump();
    expect(fieldText(tester), '2');

    second.value = 6;
    await tester.pump();
    expect(fieldText(tester), '6');

    await tester.pumpWidget(host(const SizedBox()));
    second.value = 7;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
