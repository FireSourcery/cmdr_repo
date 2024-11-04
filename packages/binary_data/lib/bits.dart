library bits;

import "package:cmdr_common/basic_types.dart";

import "bits/bit_field.dart";
import "bits/bit_struct.dart";
import "bits/bool_struct.dart";

export "bits/bits.dart";
export "bits/bit_field.dart";
export "bits/bit_struct.dart";
export "bits/bool_struct.dart";

export "src/binary_format.dart";

export "word/word.dart";
export "word/word_struct.dart";

// export 'package:flutter/foundation.dart' hide BitField;

extension type const BitFieldClass<T extends BitField>(List<T> keys) implements List<Enum> {
  // BitFieldClass.union(List<Enum> keys) : this(keys); // union of BitStruct and BoolStruct

  BitFields resolve(BitsBase bitsBase) {
    return switch (T) {
      _ when TypeKey<T>().isSubtype<BoolField>() => ConstBoolStructWithKeys<T>(keys, bitsBase.bits),
      _ when TypeKey<T>().isSubtype<BitField>() => ConstBitStructWithKeys<T>(keys, bitsBase.bits),
      Type() => throw UnimplementedError(),
    };
  }
}
