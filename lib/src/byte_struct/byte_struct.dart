import 'dart:ffi';
import 'dart:typed_data';

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
/// a struct memeber
class TypedOffset<T extends NativeType> {
  const TypedOffset(this.offset);
  final int offset;

  int get size {
    return switch (T) {
      const (Int8) => 1,
      const (Int16) => 2,
      const (Int32) => 4,
      const (Uint8) => 1,
      const (Uint16) => 2,
      const (Uint32) => 4,
      _ => throw UnimplementedError(),
    };
  }

  int get end => offset + size; // 1 + index of last byte

  // call with offset with T
  int fieldValue(ByteData byteData) => byteData.wordAt<T>(offset);
  int? fieldValueOrNull(ByteData byteData) => byteData.wordAtOrNull<T>(offset);
  void setFieldValue(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);
}

// typedef ByteStructConstructor<T extends ByteStruct> = T Function();

// ByteStruct
mixin class ByteStruct {
  // factory ByteStruct.castWith(ByteStructConstructor child, TypedData data) => child().cast(data);

  ByteStruct cast(TypedData data) => (this..reference = data);

  TypedData reference = Uint8List(0);
  // TypedData get reference;
  // set reference(TypedData pointer);
  int get viewSize => reference.lengthInBytes;
  // int get size;

  ByteData get asByteData => reference.asByteData;

  TypedOffset<Uint8> start = const TypedOffset<Uint8>(0);
  // List<TypedOffset> get members;
}

// ByteStructFactory
abstract class ByteStructFactory<T extends ByteStruct> {
  ByteStruct create();
}

extension GenericSublistView on TypedData {
  ByteData get asByteData => ByteData.sublistView(this);
  // throws range error
  // offset uses "this" instance type, not R type
  List<int> sublistView<R extends TypedData>([int offset = 0]) {
    return switch (R) {
      const (Uint8List) => Uint8List.sublistView(this, offset),
      const (Uint16List) => Uint16List.sublistView(this, offset),
      const (Uint32List) => Uint32List.sublistView(this, offset),
      const (Int8List) => Int8List.sublistView(this, offset),
      const (Int16List) => Int16List.sublistView(this, offset),
      const (Int32List) => Int32List.sublistView(this, offset),
      const (ByteData) => Uint8List.sublistView(this, offset),
      _ => throw UnimplementedError(),
    };
  }

  List<int> sublistViewOrEmpty<R extends TypedData>([int byteOffset = 0]) => (byteOffset < lengthInBytes) ? sublistView<R>(byteOffset) : const <int>[];
}

extension TypedDataViews on TypedData {
  int get end => offsetInBytes + lengthInBytes; // 1 + index of last byte
}

extension GenericGetWord on ByteData {
  // throws range error
  int wordAt<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) {
    return switch (R) {
      const (Int8) => getInt8(byteOffset),
      const (Int16) => getInt16(byteOffset, endian),
      const (Int32) => getInt32(byteOffset, endian),
      const (Uint8) => getUint8(byteOffset),
      const (Uint16) => getUint16(byteOffset, endian),
      const (Uint32) => getUint32(byteOffset, endian),
      _ => throw UnimplementedError(),
    };
  }

  void setWordAt<R extends NativeType>(int byteOffset, int value, [Endian endian = Endian.little]) {
    return switch (R) {
      const (Int8) => setInt8(byteOffset, value),
      const (Int16) => setInt16(byteOffset, value, endian),
      const (Int32) => setInt32(byteOffset, value, endian),
      const (Uint8) => setUint8(byteOffset, value),
      const (Uint16) => setUint16(byteOffset, value, endian),
      const (Uint32) => setUint32(byteOffset, value, endian),
      _ => throw UnimplementedError(),
    };
  }

  int? wordAtOrNull<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) {
    final wordLength = switch (R) {
      const (Int8) => 1,
      const (Int16) => 2,
      const (Int32) => 4,
      const (Uint8) => 1,
      const (Uint16) => 2,
      const (Uint32) => 4,
      _ => throw UnimplementedError(),
    };
    return (byteOffset + wordLength <= lengthInBytes) ? wordAt<R>(byteOffset, endian) : null;
  }

  // int? wordAtElementIndex<R extends NativeType>(int elementOffset, [Endian endian = Endian.little]) {
  // }
}

// static int sizeOf<T extends NativeType>() {
//   return switch (T) {
//     const (Int8) => 1,
//     const (Int16) => 2,
//     const (Int32) => 4,
//     const (Uint8) => 1,
//     const (Uint16) => 2,
//     const (Uint32) => 4,
//     _ => throw UnimplementedError(),
//   };
// }
