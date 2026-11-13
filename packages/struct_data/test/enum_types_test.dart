import 'package:struct_data/binary_format/binary_format.dart';
import 'package:struct_data/general/enum_types.dart';
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

  group('codec resolve', () {
    test('unknown value is null, never the first or last member', () {
      expect(const EnumCodecDefault(Color.values).resolve(7), isNull);
      expect(const EnumCodecDefault(Color.values).resolve(-1), isNull);
      expect(const EnumCodecOffset(Color.values, 1).resolve(2), isNull);
      expect(const EnumCodecOffset(Color.values, 1).resolve(-2), isNull);
      expect(const EnumCodecSign(Color.values).resolve(5), isNull);
      expect(const EnumFormat<Int16, Color>(Color.values).resolve(3), isNull);
      expect(const EnumOffsetFormat<Int16, Color>(Color.values, 1).resolve(2), isNull);
      expect(const EnumOffsetFormat<Int16, Color>(Color.values, 1).resolve(-2), isNull);
    });

    test('null data is null, known value is the member', () {
      expect(const EnumCodecDefault(Color.values).resolve(null), isNull);
      expect(const EnumCodecDefault(Color.values).resolve(2), Color.blue);
      expect(const EnumCodecOffset(Color.values, 1).resolve(-1), Color.red);
      expect(const EnumOffsetFormat<Int16, Color>(Color.values, 1).resolve(1), Color.blue);
    });

    test('offset format sign-extends before resolving', () {
      expect(const EnumOffsetFormat<Int16, Color>(Color.values, 1).resolve(0xFFFF), Color.red);
    });

    test('handler codec resolves through its decoder', () {
      const codec = EnumCodecByHandlers<Color>(values: Color.values, decoder: _decodeReversed, encoder: _encodeReversed);
      expect(codec.resolve(0), Color.blue);
      expect(codec.resolve(null), isNull);
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

Color _decodeReversed(int data) => Color.values[Color.values.length - 1 - data];
int _encodeReversed(Color view) => Color.values.length - 1 - view.index;
