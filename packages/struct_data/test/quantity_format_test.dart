import 'package:struct_data/binary_format/binary_format.dart';
import 'package:struct_data/binary_format/quantity_format.dart';
import 'package:test/test.dart';

void main() {
  group('NumDataScale.dataOf', () {
    const decimal = NumDataScale(0.1);

    test('rounds to the nearest word', () {
      expect(decimal.dataOf(0.3), 3);
      expect(decimal.dataOf(0.7), 7);
    });

    test('rounds half away from zero, symmetric about zero', () {
      expect(decimal.dataOf(-0.3), -3);
      expect(decimal.dataOf(-0.7), -7);
      expect(const NumDataScale(1.0).dataOf(2.5), 3);
      expect(const NumDataScale(1.0).dataOf(-2.5), -3);
    });

    test('agrees with FixedPoint.encode', () {
      const format = Fract16();
      final scale = NumDataScale(1 / format.scalingFactor);
      for (final view in [0.3, -0.3, 0.1234, -0.9999, 0.5]) {
        expect(scale.dataOf(view), format.encode(view), reason: '$view');
      }
      expect(scale.dataOf(0.3), 9830);
    });

    final coefficients = {'binary fraction 100/65536': 100 / 65536, 'binary fraction 72/32768': 72 / 32768, 'decimal 0.1': 0.1, 'negative': -0.1};
    for (final MapEntry(:key, :value) in coefficients.entries) {
      test('round trip dataOf(viewOf(word)) == word, $key', () {
        final scale = NumDataScale(value);
        for (var word = -32768; word <= 32767; word += 7) {
          expect(scale.dataOf(scale.viewOf(word)), word);
        }
      });

      test('round trip survives 4 dp display, $key', () {
        final scale = NumDataScale(value);
        for (var word = -32768; word <= 32767; word += 7) {
          expect(scale.dataOf(double.parse(scale.viewOf(word).toStringAsFixed(4))), word);
        }
      });
    }
  });

  group('BinaryQuantityCodec disabled conversion', () {
    test('rounds a fractional view to the nearest word', () {
      final codec = BinaryQuantityCodec<num>.of(const Int16Int());
      expect(codec.encode(2.7), 3);
      expect(codec.encode(-2.7), -3);
    });
  });

  group('BinaryQuantityCodec clamps a word rounded past the binary range', () {
    const scale = NumDataScale(1 / 128); // a power of 2, so the half LSB survives the division exactly
    final halfLsb = scale.coefficient / 2;

    test('half an LSB above the top of a Uint16 range encodes to binaryRange.max', () {
      const format = Ufract16();
      final view = scale.viewOf(format.binaryRange.max) + halfLsb;
      expect(scale.dataOf(view), format.binaryRange.max + 1);
      expect(BinaryQuantityCodec<num>.of(format, conversion: scale.conversion).encode(view), format.binaryRange.max);
    });

    test('half an LSB below the bottom of an Int16 range encodes to binaryRange.min', () {
      const format = Fract16();
      final view = scale.viewOf(format.binaryRange.min) - halfLsb;
      expect(scale.dataOf(view), format.binaryRange.min - 1);
      expect(BinaryQuantityCodec<num>.of(format, conversion: scale.conversion).encode(view), format.binaryRange.min);
    });
  });
}
