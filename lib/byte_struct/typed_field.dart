import 'dart:ffi';
import 'dart:typed_data';

import 'package:recase/recase.dart';

import '../common/enum_map.dart';
import 'byte_struct.dart';
import 'word.dart';

export 'dart:ffi';
export 'dart:typed_data';

abstract mixin class TypedField<T extends NativeType> {
  const TypedField();

  int get offset;
  int get size => sizeOf<T>();
  int get end => offset + size; // index of last byte + 1

  // call with offset with T
  // replace with struct
  int fieldValue(ByteData byteData) => byteData.wordAt<T>(offset);
  int? fieldValueOrNull(ByteData byteData) => byteData.wordAtOrNull<T>(offset);
  void setFieldValue(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);

  // necessary to keep Word compile time const
  int valueOfInt(int intData) => intData.valueTypedAt<T>(offset);
}

/// interface for including [TypedField<T>], [Enum]
abstract interface class NamedField<T extends NativeType> implements TypedField<T>, Enum {}
