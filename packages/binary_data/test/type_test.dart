import 'package:test/test.dart';

import 'package:binary_data/bytes/byte_struct.dart';

extension type const TypeTest<T extends NativeType>._(({Type t, int offset}) a) {
  int get size => sizeOf<T>();
}

class TypeTest2<T extends NativeType> {
  TypeTest2(this.offset);
  final int offset;
  int get size => sizeOf<T>();
}

void main() {
  test('type_test', () {
    final t1 = TypeTest<Uint16>(4);
    final t2 = TypeTest2<Uint16>(3);
    print(t1.runtimeType);
    print(t2.runtimeType);

    TypedArray array = TypedArray<Uint16List>(10)..asThis.setAll(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    print(array);
    print(array.typeKey);
    print(array.asThis.seek(3));

    expect(array.lengthInBytes, 20);
  });
}
