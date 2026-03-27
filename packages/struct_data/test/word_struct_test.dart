import 'package:struct_data/models/version.dart';
import 'package:struct_data/word/word_struct.dart';
import 'package:test/test.dart';

enum SerialNumberField with TypedField<Uint8>, WordField<Uint8> {
  sn0(0),
  sn1(1),
  sn2(2),
  sn3(3)
  ;

  const SerialNumberField(this.offset);
  @override
  final int offset;
}

void main() {
  const serialNumber = Version.withType(SerialNumberField.values, name: 'Serial Number');

  group('WordStruct', () {
    test('default Version fields are all zero', () {
      expect(serialNumber[SerialNumberField.sn0], 0);
      expect(serialNumber[SerialNumberField.sn1], 0);
      expect(serialNumber[SerialNumberField.sn2], 0);
      expect(serialNumber[SerialNumberField.sn3], 0);
      expect(serialNumber.toStringAsVersion(), '0.0.0.0');
    });

    test('copyWithData replaces underlying word', () {
      final updated = serialNumber.copyWithData(WordStruct(12345678 as Word));
      expect(updated.toStringAsVersion(), '0.188.97.78');
    });

    test('withField chains produce correct field values', () {
      final updated = serialNumber.withField(.sn0, 1).withField(.sn1, 2).withField(.sn2, 3).withField(.sn3, 4);
      expect(updated[.sn0], 1);
      expect(updated[.sn1], 2);
      expect(updated[.sn2], 3);
      expect(updated[.sn3], 4);
      expect(updated.toStringAsVersion(), '4.3.2.1');
    });

    test('toJsonVerbose serializes all fields', () {
      final json = serialNumber.toJsonVerbose();
      expect(json, {'sn0': 0, 'sn1': 0, 'sn2': 0, 'sn3': 0});
    });
  });
}
