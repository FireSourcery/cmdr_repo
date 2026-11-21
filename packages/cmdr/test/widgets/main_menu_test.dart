import 'dart:convert';

import 'package:cmdr/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Destination(@override final IconData icon, @override final String route) with MenuEntryId {
  first(Icons.home, '/first'),
  second(Icons.settings, '/second'),
}

/// Counts the route replacements the rail makes.
class _Replacements() extends NavigatorObserver {
  int count = 0;
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => count++;
}

/// A page that keeps a [State], so a rebuild of its route shows as a new one.
class const _Page(final String name) extends StatefulWidget {
  @override
  State<_Page> createState() => _PageState();
}

class _PageState() extends State<_Page> {
  @override
  Widget build(BuildContext context) => Text(widget.name);
}

/// The logo images are served as a 1x1 PNG, so the rail's leading buttons build in a test without the app's assets.
void serveLogoImages(WidgetTester tester) {
  final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
  tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    return key.endsWith('AssetManifest.bin') ? const StandardMessageCodec().encodeMessage(<String, Object>{}) : ByteData.sublistView(png);
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null));
}

void main() {
  late MainMenuController controller;
  late _Replacements replacements;

  Future<void> pumpRail(WidgetTester tester, {bool isExpanded = true}) async {
    serveLogoImages(tester);
    final navigatorKey = GlobalKey<NavigatorState>();
    controller = MainMenuController(_Destination.values, navigatorKey: navigatorKey)..isExpanded = isExpanded;
    replacements = _Replacements();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [LogoTheme(imageIcon: const AssetImage('logo.png'), imageExpanded: const AssetImage('logo_wide.png'), buttonStyle: ElevatedButton.styleFrom())],
        ),
        home: Scaffold(
          body: Row(
            children: [
              MainMenu(menuController: controller),
              Expanded(
                child: Navigator(
                  key: navigatorKey,
                  initialRoute: '/first',
                  observers: [replacements],
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(settings: settings, builder: (_) => _Page(settings.name!)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selecting the selected destination replaces no route and keeps its page', (tester) async {
    await pumpRail(tester);
    final page = tester.state(find.byType(_Page));

    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();

    expect(replacements.count, 0);
    expect(tester.state(find.byType(_Page)), same(page));
  });

  testWidgets('selecting another destination replaces the route once', (tester) async {
    await pumpRail(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(replacements.count, 1);
    expect(find.text('/second'), findsOneWidget);
  });

  testWidgets('a collapsed rail names each destination in a tooltip', (tester) async {
    await pumpRail(tester, isExpanded: false);
    for (final destination in _Destination.values) {
      expect(find.byTooltip(destination.label), findsOneWidget);
    }
  });

  testWidgets('the logo buttons are named for what they do', (tester) async {
    await pumpRail(tester, isExpanded: false);
    expect(find.byTooltip('Expand menu'), findsOneWidget);

    controller.isExpanded = true;
    await tester.pumpAndSettle();
    expect(find.byTooltip('Collapse menu'), findsOneWidget);
  });

  testWidgets('BottomSheetButton names its open and close buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(floatingActionButton: BottomSheetButton(child: Text('sheet'))),
      ),
    );
    expect(find.byTooltip('Show panel'), findsOneWidget);

    await tester.tap(find.byTooltip('Show panel'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide panel'), findsOneWidget);
  });
}
