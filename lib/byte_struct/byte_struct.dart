import 'dart:ffi';
import 'dart:typed_data';

export 'dart:ffi';
export 'dart:typed_data';

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
/// a struct memeber
/// configuration for get TypedData segment from
class TypedOffset<T extends NativeType> {
  const TypedOffset(this.offset);
  final int offset;

  int get size => sizeOf<T>();
  int get end => offset + size; // index of last byte + 1

  // call with offset with T
  int fieldValue(ByteData byteData) => byteData.wordAt<T>(offset);
  int? fieldValueOrNull(ByteData byteData) => byteData.wordAtOrNull<T>(offset);
  void setFieldValue(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);
}

/// ByteStruct
/// Effectively TypedData as abstract class with user defined fields.
abstract mixin class ByteStruct<T extends ByteStruct<dynamic>> {
  // TypedData.new
  T buffer(int length) => (this..reference = Uint8List(length)) as T;

  // TypedData.view
  // Analogous to ByteData.sublistView but without configurable offset, as it is always inherited from the reference.
  T cast(TypedData data) => (this..reference = data) as T;

  // static Uint8List nullPtr = Uint8List.fromList(const []);
  static TypedData nullPtr = throw UnsupportedError('nullPtr');

  TypedData reference = nullPtr; // alternatively use late

  int get size => reference.lengthInBytes; // view size, virtual size, independent of underlying buffer and offset
  ByteData get asByteData => reference.asByteData;

  static const TypedOffset<Uint8> start = TypedOffset<Uint8>(0);
  // List<TypedOffset> get members;
}

// ByteStructFactory
abstract class ByteStructFactory {
  ByteStruct create();
}

/// ByteBuffer conversion function, but on view segment accounting for offset
extension GenericSublistView on TypedData {
  ByteData get asByteData => ByteData.sublistView(this);
  List<int> asTypedList<R extends TypedData>() => sublistView<R>();

  // throws range error
  // offset uses "this" instance type, not R type
  List<int> _sublistView<R extends TypedData>([int typedOffset = 0]) {
    return switch (R) {
      const (Uint8List) => Uint8List.sublistView(this, typedOffset),
      const (Uint16List) => Uint16List.sublistView(this, typedOffset),
      const (Uint32List) => Uint32List.sublistView(this, typedOffset),
      const (Int8List) => Int8List.sublistView(this, typedOffset),
      const (Int16List) => Int16List.sublistView(this, typedOffset),
      const (Int32List) => Int32List.sublistView(this, typedOffset),
      const (ByteData) => throw UnsupportedError('ByteData.sublistView'),
      _ => throw UnimplementedError(),
    };
  }

  List<int> _sublistViewConvertEndian<R extends TypedData>(Endian endian, [int typedOffset = 0]) {
    final byteData = ByteData.sublistView(this, typedOffset);
    //  final length = sublistView.lengthInBytes / sizeOf<R>();
    return switch (R) {
      const (Uint16List) => List<int>.generate(byteData.lengthInBytes ~/ 2, (i) => byteData.getUint16(i * 2, endian)),
      const (Uint32List) => List<int>.generate(byteData.lengthInBytes ~/ 4, (i) => byteData.getUint32(i * 4, endian)),
      const (Int16List) => List<int>.generate(byteData.lengthInBytes ~/ 2, (i) => byteData.getInt16(i * 2, endian)),
      const (Int32List) => List<int>.generate(byteData.lengthInBytes ~/ 4, (i) => byteData.getInt32(i * 4, endian)),
      _ => throw UnimplementedError(),
    };
  }

  List<int> sublistView<R extends TypedData>([int typedOffset = 0, Endian endian = Endian.little]) {
    return ((Endian.host != endian) && (R != Uint8List) && (R != Int8List)) ? _sublistViewConvertEndian<R>(endian, typedOffset) : _sublistView<R>(typedOffset);
  }

  List<int> sublistViewOrEmpty<R extends TypedData>([int byteOffset = 0]) => (byteOffset < lengthInBytes) ? sublistView<R>(byteOffset) : const <int>[];

  int get end => offsetInBytes + lengthInBytes; //  index of last byte + 1
}

extension GenericWord on ByteData {
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

  // int? wordAtElementIndex<R extends NativeType>(int elementOffset, [Endian endian = Endian.little]) {
  // }
}

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
