import 'package:struct_data/binary_format/binary_format.dart';
import 'package:test/test.dart';

void main() {
  group('Angle16 encode rounds to nearest word', () {
    test('0.3 turn is 19661 (19660.8 words)', () {
      expect(const Angle16().encode(0.3), 19661);
    });

    test('a value just under fullScale wraps to 0, not 65536', () {
      expect(const Angle16().encode(1.0 - 1e-6), 0);
      expect(const Angle16Deg().encode(360.0 - 1e-4), 0);
    });

    test('a value half a word or more above zero rounds up to 1', () {
      expect(const Angle16().encode(0.6 / 65536), 1);
    });

    test('the encoded word stays in 0..65535', () {
      for (final value in [0.0, 0.25, 0.9999, 0.99999, 0.999999, 1.0 - 1e-12]) {
        expect(const Angle16().encode(value), inInclusiveRange(0, 65535));
      }
    });

    test('degrees displayed at 4 dp re-encode to the original word', () {
      const format = Angle16Deg();
      for (var word = 0; word < 65536; word += 7) {
        expect(format.encode(double.parse(format.decode(word).toStringAsFixed(4))), word);
      }
    });
  });
}
