import 'dart:typed_data';

import 'package:struct_data/struct_data.dart';
import 'package:test/test.dart';

void main() {
  final view = ByteData.sublistView(Uint8List.fromList(List.generate(16, (i) => i)), 4, 8);

  group('arrayAt is bounded by the view', () {
    test('default length runs to the end of the view', () => expect(view.arrayAt<Uint8List>().length, 4));
    test('offset is relative to the view', () => expect(view.arrayAt<Uint8List>(1, 2), [5, 6]));
    test('length is in elements of T', () => expect(view.arrayAt<Uint16List>(0, 2).lengthInBytes, 4));
    test('past the view throws', () => expect(() => view.arrayAt<Uint8List>(0, 5), throwsRangeError));
  });

  group('arrayOrNullAt compares bytes with bytes', () {
    test('elements beyond the view return null', () => expect(ByteData(4).arrayOrNullAt<Uint16List>(0, 4), isNull));
    test('elements within the view return the array', () => expect(ByteData(4).arrayOrNullAt<Uint16List>(0, 2)?.length, 2));
  });

  group('type switches cover the 64-bit and clamped lists', () {
    test('bytesPerElementOf', () => expect([bytesPerElementOf<Uint8ClampedList>(), bytesPerElementOf<Uint64List>(), bytesPerElementOf<Int64List>()], [1, 8, 8]));
    test('typedList', () => expect([typedList<Uint8ClampedList>(2), typedList<Uint64List>(2), typedList<Int64List>(2)].map((e) => e.lengthInBytes), [2, 16, 16]));
    test('arrayAt', () => expect(ByteData(16).arrayAt<Int64List>(8).length, 1));
  });
}
