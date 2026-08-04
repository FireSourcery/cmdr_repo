import 'dart:typed_data';
import 'dart:ffi';

export '../src/type_markers.dart';

/// [StructField]/[NativeKey]/[StructKey], Typed 0,1,2,4,8 bytes
///
/// Using [NativeType] as type marker
///
/// Field for
///   [ByteStruct] - backed by [TypedData]
///   [WordStruct] - backed by [Bits/int]
///
/// mixin can be applied to enum
abstract mixin class TypedField<T extends NativeType> {
  const TypedField._();
  // const factory TypedField(int offset) = TypedOffset<T>;

  int get offset; // index of the first byte

  int get size => _sizeOf<T>();
  int get end => offset + size; // index of the last byte + 1

  int get valueMax => (1 << size * 8) - 1;
  int get defaultValue => 0;

  /// [ByteStruct] access. Width comes from [T] — dispatches per key without the caller naming a width.
  int getWord(ByteData byteData, [Endian endian = Endian.little]) => byteData.wordAt<T>(offset, endian);
  void setWord(ByteData byteData, int value, [Endian endian = Endian.little]) => byteData.setWordAt<T>(offset, value, endian);
  bool testWordBoundsOf(ByteData byteData) => end <= byteData.lengthInBytes;
  int? getWordOrNull(ByteData byteData, [Endian endian = Endian.little]) => byteData.wordOrNullAt<T>(offset, endian);
  bool setWordOrNot(ByteData byteData, int value, [Endian endian = Endian.little]) => byteData.setWordOrNotAt<T>(offset, value, endian);
}

///
/// Word value
///
int _sizeOf<T extends NativeType>() {
  return switch (T) {
    const (Int8) || const (Uint8) => 1,
    const (Int16) || const (Uint16) => 2,
    const (Int32) || const (Uint32) => 4,
    const (Int64) || const (Uint64) => 8,
    _ => throw UnimplementedError(),
  };
}

extension ByteDataWordAccess on ByteData {
  /// valueAt by type, alternatively specify sign and size
  /// throws range error
  int wordAt<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) {
    return switch (R) {
      const (Int8) => getInt8(byteOffset),
      const (Int16) => getInt16(byteOffset, endian),
      const (Int32) => getInt32(byteOffset, endian),
      const (Int64) => getInt64(byteOffset, endian),
      const (Uint8) => getUint8(byteOffset),
      const (Uint16) => getUint16(byteOffset, endian),
      const (Uint32) => getUint32(byteOffset, endian),
      const (Uint64) => getUint64(byteOffset, endian), // Dart int is signed 64; 0xFFFF... reads as -1
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
      const (Int64) => setInt64(byteOffset, value, endian),
      const (Uint8) => setUint8(byteOffset, value),
      const (Uint16) => setUint16(byteOffset, value, endian),
      const (Uint32) => setUint32(byteOffset, value, endian),
      const (Uint64) => setUint64(byteOffset, value, endian),
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


/// Segment codec. [pack] and [unpack] are inverses, keyed by the field layout.
///
/// Bound on [TypedField] rather than a view-aware key: serialization needs only the offset and the
/// width, so a composite whose view side is not a keyed map can use these too.
/// Each key resolves its own width from its `T`, so one struct may mix `Uint16` and `Uint64` slots.
extension TypedFieldLayout<K extends TypedField> on List<K> {
  /// Extent of the declared fields. May be less than the containing segment.
  int get lengthInBytes => fold<int>(0, (extent, key) => key.end > extent ? key.end : extent);

  Map<K, int> unpack(TypedData data, [Endian endian = Endian.little]) {
    final buffer = ByteData.sublistView(data);
    if (buffer.lengthInBytes < lengthInBytes) throw const FormatException('TypedField: short buffer');
    return {for (final key in this) key: key.getWord(buffer, endian)};
  }
}

extension TypedFieldWords<K extends TypedField> on Map<K, int> {
  /// Place each word at its own offset. Bytes no key covers — reserved space, and the gaps of a
  /// sparse layout — keep [unwrittenByte]; `0xFF` matches erased NOR flash.
  Uint8List pack(int lengthInBytes, [int unwrittenByte = 0xFF, Endian endian = Endian.little]) {
    final bytes = Uint8List(lengthInBytes)..fillRange(0, lengthInBytes, unwrittenByte);
    final buffer = ByteData.sublistView(bytes);
    for (final MapEntry(:key, :value) in entries) {
      key.setWord(buffer, value, endian);
    }
    return bytes;
  }
}

// still to move onto TypedField, they need Bitmask/BitData in scope
// extension TypedFieldMethods<T extends NativeType> on TypedField<T> {
//   /// [WordStruct/BitStruct]
//   Bitmask asBitmask() => Bitmask.bytes(offset, size);
//   int getBits(BitData data) => bits.getInt(offset, size);
// }

// // class TypedOffset<T extends NativeType> with TypedField<T> {
// //   const TypedOffset(this.offset);
// //   @override
// //   final int offset;
// // }