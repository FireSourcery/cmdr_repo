import 'dart:async';

import 'package:cmdr/widgets/app_general/drive_shift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Gear() {
  forward,
  neutral,
  reverse,
  park,
}

/// Pins what [DriveShift] shows: the gear [DriveShift.actual] reports, and a request as pending until the confirm answers.
void main() {
  late ValueNotifier<Enum?> actual;
  late Completer<Enum?> confirm;
  late int confirms;

  setUp(() {
    actual = ValueNotifier(_Gear.neutral);
    confirms = 0;
  });

  Future<void> pumpShift(WidgetTester tester, {AsyncValueSetter<Enum>? onSelect}) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DriveShift(
          actual: actual,
          onSelect: onSelect ?? (_) async {},
          confirmSelected: () {
            confirms++;
            return confirm.future;
          },
          enumF: _Gear.forward,
          enumN: _Gear.neutral,
          enumR: _Gear.reverse,
          enumP: _Gear.park,
        ),
      ),
    ),
  );

  Finder buttonOf(String label) => find.widgetWithText(ElevatedButton, label);
  Set<WidgetState> statesOf(WidgetTester tester, String label) => tester.widget<ElevatedButton>(buttonOf(label)).statesController!.value;
  Finder pendingOn(String label) => find.descendant(of: buttonOf(label), matching: find.byType(CircularProgressIndicator));
  Color? backgroundOf(WidgetTester tester, String label) => tester.widget<Material>(find.descendant(of: buttonOf(label), matching: find.byType(Material)).first).color;

  Future<void> request(WidgetTester tester, String label) async {
    confirm = Completer(); // made in the test body, not setUp, so its answer lands in the fake-async zone the frames run in
    await tester.tap(find.text(label));
    await tester.pump();
  }

  Future<void> answer(WidgetTester tester, Enum? reported) async {
    confirm.complete(reported);
    await tester.pump();
  }

  testWidgets('selects the gear the device reports, and follows it', (tester) async {
    await pumpShift(tester);
    expect(statesOf(tester, 'N'), contains(WidgetState.selected));

    actual.value = _Gear.reverse;
    await tester.pump();

    expect(statesOf(tester, 'R'), contains(WidgetState.selected));
    expect(statesOf(tester, 'N'), isNot(contains(WidgetState.selected)));
  });

  testWidgets('a request shows pending, not selected, until the device confirms it', (tester) async {
    await pumpShift(tester);
    await request(tester, 'F');

    expect(pendingOn('F'), findsOneWidget);
    expect(statesOf(tester, 'F'), isNot(contains(WidgetState.selected)));
    expect(statesOf(tester, 'N'), contains(WidgetState.selected));

    actual.value = _Gear.forward;
    await answer(tester, _Gear.forward);

    expect(pendingOn('F'), findsNothing);
    expect(statesOf(tester, 'F'), contains(WidgetState.selected));
    expect(statesOf(tester, 'F'), isNot(contains(WidgetState.error)));
    expect(statesOf(tester, 'N'), isNot(contains(WidgetState.selected)));
  });

  testWidgets('a request the device does not take leaves the reported gear selected and marks the request', (tester) async {
    await pumpShift(tester);
    await request(tester, 'F');
    await answer(tester, _Gear.neutral);

    expect(pendingOn('F'), findsNothing);
    expect(statesOf(tester, 'F'), contains(WidgetState.error));
    expect(statesOf(tester, 'F'), isNot(contains(WidgetState.selected)));
    expect(statesOf(tester, 'N'), contains(WidgetState.selected));
  });

  testWidgets('the reported gear shows selected, not the error of an earlier request for it', (tester) async {
    await pumpShift(tester);
    await request(tester, 'P');
    await answer(tester, _Gear.neutral);

    actual.value = _Gear.park;
    await tester.pump();

    final colors = Theme.of(tester.element(buttonOf('P'))).colorScheme;
    expect(backgroundOf(tester, 'P'), colors.outline.withAlpha(100));
  });

  testWidgets('the device is asked for the gear only once it has answered the request, which shows pending meanwhile', (tester) async {
    final sent = Completer<void>();
    await pumpShift(tester, onSelect: (_) => sent.future);
    await request(tester, 'F');

    expect(pendingOn('F'), findsOneWidget);
    expect(confirms, 0);

    sent.complete();
    await tester.pump();

    expect(confirms, 1);
    expect(pendingOn('F'), findsOneWidget);
  });

  testWidgets('a second request keeps its pending mark when the first is answered', (tester) async {
    await pumpShift(tester);
    await request(tester, 'F');
    final first = confirm;
    await request(tester, 'R');

    first.complete(_Gear.neutral);
    await tester.pump();
    expect(pendingOn('R'), findsOneWidget);

    await answer(tester, _Gear.reverse);
    expect(pendingOn('R'), findsNothing);
  });

  testWidgets('a request that throws clears its pending mark, and its error still surfaces', (tester) async {
    final errors = <Object>[];
    await pumpShift(tester, onSelect: (_) async => throw StateError('link lost'));
    await runZonedGuarded(() => tester.tap(find.text('F')), (error, _) => errors.add(error)); // the error a tapped button's future leaves uncaught
    await tester.pump();

    expect(errors, [isA<StateError>()]);
    expect(pendingOn('F'), findsNothing);
  });
}
