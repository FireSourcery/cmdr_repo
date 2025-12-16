import 'dart:ffi';
import 'dart:typed_data';

export 'dart:ffi';
export 'dart:typed_data';

/// [StructField]/[NativeKey]/[StructKey], Typed 0,1,2,4,8 bytes
///
/// Using [NativeType] as type marker
///
/// Field for
///   [ByteStruct] - backed by [TypedData]
///   [WordStruct] - backed by [Bits/int]
///
/// mixin can be applied to enum
/// implements Field<int>
abstract mixin class TypedField<T extends NativeType> {
  const TypedField._();
  // const factory TypedField(int offset) = TypedOffset<T>;

  int get offset; // index of the first byte

  int get size => _sizeOf<T>();
  int get end => offset + size; // index of the last byte + 1

  /// [ByteStruct]
  /// Primarily for offsets > word length
  // call passing T
  // Although handling of keyed access is preferable in the data source class.
  // T must handled in it's local scope. No type inference when passing `Field` to ByteData
  // int getWord(ByteData byteData) => byteData.wordAt<T>(offset);
  // void setWord(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);
  // bool testWordBoundsOf(ByteData byteData) => end <= byteData.lengthInBytes;

  //
  // int? getWordOrNull(ByteData byteData) => byteData.wordOrNullAt<T>(offset);
  // bool setWordOrNot(ByteData byteData, int value) => byteData.setWordOrNotAt<T>(offset, value);

  /// [WordStruct/BitStruct]
  // Bitmask asBitmask() => Bitmask.bytes(offset, size);
  // Bitmask bitmaskOf<T extends NativeType>(int offset) => Bitmask.bytes(offset, _sizeOf<T>());
  //  int ofBits(Bits bits) =>  bits.getInt(offset, size);

  @override
  int get defaultValue => 0;
}

// class TypedOffset<T extends NativeType> with TypedField<T> {
//   const TypedOffset(this.offset);
//   @override
//   final int offset;
// }

////////////////////////////////////////////////////////////////////////////////
/// Word value
////////////////////////////////////////////////////////////////////////////////
int _sizeOf<T extends NativeType>() {
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

extension ByteDataTypedWord on ByteData {
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

  int? wordOrNullAt<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) {
    return (byteOffset + _sizeOf<R>() <= lengthInBytes) ? wordAt<R>(byteOffset, endian) : null;
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

  bool setWordOrNotAt<R extends NativeType>(int byteOffset, int value, [Endian endian = Endian.little]) {
    if (byteOffset + _sizeOf<R>() <= lengthInBytes) {
      setWordAt(byteOffset, value, endian);
      return true;
    }
    return false;
  }
}

/// General case, without NativeType
/// `Partition`
// abstract mixin class SizedField {
//   // const SizedField._();
//   // const factory SizedField(int offset, int size) = _SizedField;

//   int get offset;
//   int get size;
//   int get end => offset + size;
// }

// class Part {
//   const Part(this.offset, this.size);
//   // const Part.length(this.offset, this.size);
//   // const Part.end(this.offset, this.size);
//   final int offset;
//   final int size;
//   // final int end;
// }
