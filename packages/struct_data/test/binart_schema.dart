import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:struct_data/binary_data.dart';

abstract class BinarySchema {
  const BinarySchema();
  Map<ByteField, BinaryFormat> get fieldFormats;

  ByteStruct cast(TypedData typedData);
  // Map<ByteField, Num> cast(TypedData typedData); // num/Enum/BitStruct
}

abstract interface class BinaryField implements ByteField {
  BinaryFormat get format;
}

// alternative to ffi.Struct def
abstract mixin class Binarizable implements StructBase<Binarizable, BinaryField, Object?> {
  const Binarizable();
  // List<ByteField> get fields;

  ByteStruct toBinary() {
    final data = ByteStruct(ByteData(keys.fold(0, (sum, field) => sum + field.size)));

    for (final key in keys) {
      data[key] = key.format.encode(this[key]);
    }
    return data;
  }

  Map<ByteField, Object?> fromBinary(ByteStruct binary) {
    return <ByteField, Object?>{for (final key in keys) key: key.format.decode(binary[key])};
  }
}

extension type const Num<V>(V value) {
  Num.from(BinaryFormat<NativeType, V> format, int data) : value = format.decode(data);
}

// sealed class Num<V> {
//   const Num();
// }

// class NumEnum extends Num<Enum> {
//   const NumEnum();
// }

// class NumDouble extends Num<double> {
//   const NumDouble();
// }
