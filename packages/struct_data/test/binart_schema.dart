import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:struct_data/binary_data.dart';

abstract class BinarySchema {
  const BinarySchema();
  Map<ByteField, BinaryFormat> get fieldFormats;

  ByteStruct cast(TypedData typedData);
  // Map<ByteField, Num> cast(TypedData typedData); // num/Enum/BitStruct
}

abstract interface class BinaryField<S extends NativeType, V> implements ByteField<S> {
  BinaryFormat<S, V> get format;
}

// extension type const BinaryForm(List<)
extension B<K extends BinaryField> on ByteForm<K> {
  ({StructForm<K, int> type, StructData<K, int> data}) _create() => this(create());

  Map<ByteField, Object?> fromBinary(ByteStruct binary) => {for (final key in fields) key: key.format.decode(binary[key])};
}

// extension<K extends BinaryField<NativeType, V>, V extends Object?> on ({StructForm<K, V> type, StructData<K, V> data}) {
//   Iterable<int> get valuesInBinary => type.map((e) => e.format.encode(data[e]));
// }

// alternative to ffi.Struct def
abstract mixin class Binarizable<K extends BinaryField<NativeType, Object?>> implements StructBase<Binarizable<K>, K, Object?> {
  const Binarizable();

  ByteForm<K> get type;
  Iterable<int> get valuesInBinary => keys.map((e) => e.format.encode(this[e]));

  ByteStruct toBinary() {
    // ByteForm(keys).create
    final data = ByteStruct<K>(ByteData(type.size));
    for (final key in keys) {
      data[key] = key.format.encode(this[key]);
    }
    return data;
  }

  Map<ByteField, Object?> fromBinary(ByteStruct binary) => <ByteField, Object?>{for (final key in keys) key: key.format.decode(binary[key])};
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
