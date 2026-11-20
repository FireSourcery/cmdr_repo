import 'package:cmdr/var_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

enum const Color() {
  red,
  green,
  blue,
}

class _EnumVar() with VarValue<Color> {
  this {
    codec = const EnumFormat<NativeType, Color>(Color.values);
  }
}

/// Interim contract, pending a nullable view type:
/// a device value naming no enum member clamps to the nearest member, [VarValue.view] does not throw.
void main() {
  group('VarValue over an enum codec', () {
    test('view of a known server value is the member', () {
      expect((_EnumVar()..serverData = 1).view, Color.green);
    });

    test('view of an unknown server value clamps to the nearest member', () {
      expect((_EnumVar()..serverData = 7).view, Color.blue);
    });

    test('a num naming no member is refused, a file value is not clamped', () {
      expect(() => _EnumVar()..numView = 7, throwsRangeError);
      expect((_EnumVar()..numView = 2).view, Color.blue);
    });

    test('a pending user view still reads back while the server value is unknown', () {
      expect(
        (_EnumVar()
              ..serverData = 7
              ..view = Color.red)
            .view,
        Color.red,
      );
    });
  });
}
