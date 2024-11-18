import 'dart:ffi';
import 'dart:typed_data';

import 'package:cmdr_common/struct.dart';

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
abstract mixin class TypedField<T extends NativeType> implements Field<int> {
  const TypedField._();
  const factory TypedField(int offset) = _TypedField<T>;

  int get offset; // index of the first byte

  int get size => sizeOf<T>();
  int get end => offset + size; // index of the last byte + 1
  // int get valueMax => (1 << width) - 1);

  // for BitStruct
  // static Bitmask bitmaskOf<T extends NativeType>(int offset) => Bitmask.bytes(offset, sizeOf<T>());
  // Bitmask asBitmask() => Bitmask.bytes(offset, size);

  /// [ByteStruct]
  // call passing T
  // Although handling of keyed access is preferable in the data source class.
  // T must handled in it's local scope. No type inference when passing `Field` to ByteData

  // replaced by ffi.Struct
  // applyGet
  @override
  int getIn(ByteData byteData) => byteData.wordAt<T>(offset);
  @override
  void setIn(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);
  // not yet replaceable
  @override
  int? getInOrNull(ByteData byteData) => byteData.wordOrNullAt<T>(offset);
  @override
  bool setInOrNot(ByteData byteData, int value) => byteData.setWordOrNotAt<T>(offset, value);

  @override
  int? get defaultValue => 0;

  @override
  bool testBounds(ByteData byteData) => end <= byteData.lengthInBytes;
}

class _TypedField<T extends NativeType> with TypedField<T> {
  const _TypedField(this.offset);

  @override
  final int offset;

  @override
  int get index => throw UnimplementedError();
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

  int? wordOrNullAt<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) {
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

  bool setWordOrNotAt<R extends NativeType>(int byteOffset, int value, [Endian endian = Endian.little]) {
    if (byteOffset + sizeOf<R>() <= lengthInBytes) {
      setWordAt(byteOffset, value, endian);
      return true;
    }
    return false;
  }
}

// /// General case, without NativeType
// /// `Partition`
// abstract mixin class SizedField {
//   // const SizedField._();
//   // const factory SizedField(int offset, int size) = _SizedField;

//   int get offset;
//   int get size;
//   int get end => offset + size;

//   List<int> arrayOf<R extends TypedData>(TypedData typedList) => typedList.asIntListOrEmpty<R>(offset, size);
// }

// class _Part with Part {
//   const _Part(this.offset, this.size);
//   @override
//   final int offset;
//   @override
//   final int size;
// }
