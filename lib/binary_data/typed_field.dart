import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../common/fixed_map.dart';
import 'byte_struct.dart';
import 'typed_data_ext.dart';
import 'bits.dart';

export 'dart:ffi';
export 'dart:typed_data';

/// Field for [ByteStruct], and [WordFields]
/// TypedField, Typed 0-8 bytes
abstract mixin class TypedField<T extends NativeType> {
  const TypedField._();
  const factory TypedField(int offset) = TypedOffset<T>;

  int get offset;
  int get size => sizeOf<T>();
  int get end => offset + size; // index of last byte + 1

  // int get valueRange => 1 << (size * 8);

  /// [ByteStruct]
  // call with offset with T
  // replaced by struct
  int valueOf(ByteData byteData) => byteData.wordAt<T>(offset);
  void setValueOf(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);
  // not yet replaceable
  int? valueOrNullOf(ByteData byteData) => byteData.wordOrNullAt<T>(offset);

  /// [WordFields]
  // necessary to keep Word compile time const
  int valueOfWord(int source) => source.bytesAt(offset, size);
  int modifyWord(int source, int value) => source.modifyBytes(offset, size, value);
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



// /// General case, without NativeType
// /// `Partition`
// abstract mixin class Part {
//   // const Part._();
//   const factory Part(int offset, int size) = _Part;
//   int get offset;
//   int get size;

//   int get end => offset + size;

// //   List<int> typedListOf<R extends TypedData>(TypedData typedList) => typedList.sublistViewOrEmpty<R>(offset, size);
// // List<int> typedListOf<R extends TypedData>(TypedData typedList) => typedList.sublistViewOrEmpty<R>(offset, size);

// //   int valueOfTypedData(ByteData byteData) => byteData.uintAt(offset, size);
// //   int valueOfInt(int intData) => intData.valueAt(offset, size);
// }

// class _Part with Part {
//   const _Part(this.offset, this.size);
//   @override
//   final int offset;
//   @override
//   final int size;
// }
