import 'package:struct_data/binary_format/binary_format.dart';
import 'package:test/test.dart';

void main() {
  group('Angle16 encode wraps within the word', () {
    test('every value in [0, 1) encodes within 0..65535', () {
      for (final value in [0.0, 0.25, 0.5, 0.9999, 0.99999, 0.999999, 1.0 - 1e-12]) {
        expect(const Angle16().encode(value), inInclusiveRange(0, 65535), reason: '$value');
      }
    });

    test('a negative value wraps into 0..65535', () {
      for (final value in [-0.25, -1e-12, -1.0 - 1e-6]) {
        expect(const Angle16().encode(value), inInclusiveRange(0, 65535), reason: '$value');
      }
    });

    test('a negative value whose remainder rounds to a full turn encodes the full turn, which the device wraps to 0', () {
      expect(const Angle16().encode(-1e-17), 65536);
    });

    test('0.5 encodes to 32768', () {
      expect(const Angle16().encode(0.5), 32768);
    });
  });
}
