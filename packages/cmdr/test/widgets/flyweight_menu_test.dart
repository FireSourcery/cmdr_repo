import 'package:cmdr/widgets/flyweight_menu/flyweight_menu.dart';
import 'package:cmdr/widgets/flyweight_menu/flyweight_menu_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

const source = FlyweightMenuSource<int>(
  menuItems: [
    FlyweightMenuItem(itemKey: null, child: Text('header')),
    FlyweightMenuItem(itemKey: 1, child: Text('one')),
    FlyweightMenuItem(itemKey: 2, child: Text('two')),
  ],
  defaultKey: 0,
);

/// Logs each build of a menu item's view into [builds].
class const CountedText(final String text, final List<String> builds, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    builds.add(text);
    return Text(text);
  }
}

Future<void> openMenu(WidgetTester tester, Finder anchor) async {
  await tester.tap(anchor);
  await tester.pumpAndSettle();
}

void main() {
  test('instances of one source share each item view, and own their buttons and notifier', () {
    final a = source.create();
    final b = source.create();
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    for (final (index, item) in source.menuItems.indexed) {
      expect(a.menuItems[index], isA<MenuItemButton>().having((button) => button.child, 'child', same(item.child)));
      expect(b.menuItems[index], isA<MenuItemButton>().having((button) => button.child, 'child', same(item.child)));
      expect(a.menuItems[index], isNot(same(b.menuItems[index])));
    }
    a.value = 1;
    expect(b.value, 0);
  });

  testWidgets('pressing an item under any MenuAnchor sets only its own instance and calls its onPressed', (tester) async {
    final pressed = <String>[];
    final a = source.create(onPressed: (key) => pressed.add('a$key'));
    final b = source.create(onPressed: (key) => pressed.add('b$key'));
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await tester.pumpWidget(
      host(
        Column(
          children: [
            MenuAnchorButton(menuItems: a.menuItems),
            MenuAnchorButton(menuItems: b.menuItems),
          ],
        ),
      ),
    );

    await openMenu(tester, find.byType(IconButton).first);
    await tester.tap(find.text('two'));
    await tester.pumpAndSettle();

    expect(a.value, 2);
    expect(b.value, 0);
    expect(pressed, ['a2']);
  });

  testWidgets('a null key gives a disabled button', (tester) async {
    final menu = source.create();
    addTearDown(menu.dispose);
    await tester.pumpWidget(host(FlyweightMenuButton<int>(menu: menu)));

    await openMenu(tester, find.byType(IconButton));

    expect(tester.widget<MenuItemButton>(find.widgetWithText(MenuItemButton, 'header')).enabled, isFalse);
    expect(tester.widget<MenuItemButton>(find.widgetWithText(MenuItemButton, 'one')).enabled, isTrue);
  });

  testWidgets('MenuAnchorBuilder selects through its instance and disposes it', (tester) async {
    late FlyweightMenu<int> built;
    await tester.pumpWidget(
      host(
        MenuAnchorBuilder<int>(
          menuSource: source,
          initialItem: 1,
          menuAnchorBuilder: (context, menu, keyWidget) {
            built = menu;
            return MenuAnchorOverlay(menuItems: menu.menuItems, child: keyWidget);
          },
          keyBuilder: (context, key, child) => Text('selected $key'),
        ),
      ),
    );

    await tester.longPress(find.text('selected 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('two'));
    await tester.pumpAndSettle();
    expect(find.text('selected 2'), findsOneWidget);

    await tester.pumpWidget(host(const SizedBox()));
    expect(() => ChangeNotifier.debugAssertNotDisposed(built), throwsFlutterError);
  });

  testWidgets('MenuAnchorOverlay opens from the keyboard, and an item is chosen from there', (tester) async {
    await tester.pumpWidget(
      host(
        MenuAnchorBuilder<int>(
          menuSource: source,
          initialItem: 1,
          menuAnchorBuilder: (context, menu, keyWidget) => MenuAnchorOverlay(menuItems: menu.menuItems, child: keyWidget),
          keyBuilder: (context, key, child) => Text('selected $key'),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('two'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // 'header' is disabled: 'one', then 'two'
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('selected 2'), findsOneWidget);
  });

  testWidgets('a tap on MenuAnchorOverlay leaves the menu closed; numpad Enter, Space and the context-menu keys open it', (tester) async {
    final menu = source.create();
    addTearDown(menu.dispose);
    await tester.pumpWidget(host(MenuAnchorOverlay(menuItems: menu.menuItems, child: const Text('gauge'))));

    await tester.tap(find.text('gauge'));
    await tester.pumpAndSettle();
    expect(find.text('two'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    for (final (name, press) in <(String, Future<void> Function())>[
      ('Numpad Enter', () => tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter)),
      ('Space', () => tester.sendKeyEvent(LogicalKeyboardKey.space)),
      ('Menu key', () => tester.sendKeyEvent(LogicalKeyboardKey.contextMenu)),
      (
        'Shift+F10',
        () async {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.f10);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        },
      ),
    ]) {
      await press();
      await tester.pumpAndSettle();
      expect(find.text('two'), findsOneWidget, reason: name);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('two'), findsNothing, reason: name);
    }
  });

  testWidgets('both menu anchors are buttons that say they show a menu', (tester) async {
    final menu = source.create();
    addTearDown(menu.dispose);
    await tester.pumpWidget(
      host(
        Column(
          children: [
            MenuAnchorButton(menuItems: menu.menuItems),
            MenuAnchorOverlay(menuItems: menu.menuItems, child: const Text('gauge')),
          ],
        ),
      ),
    );

    expect(tester.getSemantics(find.byType(IconButton)), isSemantics(tooltip: 'Show menu', isButton: true, hasTapAction: true));
    expect(tester.getSemantics(find.text('gauge')), isSemantics(label: 'gauge', tooltip: 'Show menu', isButton: true, isFocusable: true, hasTapAction: true));

    tester.semantics.tap(find.semantics.byLabel('gauge')); // assistive technology activates it as the keyboard does
    await tester.pumpAndSettle();
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('a value change does not rebuild the open items', (tester) async {
    final builds = <String>[];
    final menu = FlyweightMenuSource<int>(
      menuItems: [
        FlyweightMenuItem(itemKey: 1, child: CountedText('one', builds)),
        FlyweightMenuItem(itemKey: 2, child: CountedText('two', builds)),
      ],
      defaultKey: 0,
    ).create();
    addTearDown(menu.dispose);
    await tester.pumpWidget(host(FlyweightMenuButton<int>(menu: menu)));
    await openMenu(tester, find.byType(IconButton));
    final items = tester.widgetList<MenuItemButton>(find.byType(MenuItemButton)).toList();
    builds.clear();

    menu.value = 2;
    await tester.pump();

    expect(builds, isEmpty);
    expect(tester.widgetList<MenuItemButton>(find.byType(MenuItemButton)), orderedEquals(items));
  });

  testWidgets('MenuAnchorOverlay keeps one MenuController across a parent rebuild', (tester) async {
    final menu = source.create();
    addTearDown(menu.dispose);
    final controllers = <MenuController?>[];
    Widget overlay() => host(
      MenuAnchorOverlay(
        menuItems: menu.menuItems,
        child: Builder(
          builder: (context) {
            controllers.add(MenuController.maybeOf(context));
            return const Text('gauge');
          },
        ),
      ),
    );

    await tester.pumpWidget(overlay());
    await tester.pumpWidget(overlay());

    expect(controllers, [isNotNull, isNotNull]);
    expect(controllers.last, same(controllers.first));
  });
}
