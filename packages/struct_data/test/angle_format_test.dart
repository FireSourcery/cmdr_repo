import 'dart:math';

import 'package:struct_data/binary_format/binary_format.dart';
import 'package:test/test.dart';

void main() {
  group('Angle16', () {
    const format = Angle16();

    test('decode 0 returns 0.0', () {
      expect(format.decode(0), 0.0);
    });

    test('decode max returns near 1.0', () {
      expect(format.decode(65535), closeTo(1.0, 1 / 65536));
    });

    test('decode midpoint returns ~0.5', () {
      expect(format.decode(32768), closeTo(0.5, 1e-6));
    });

    test('encode 0.0 returns 0', () {
      expect(format.encode(0.0), 0);
    });

    test('encode 0.5 returns 32768', () {
      expect(format.encode(0.5), 32768);
    });

    test('encode wraps at fullScale (1.0 wraps to 0)', () {
      expect(format.encode(1.0), 0);
    });

    test('encode wraps values above fullScale', () {
      expect(format.encode(1.5), format.encode(0.5));
    });

    test('decode then encode round-trips', () {
      for (final raw in [0, 1, 100, 16384, 32768, 65535]) {
        expect(format.encode(format.decode(raw)), raw);
      }
    });

    test('scalingFactor is 65536', () {
      expect(format.scalingFactor, 65536);
    });

    test('fullScale is 1.0', () {
      expect(format.fullScale, 1.0);
    });
  });

  group('SAngle16', () {
    const format = SAngle16();

    test('decode 0 returns 0.0', () {
      expect(format.decode(0), 0.0);
    });

    test('decode 0x7FFF (positive max) returns near 0.5', () {
      expect(format.decode(0x7FFF), closeTo(0.5, 1 / 65536));
    });

    test('decode 0x8000 (as unsigned) sign-extends to negative', () {
      // 0x8000 unsigned = 32768, sign-extended to -32768
      expect(format.decode(0x8000), closeTo(-0.5, 1e-6));
    });

    test('encode 0.0 returns 0', () {
      expect(format.encode(0.0), 0);
    });

    test('scalingFactor is 65536', () {
      expect(format.scalingFactor, 65536);
    });
  });

  group('Angle16Deg', () {
    const format = Angle16Deg();

    test('fullScale is 360.0', () {
      expect(format.fullScale, 360.0);
    });

    test('decode 0 returns 0.0 degrees', () {
      expect(format.decode(0), 0.0);
    });

    test('decode max returns near 360.0', () {
      expect(format.decode(65535), closeTo(360.0, 360.0 / 65536));
    });

    test('decode midpoint returns ~180.0 degrees', () {
      expect(format.decode(32768), closeTo(180.0, 1e-3));
    });

    test('decode quarter returns ~90.0 degrees', () {
      expect(format.decode(16384), closeTo(90.0, 1e-3));
    });

    test('encode 0.0 returns 0', () {
      expect(format.encode(0.0), 0);
    });

    test('encode 180.0 returns 32768', () {
      expect(format.encode(180.0), 32768);
    });

    test('encode 90.0 returns 16384', () {
      expect(format.encode(90.0), 16384);
    });

    test('encode wraps at 360.0', () {
      expect(format.encode(360.0), 0);
    });

    test('encode wraps above 360.0', () {
      expect(format.encode(450.0), format.encode(90.0));
    });

    test('decode then encode round-trips', () {
      for (final raw in [0, 1, 100, 16384, 32768, 65535]) {
        expect(format.encode(format.decode(raw)), raw);
      }
    });
  });

  group('Angle16Rad', () {
    const format = Angle16Rad();

    test('fullScale is 2*pi', () {
      expect(format.fullScale, closeTo(2 * pi, 1e-10));
    });

    test('decode 0 returns 0.0 radians', () {
      expect(format.decode(0), 0.0);
    });

    test('decode max returns near 2*pi', () {
      expect(format.decode(65535), closeTo(2 * pi, 2 * pi / 65536));
    });

    test('decode midpoint returns ~pi radians', () {
      expect(format.decode(32768), closeTo(pi, 1e-3));
    });

    test('decode quarter returns ~pi/2 radians', () {
      expect(format.decode(16384), closeTo(pi / 2, 1e-3));
    });

    test('encode 0.0 returns 0', () {
      expect(format.encode(0.0), 0);
    });

    test('encode pi returns ~32768', () {
      expect(format.encode(pi), closeTo(32768, 1));
    });

    test('encode pi/2 returns ~16384', () {
      expect(format.encode(pi / 2), closeTo(16384, 1));
    });

    test('encode wraps at 2*pi', () {
      expect(format.encode(2 * pi), 0);
    });

    test('decode then encode round-trips', () {
      for (final raw in [0, 1, 100, 16384, 32768, 65535]) {
        expect(format.encode(format.decode(raw)), raw);
      }
    });
  });
}
