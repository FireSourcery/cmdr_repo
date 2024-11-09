import 'package:test/test.dart';

import 'package:binary_data/bytes/byte_struct.dart';

void main() {
  test('type_test', () {
    TypedArray array = TypedArray<Uint16List>(10)..asThis.setAll(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    print(array);
    print(array.typeKey);
    print(array.asThis.seek(3));

    expect(array.lengthInBytes, 20);
  });
}
