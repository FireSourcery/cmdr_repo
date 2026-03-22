import 'package:binary_data/models/version.dart';
import 'package:binary_data/word/word_struct.dart';
import 'package:test/test.dart';

enum SerialNumberField with TypedField<Uint8>, WordField<Uint8> {
  sn0(0),
  sn1(1),
  sn2(2),
  sn3(3);

  const SerialNumberField(this.offset);
  @override
  final int offset;
}

void main() {
  final serialNumber = const Version.withType(SerialNumberField.values, name: 'Serial Number');

  test('word_Struct_test', () {
    print(serialNumber);
    print(serialNumber.copyWithData(WordStruct(12345678 as Word)));
    print(serialNumber.withField(SerialNumberField.sn0, 1).withField(SerialNumberField.sn1, 2).withField(SerialNumberField.sn2, 3).withField(SerialNumberField.sn3, 4));
    print(serialNumber.toJsonVerbose());
  });
}
