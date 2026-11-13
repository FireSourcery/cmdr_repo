import 'dart:async';

import 'package:cmdr/widgets/dialog/dialog.dart';
import 'package:flutter/material.dart';
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
}
