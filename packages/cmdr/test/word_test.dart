import 'package:flutter_test/flutter_test.dart';

import '../../binary_data/lib/src/binary_data/word.dart';
// enum Tester {
//   b1(value: Bits(1)),
//   ;

//   const Tester({required this.value});

//   final Bits value;
// }

void main() {
  List<int> list = [65, 66, 67, 68];
  // String string = 'ABCD'; // 65, 66, 67, 68
  String string = String.fromCharCodes(list);

  test('test', () {
    print(string.codeUnits);
    print(string.runes);
    print(Word.string(string).asString());
    // print(Word.bytes(list));
    // print(Word.bytes(string.runes));
    print(Word.msb32(68, 67, 66, 65));
  });
}
