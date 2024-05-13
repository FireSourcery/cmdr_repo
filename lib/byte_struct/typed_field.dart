import 'dart:ffi';
import 'dart:typed_data';

import 'byte_struct.dart';
import 'word.dart';

export 'dart:ffi';
export 'dart:typed_data';

abstract mixin class TypedField<T extends NativeType> {
  const TypedField();

  int get offset;
  int get size => sizeOf<T>();
  int get end => offset + size; // index of last byte + 1

  // int call(ByteData byteData) => byteData.wordAt<T>(offset);
  // int? callOrNull(ByteData byteData) => byteData.wordAtOrNull<T>(offset);

  // call with offset with T
  int fieldValue(ByteData byteData) => byteData.wordAt<T>(offset);
  int? fieldValueOrNull(ByteData byteData) => byteData.wordAtOrNull<T>(offset);
  void setFieldValue(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);

  int valueOfInt(int intData) => intData.valueTypedAt<T>(offset);
}
