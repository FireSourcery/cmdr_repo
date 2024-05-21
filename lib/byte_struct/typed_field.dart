import 'dart:ffi';
import 'dart:typed_data';

import 'byte_struct.dart';
import 'typed_data_ext.dart';
import 'word.dart';

import 'package:ffi/ffi.dart';

export 'dart:ffi';
export 'dart:typed_data';

/// General case
/// `Partition`
// abstract mixin class Part {
//   // const Part._();
//   const factory Part(int offset, int size) = _Part;
//   int get offset;
//   int get size;

//   int get end => offset + size;

//   List<int> typedListOf<R extends TypedData>(TypedData typedList) => typedList.sublistViewOrEmpty<R>(offset, size);

//   int valueOfTypedData(ByteData byteData) => byteData.uintAt(offset, size);
//   int valueOfInt(int intData) => intData.valueAt(offset, size);
// }

// class _Part with Part {
//   const _Part(this.offset, this.size);
//   @override
//   final int offset;
//   @override
//   final int size;
// }

/// TypedField, Typed 0-8 bytes
abstract mixin class TypedField<T extends NativeType> {
  const TypedField._();
  const factory TypedField(int offset) = TypedOffset<T>;

  int get offset;
  int get size => sizeOf<T>();
  int get end => offset + size; // index of last byte + 1

  // call with offset with T
  // replace with struct
  int fieldValue(ByteData byteData) => byteData.wordAt<T>(offset);
  void setFieldValue(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);
  int? fieldValueOrNull(ByteData byteData) => byteData.wordAtOrNull<T>(offset);

  // necessary to keep Word compile time const
  int valueOfInt(int intData) => intData.wordAt<T>(offset);

  // List<int> typedListOf<R extends TypedData>(TypedData typedList) => typedList.sublistViewOrEmpty<R>(offset, size);
}

// class _TypedField<T extends NativeType> extends TypedField<T> {
//   const _TypedField(this.offset) : super._();
//   @override
//   final int offset;
// }

class TypedOffset<T extends NativeType> extends TypedField<T> {
  const TypedOffset(this.offset) : super._();

  @override
  final int offset;
}

/// interface for including [TypedField<T>], [Enum]
abstract interface class NamedField<T extends NativeType> implements TypedField<T>, Enum {}
