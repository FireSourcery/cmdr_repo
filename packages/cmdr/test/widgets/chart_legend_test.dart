import 'package:cmdr/widgets/time_chart/chart_controller.dart';
import 'package:cmdr/widgets/time_chart/chart_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins that a legend entry reads as its name and value, and that a selectable one is reached and chosen from the keyboard.
void main() {
  testWidgets('an entry reads as its name and value; a selectable one is chosen from the keyboard', (tester) async {
    final semantics = tester.ensureSemantics();
    final tick = ValueNotifier(0);
    addTearDown(tick.dispose);
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartLegend(
            listenable: tick,
            entries: [
              ChartEntry(name: 'Speed', valueGetter: () => 12.5, onSelect: () => selected.add('Speed')),
              ChartEntry(name: 'Iq', valueGetter: () => 3),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSemantics(find.text('Speed')), isSemantics(label: 'Speed\n12.5', isFocusable: true, hasTapAction: true));
    expect(tester.getSemantics(find.text('Iq')), isSemantics(label: 'Iq\n3.0', isFocusable: false, hasTapAction: false));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, ['Speed']);
    semantics.dispose();
  });
}
