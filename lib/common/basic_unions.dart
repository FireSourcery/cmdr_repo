// class/Type
import 'package:cmdr/binary_data/bit_struct.dart';

import '../binary_data/bit_field.dart';
import '../binary_data/bool_struct.dart';
import 'basic_types.dart';

extension type const BitFieldClass<T extends BitField>(List<T> keys) implements List<Enum> {
  // BitFieldClass.union(List<Enum> keys) : this(keys); //union of BitStruct and BoolStruct

  BitFields resolve(BitsBase bitsBase) {
    return switch (T) {
      _ when TypeKey<T>().isSubtype<BoolField>() => ConstBoolStructWithKeys<T>(keys, bitsBase.bits),
      _ when TypeKey<T>().isSubtype<BitField>() => ConstBitStructWithKeys<T>(keys, bitsBase.bits),
      Type() => throw UnimplementedError(),
    };
  }
}

///
extension type const EnumClass<T extends Enum>(List<T> enumValues) implements List<Enum> {
  EnumClass.inUnion(Set<List<Enum>> enumValues) : this(enumValues.whereType<List<T>>().single);

  T resolve(int index) => enumValues[index];
  T? resolveOrNull(int? index) => index != null ? enumValues.elementAtOrNull(index) : null;
}
