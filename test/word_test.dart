import 'dart:typed_data';

import 'package:cmdr/byte_struct.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmdr/byte_struct/word.dart';

void main() {
  List<int> list = [65, 66, 67, 68];
  // String string = 'ABCD'; // 65, 66, 67, 68
  String string = String.fromCharCodes(list);

  test('test', () {
    print(string.codeUnits);
    print(string.runes);
    print(Word.string(string).asString);
    print(Word.bytes(list));
    print(Word.bytes(string.runes));
    print(Word.msb32(68, 67, 66, 65));
  });
}
