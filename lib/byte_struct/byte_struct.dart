import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cmdr/byte_struct.dart';

import 'typed_field.dart';

export 'dart:ffi';
export 'dart:typed_data';

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////

/// a struct memeber
/// configuration for get TypedData segment from
class TypedOffset<T extends NativeType> extends TypedField<T> {
  const TypedOffset(this.offset);

  @override
  final int offset;
  // int get size => sizeOf<T>();
  // int get end => offset + size; // index of last byte + 1

  // // call with offset with T
  // int fieldValue(ByteData byteData) => byteData.wordAt<T>(offset);
  // int? fieldValueOrNull(ByteData byteData) => byteData.wordAtOrNull<T>(offset);
  // void setFieldValue(ByteData byteData, int value) => byteData.setWordAt<T>(offset, value);
}

/// ByteStruct
/// Effectively TypedData as an abstract class with user defined fields.
///  implemented as wrapper since TypedData is final
///
abstract mixin class ByteStruct<T extends ByteStruct<dynamic>> {
  static const TypedOffset<Uint8> start = TypedOffset<Uint8>(0);
  // List<TypedOffset> get members;

  // TypedData.new
  T buffer(int length) => (this..reference = Uint8List(length)) as T;

  // TypedData.view
  // Analogous to ByteData.sublistView but without configurable offset, as it is always inherited from the reference.
  T cast(TypedData data) => (this..reference = data) as T;

  static Uint8List nullPtr = Uint8List(0);

  // alternatively this model holder size and offset with pointer to ByteBuffer
  TypedData reference = nullPtr; // alternatively use late

  int get size => reference.lengthInBytes; // view size, virtual size, independent of underlying buffer and offset

  // extended to hold Typed conversion functions
  ByteData asByteData() => reference.asByteData();
}

// ByteStructFactory
abstract class ByteStructFactory {
  ByteStruct create();
}

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
/// Effectively ByteBuffer conversion function, but on view segment accounting for offset
extension GenericSublistView on TypedData {
  int get end => offsetInBytes + lengthInBytes; // index of last byte + 1

  ByteData asByteData() => ByteData.sublistView(this);
  List<int> asTypedList<R extends TypedData>() => sublistViewHost<R>();

  // throws range error
  // offset uses "this" instance type, not R type
  List<int> sublistView<R extends TypedData>([int typedOffset = 0]) {
    return switch (R) {
      const (Uint8List) => Uint8List.sublistView(this, typedOffset),
      const (Uint16List) => Uint16List.sublistView(this, typedOffset),
      const (Uint32List) => Uint32List.sublistView(this, typedOffset),
      const (Int8List) => Int8List.sublistView(this, typedOffset),
      const (Int16List) => Int16List.sublistView(this, typedOffset),
      const (Int32List) => Int32List.sublistView(this, typedOffset),
      const (ByteData) => throw UnsupportedError('ByteData is not a typed list'),
      _ => throw UnimplementedError(),
    };
  }

  List<int> sublistViewOrEmpty<R extends TypedData>([int byteOffset = 0]) => (byteOffset < lengthInBytes) ? sublistView<R>(byteOffset) : const <int>[];

  static Endian hostEndian = Endian.host; // resolve once storing results

  List<int> sublistViewHost<R extends TypedData>([int typedOffset = 0, Endian endian = Endian.little]) {
    return ((hostEndian != endian) && (R != Uint8List) && (R != Int8List)) ? EndianCastList<R>(this, endian) : sublistView<R>(typedOffset);
  }
}

extension ByteBufferData on ByteBuffer {
  int wordAt<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) => asByteData().wordAt<R>(byteOffset, endian);
  int? wordAtOrNull<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) => asByteData().wordAtOrNull<R>(byteOffset, endian);
  void setWordAt<R extends NativeType>(int byteOffset, int value, [Endian endian = Endian.little]) => asByteData().setWordAt<R>(byteOffset, value, endian);

  // List<int> cast<R extends TypedData>(int byteOffset, [Endian endian = Endian.little])
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

class EndianCastList<R extends TypedData> extends ListBase<int> {
  EndianCastList(this._source, this._endian);

  TypedData _source;
  Endian _endian;

  @override
  int get length => _source.lengthInBytes ~/ _source.elementSizeInBytes;
  // int get length => (_source as List<int>).length;

  @override
  int operator [](int index) {
    final byteData = ByteData.sublistView(_source);
    return switch (R) {
      const (Uint16List) => byteData.getUint16(index * _source.elementSizeInBytes, _endian),
      // const (Uint16List) => Uint16List.sublistView(this, typedOffset),
      // const (Uint32List) => Uint32List.sublistView(this, typedOffset),
      // const (Int8List) => Int8List.sublistView(this, typedOffset),
      // const (Int16List) => Int16List.sublistView(this, typedOffset),
      // const (Int32List) => Int32List.sublistView(this, typedOffset),
      // const (ByteData) => throw UnsupportedError('ByteData is not a typed list'),
      _ => throw UnimplementedError(),
    };
  }

  @override
  void operator []=(int index, int value) {
    // TODO: implement []=
  }

  @override
  set length(int newLength) {
    // TODO: implement length
  }
}
