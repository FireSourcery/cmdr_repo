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

  testWidgets('BottomSheetButton paints its backdrop over the bar surface and its border, under the button, passing taps through', (tester) async {
    const shape = BeveledRectangleBorder(side: BorderSide(color: Colors.white));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          floatingActionButton: BottomSheetButton(backdrop: backdrop, shape: shape, child: Text('sheet')),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );
    final List<Element> paintOrder = tester.allElements.toList();
    int indexOf(bool Function(Widget widget) test) => paintOrder.indexWhere((element) => test(element.widget));
    final int surface = indexOf((widget) => widget is Material && widget.shape == shape);
    final int light = indexOf((widget) => widget.key == const ValueKey('backdrop'));
    final int button = indexOf((widget) => widget is FloatingActionButton);
    expect((surface >= 0, light > surface, button > light), (true, true, true), reason: 'surface, then the backdrop, then the button');
    expect(tester.getSize(find.byKey(const ValueKey('backdrop'))).height, greaterThan(0));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget, reason: 'the button opens its sheet through the backdrop');
  });
}
