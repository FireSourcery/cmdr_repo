import 'dart:async';

import 'package:cmdr/widgets/dialog/dialog.dart';
import 'package:cmdr/widgets/dialog/dialog_anchor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AsyncConfirmationDialog actions follow confirm, running and done', (tester) async {
    final process = Completer<int>();
    int? popped;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => popped = await showDialog<int>(
              context: context,
              builder: (_) => AsyncConfirmationDialog<int>(
                onConfirm: () => process.future,
                initialContent: const Text('Are you sure?'),
                onConfirmContent: (_, snapshot) => Text('result ${snapshot.data}'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Ok'), findsNothing);

    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Confirm'), findsNothing);
    expect(find.text('Ok'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    process.complete(42);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('result 42'), findsOneWidget);
    expect(find.text('Ok'), findsOneWidget);

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.byType(AsyncConfirmationDialog<int>), findsNothing);
    expect(popped, 42);
  });

  testWidgets('AsyncConfirmationDialog is not popped by Escape or back while running', (tester) async {
    final process = Completer<int>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<int>(
              context: context,
              builder: (_) => AsyncConfirmationDialog<int>(
                onConfirm: () => process.future,
                initialContent: const Text('Are you sure?'),
                onConfirmContent: (_, snapshot) => Text('result ${snapshot.data}'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    // pump past a route's exit transition, which pumpAndSettle cannot while the spinner runs
    Future<void> pumpPastTransition() async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpPastTransition();
    expect(find.byType(AsyncConfirmationDialog<int>), findsOneWidget);

    await tester.binding.handlePopRoute();
    await pumpPastTransition();
    expect(find.byType(AsyncConfirmationDialog<int>), findsOneWidget);

    process.complete(42);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(AsyncConfirmationDialog<int>), findsNothing);
  });

  group('Cancel closes the dialog with no result and never calls onConfirm', () {
    /// The value [dialog] pops on Cancel; -1 while it stays open.
    Future<int?> cancel(WidgetTester tester, Widget dialog) async {
      int? popped = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => popped = await showDialog<int>(context: context, builder: (_) => dialog),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      return popped;
    }

    testWidgets('ConfirmationDialog', (tester) async {
      var confirms = 0;
      expect(await cancel(tester, ConfirmationDialog<int>(onConfirm: () => ++confirms, content: const Text('Are you sure?'))), isNull);
      expect(confirms, 0);
    });

    testWidgets('AsyncConfirmationDialog', (tester) async {
      var confirms = 0;
      final dialog = AsyncConfirmationDialog<int>(
        onConfirm: () async => ++confirms,
        initialContent: const Text('Are you sure?'),
        onConfirmContent: (_, snapshot) => Text('result ${snapshot.data}'),
      );
      expect(await cancel(tester, dialog), isNull);
      expect(confirms, 0);
    });
  });

  group('the warning style: the warning icon in the theme warning colour, and Confirm in the warning button style', () {
    const warningButtonStyle = ButtonStyle(elevation: WidgetStatePropertyAll(10));

    Future<void> pumpDialog(WidgetTester tester, Widget dialog) {
      return tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [DialogButtonTheme(warningButtonStyle: warningButtonStyle, warningColor: Colors.amber)],
          ),
          home: dialog,
        ),
      );
    }

    ButtonStyle? styleOf(WidgetTester tester, String action) => tester.widget<TextButton>(find.widgetWithText(TextButton, action)).style;

    void expectWarning(WidgetTester tester) {
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(tester.widget<AlertDialog>(find.byType(AlertDialog)).iconColor, Colors.amber);
      expect(styleOf(tester, 'Confirm'), warningButtonStyle);
      expect(styleOf(tester, 'Cancel'), isNull);
    }

    testWidgets('ConfirmationDialog', (tester) async {
      await pumpDialog(tester, const ConfirmationDialog<void>(styleId: DialogButtonStyle.warning, content: Text('Confirm Program Flash?')));
      expectWarning(tester);
    });

    testWidgets('AsyncConfirmationDialog, until confirmed', (tester) async {
      await pumpDialog(
        tester,
        AsyncConfirmationDialog<int>(
          styleId: DialogButtonStyle.warning,
          onConfirm: () async => 0,
          initialContent: const Text('Warning: Motor will spin'),
          onConfirmContent: (_, _) => const SizedBox(),
        ),
      );
      expectWarning(tester);
    });

    testWidgets('is not the default', (tester) async {
      await pumpDialog(tester, const ConfirmationDialog<void>(content: Text('Confirm?')));

      expect(find.byIcon(Icons.warning), findsNothing);
      expect(styleOf(tester, 'Confirm'), isNull);
    });
  });
}
