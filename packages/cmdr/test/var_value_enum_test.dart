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

/// Interim contract, pending the owner decision on a nullable view type:
/// a device value naming no enum member is not clamped to a wrong label, [VarValue.view] throws.
void main() {
  group('VarValue over an enum codec', () {
    test('view of a known server value is the member', () {
      expect((_EnumVar()..serverData = 1).view, Color.green);
    });

    test('view of an unknown server value throws instead of clamping', () {
      expect(() => (_EnumVar()..serverData = 7).view, throwsRangeError);
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
