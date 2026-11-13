import 'package:struct_data/struct_data.dart';
import 'package:test/test.dart';

enum StatusField(
  @override
  final Bitmask bitmask) with BitField {
  ready(Bitmask(0, 1)),
  mode(Bitmask(1, 3))
  ;

}

class const StatusBits(@override final List<StatusField> keys, super.bitData) extends BitStructBase<StatusBits, StatusField> {
  @override
  StatusBits copyWithData(BitStruct<StatusField> data) => StatusBits(keys, ConstBits(data.bits));
}

void main() {
  group('operator == accepts any Object', () {
    test('BitData', () => expect((const ConstBits(Bits(1)) as Object) == 'x', isFalse));
    test('BitStructBase', () => expect((StatusBits(StatusField.values, const ConstBits(Bits(1))) as Object) == 'x', isFalse));
    test('Version', () => expect((const VersionStandard(0, 1, 2, 3) as Object) == 'x', isFalse));
    test('Version in a Set with foreign members', () => expect(<Object>{'x', const VersionStandard(0, 1, 2, 3)}.contains(const VersionStandard(0, 1, 2, 3)), isTrue));
  });

  test('equal bit structs with distinct key lists have equal hash codes', () {
    final a = StatusBits(StatusField.values, const ConstBits(Bits(5)));
    final b = StatusBits([...StatusField.values], const ConstBits(Bits(5)));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
