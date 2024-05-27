import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../common/enum_map.dart';
import 'byte_struct.dart';
import 'typed_data_ext.dart';
import 'int_ext.dart';

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
// List<int> typedListOf<R extends TypedData>(TypedData typedList) => typedList.sublistViewOrEmpty<R>(offset, size);

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

// abstract mixin class Field<V> implements Enum {
//   const Field();
//   Type get type => V;
//   bool compareType(Object? object) => object is V;
//   V get(EnumMap enumMap) => enumMap[this] as V;
//   void set(EnumMap enumMap, V value) => enumMap[this] = value;
//   EnumMap asModified(EnumMap enumMap, V value) => enumMap.copyWithEntry(this, value);
// }

/// TypedField, Typed 0-8 bytes
abstract mixin class TypedField<T extends NativeType> {
  const TypedField._();
  const factory TypedField(int offset) = TypedOffset<T>;

  int get offset;
  int get size => sizeOf<T>();
  int get end => offset + size; // index of last byte + 1

  // call with offset with T
  // replaced by struct
  int valueOf(ByteData byteData) => byteData.wordAt<T>(offset);
  void setValueOf(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);
  // not yet replaceable
  int? valueOrNullOf(ByteData byteData) => byteData.wordOrNullAt<T>(offset);

  // necessary to keep Word compile time const
  int valueOfInt(int intData) => intData.bytesAt(offset, sizeOf<T>());
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

// /// interface for including [TypedField<T>], [Enum]
// abstract interface class NamedField<T extends NativeType> implements TypedField<T>, Enum {}


// // add operator [] to ByteStructBase
// abstract class TypedFields<T extends NamedField> extends ByteStructBase with MapBase<T, int>, EnumMap<T, int> {
//   TypedFields(super.bytes);

//   // TypedFields._();
//   // factory TypedFields(int value) = TypedFieldsValue<T>;

//   int operator [](T field) => field.valueOf(byteData);
//   void operator []=(T field, int? value);
//   void clear();
// }
