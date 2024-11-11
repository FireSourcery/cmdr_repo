import 'package:cmdr_common/enum_map.dart';

import "bit_struct.dart";
import "bool_struct.dart";

// export 'package:flutter/foundation.dart' hide BitField;

// EnumMapFactory<S extends EnumMap<K, V>, K extends EnumKey, V>

// union of BitStruct and BoolStruct
extension type const BitFieldClass<S extends BitsMap<K, V>, K extends BitFieldKey, V>(List<K> keys) implements EnumMapFactory<S, K, V> {
  // BitFieldClass.union(List<Enum> keys) : this(keys);

  // S castBase(EnumMap<K, V> state) => state as S;

  BitsMap resolve(BitsBase bitsBase) {
    return switch (keys) {
      List<BitsIndexKey>() => ConstBoolStructWithKeys<K>(keys, bitsBase.bits),
      List<BitsKey>() => ConstBitStructWithKeys<K>(keys, bitsBase.bits),
    };
  }
}
