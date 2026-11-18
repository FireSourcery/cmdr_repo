import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmdr/widgets/app_general/bottom_sheet_button.dart';
import 'package:cmdr/widgets/main_menu/main_menu.dart';

/// Pins that the menu and the bottom bar paint a backdrop widget behind their content, where an image used to be the only option.
void main() {
  const backdrop = ColoredBox(key: ValueKey('backdrop'), color: Colors.blue);

  testWidgets('MenuContainer paints its backdrop behind its child, filling it, with no image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 400,
            child: MenuContainer(
              backdrop: backdrop,
              child: SizedBox(width: 100, height: 300, child: Text('items')),
            ),
          ),
        ),
      ),
    );
    expect(find.text('items'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('backdrop'))), tester.getSize(find.byType(IntrinsicHeight)));
    expect(find.ancestor(of: find.text('items'), matching: find.byType(Stack)), findsWidgets);
  });

  testWidgets('BottomSheetButton paints its backdrop behind the button, with no image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          floatingActionButton: BottomSheetButton(backdrop: backdrop, child: null),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('backdrop')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('backdrop'))).height, greaterThan(0));
  });
}
