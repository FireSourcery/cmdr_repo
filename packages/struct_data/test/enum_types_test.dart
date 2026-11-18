import 'package:struct_data/struct_data.dart';
import 'package:test/test.dart';

enum const Color() { red, green, blue }

void main() {
  group('byIndex', () {
    test('returns the member in range', () {
      expect(Color.values.byIndex(1), Color.green);
    });

    test('returns the default out of range', () {
      expect(Color.values.byIndex(7, Color.red), Color.red);
      expect(Color.values.byIndex(-1, Color.red), Color.red);
    });

    test('throws RangeError out of range without a default, never clamps', () {
      expect(() => Color.values.byIndex(7), throwsRangeError);
      expect(() => Color.values.byIndex(-1), throwsRangeError);
    });
  });

  group('list resolve', () {
    test('unknown index is null, never the first or last member', () {
      expect(Color.values.resolve(7), isNull);
      expect(Color.values.resolve(-1), isNull);
    });

    test('null index is null, known index is the member', () {
      expect(Color.values.resolve(null), isNull);
      expect(Color.values.resolve(2), Color.blue);
    });

    test('union codec resolves unknown to null', () {
      final union = EnumUnionCodec<Enum>.of({Color.values});
      expect(union.resolve<Color>(7), isNull);
      expect(union.resolve<Color>(2), Color.blue);
    });
  });

  group('codec decode', () {
    test('known value is the member', () {
      expect(const EnumCodecDefault(Color.values).decode(2), Color.blue);
      expect(const EnumCodecOffset(Color.values, 1).decode(-1), Color.red);
    });

    test('unknown value throws RangeError, never clamps', () {
      expect(() => const EnumCodecDefault(Color.values).decode(7), throwsRangeError);
      expect(() => const EnumCodecOffset(Color.values, 1).decode(2), throwsRangeError);
      expect(() => const EnumOffsetFormat<Int16, Color>(Color.values, 1).decode(-2), throwsRangeError);
    });
  });
}
