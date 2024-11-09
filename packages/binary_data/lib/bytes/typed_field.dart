import 'dart:ffi';
import 'dart:typed_data';
export 'dart:ffi';
export 'dart:typed_data';

/// [StructField]/[TypedField]/[StructKey], Typed 0,1,2,4,8 bytes
///
/// Using [NativeType] as type marker
///
/// Field for
///   [ByteStruct] - backed by [TypedData]
///   [WordStruct] - backed by [int]
///
/// mixin can be applied to enum
abstract mixin class TypedField<T extends NativeType> {
  const TypedField._();
  const factory TypedField(int offset) = TypedOffset<T>;

  int get offset;

  int get size => sizeOf<T>();
  int get end => offset + size; // index of last byte + 1
  // int get valueMax => (1 << width) - 1);

  // static Bitmask bitmaskOf<T extends NativeType>(int offset) => Bitmask.bytes(offset, sizeOf<T>());
  // Bitmask asBitmask() => Bitmask.bytes(offset, size);

  /// [ByteStruct]
  // call passing T
  // Although handling of keyed access is preferable in the data source class. It is clearer here.

  // replaced by ffi.Struct
  int valueOf(ByteData byteData) => byteData.wordAt<T>(offset);
  void setValueOf(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);
  // not yet replaceable
  int? valueOrNullOf(ByteData byteData) => byteData.wordAtOrNull<T>(offset);
  bool updateValueOf(ByteData byteData, int value) => byteData.updateWordAt<T>(offset, value);
}

// class _TypedField<T extends NativeType> extends TypedField<T> {
//   const _TypedField(this.offset) : super._();
//   @override
//   final int offset;
// }

// extension type TypedOffset1<T extends NativeType>(int offset) {}

class TypedOffset<T extends NativeType> with TypedField<T> {
  const TypedOffset(this.offset);

  @override
  final int offset;
}

////////////////////////////////////////////////////////////////////////////////
/// Word value
////////////////////////////////////////////////////////////////////////////////
int sizeOf<T extends NativeType>() {
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

extension GenericTypedWord on ByteData {
  /// valueAt by type, alternatively specify sign and size
  /// throws range error
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

  int? wordAtOrNull<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) {
    return (byteOffset + sizeOf<R>() <= lengthInBytes) ? wordAt<R>(byteOffset, endian) : null;
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

  bool updateWordAt<R extends NativeType>(int byteOffset, int value, [Endian endian = Endian.little]) {
    if (byteOffset + sizeOf<R>() <= lengthInBytes) {
      setWordAt(byteOffset, value, endian);
      return true;
    }
    return false;
  }
}

// /// General case, without NativeType
// /// `Partition`
// abstract mixin class Part {
//   // const Part._();
//   const factory Part(int offset, int size) = _Part;
//   int get offset;
//   int get size;

//   int get end => offset + size;

//   List<int> arrayOf<R extends TypedData>(TypedData typedList) => typedList.sublistViewOrEmpty<R>(offset, size);
// }

// class _Part with Part {
//   const _Part(this.offset, this.size);
//   @override
//   final int offset;
//   @override
//   final int size;
// }
