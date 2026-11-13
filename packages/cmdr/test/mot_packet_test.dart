import 'dart:typed_data';

import 'package:cmdr/connection/mot_connection/mot_packet.dart';
import 'package:flutter_test/flutter_test.dart';

MemWriteRequestValues _write(int size, {int? dataLength}) => (address: 0x100, size: size, config: 3, data: Uint8List.fromList(List.generate(dataLength ?? size, (i) => i + 1)));

/// A plain [ArgumentError]: a [RangeError] from indexing past the data is a subtype, and not the validation.
final _invalidRequest = throwsA(isA<ArgumentError>().having((e) => e is RangeError, 'is RangeError', false));

void main() {
  group('MemWriteRequest.build', () {
    late Uint8List buffer;
    setUp(() => buffer = Uint8List(64));

    test('a 16-byte write succeeds in a buffer left dirty by a 32-byte read', () {
      MemReadRequest.cast(buffer).build((address: 0, size: 32, config: 0));

      final meta = MemWriteRequest.cast(buffer).build(_write(16));

      expect(meta.length, 16 + 8);
      expect(buffer[4], 16);
      expect(buffer.sublist(8, 24), List.generate(16, (i) => i + 1));
    });

    test('an oversize request throws an ArgumentError naming the size', () {
      expect(
        () => MemWriteRequest.cast(buffer).build(_write(20)),
        throwsA(isA<ArgumentError>().having((e) => e is RangeError, 'is RangeError', false).having((e) => e.toString(), 'message', contains('20'))),
      );
    });

    test('a negative size throws', () {
      expect(() => MemWriteRequest.cast(buffer).build(_write(-1, dataLength: 0)), _invalidRequest);
    });

    test('data shorter than size throws ArgumentError, not RangeError', () {
      expect(() => MemWriteRequest.cast(buffer).build(_write(8, dataLength: 4)), _invalidRequest);
    });

    test('data longer than size writes only size bytes', () {
      final meta = MemWriteRequest.cast(buffer).build(_write(4, dataLength: 16));

      expect(meta.length, 4 + 8);
      expect(buffer.sublist(8, 13), [1, 2, 3, 4, 0]);
    });
  });
}
