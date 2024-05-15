import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

// implementations grouped by new buffer
//   toTypedData method call
extension TypedDataCtors on TypedData {
  // fixed size buffer then wrap view with length likely better performance than iterative build with flex size BytesBuilder
  static ByteData fromInt(int value, [Endian endian = Endian.big]) => ByteData(8)..setInt64(0, value, endian);

  static Uint8List fromString(String string) => fromBytes(string.runes);

  static Uint8List fromBytes(Iterable<int> bytes) => (Uint8List(bytes.length)..setRange(0, bytes.length, bytes));

  static List<int> _fromLength<R extends TypedData>(int length) {
    return switch (R) {
      const (Uint8List) => Uint8List(length),
      const (Uint16List) => Uint16List(length),
      _ => throw UnimplementedError(),
    };
  }

  // fromList but with Iterable
  static R fromIterable<R extends TypedData>(Iterable<int> values, [int? count]) {
    final length = count ?? values.length;
    return (_fromLength<R>(length)..setRange(0, length, values)) as R;
    // return switch (R) {
    //   const (Uint8List) => Uint8List(length)..setRange(0, length, values),
    //   const (Uint16List) => Uint16List(length)..setRange(0, length, values),
    //   const (Uint32List) => fromBytes(values, count).buffer.asUint32List(),
    //   const (Int8List) => fromBytes(values, count).buffer.asInt8List(),
    //   const (Int16List) => fromBytes(values, count).buffer.asInt16List(),
    //   const (Int32List) => fromBytes(values, count).buffer.asInt32List(),
    // const (ByteData) => fromBytes(values, count).buffer.asByteData(),
    //   _ => throw UnimplementedError(),
    // } as TypedData;
  }

  // int toInt([Endian endian = Endian.little]) => buffer.asByteData().getInt64(offsetInBytes, endian);
  // String toStringAsEncoded([int start = 0, int? end]) => String.fromCharCodes(Uint8List.sublistView(this), start, end);
}

////////////////////////////////////////////////////////////////////////////////
/// Word value
///
////////////////////////////////////////////////////////////////////////////////
extension BytesOfInt on int {
  int get byteLength => (bitLength / 8).ceil();
  // returns as 8 bytes
  // fixed size buffer then wrap view with length likely better performance than iterative build with flex size BytesBuilder
  ByteData toByteData([Endian endian = Endian.big]) => TypedDataCtors.fromInt(this, endian);
  Uint8List toBytes([Endian endian = Endian.big]) => TypedDataCtors.fromInt(this, endian).buffer.asUint8List();

  /// skip ByteData buffer for a direct segment
  int valueSizedAt(int offset, int size) => (this >> (offset * 8)) & ((1 << (size * 8)) - 1);
  int valueTypedAt<T extends NativeType>(int offset) => valueSizedAt(offset, sizeOf<T>());
  // int modifyByte(int index, int value) => (this & ~ _bitmask) | (value << index) ;
}

extension IntOfBytes on TypedData {
  // defaults to little endian for an arbitrary list of bytes, assume external
  // big endian will set first item as msb of 64-bits, fill missing bytes with 0
  //   e.g. for a value of 1, big endian, user must input <int>[0, 0, 0, 0, 0, 0, 0, 1], <int>[1] would be treated as 0x0100'0000'0000'0000
  // static int valueOf(TypedData bytes, [Endian endian = Endian.little]) => bytes.buffer.asByteData().getInt64(bytes.offsetInBytes, endian);
  // equivalent to ByteData.sublistView(this).getInt64(0, endian)
  int toInt([Endian endian = Endian.little]) => buffer.asByteData().getInt64(offsetInBytes, endian);

  // following bytesOfInt
  // trimmed view sublist for copy
  // big endian trim leading. little endian trim trailing
  Uint8List trim(int wordLength, Endian endian) => switch (endian) { Endian.big => trimAsBE(wordLength), Endian.little => trimAsLE(wordLength), Endian() => throw UnsupportedError('Endian') };
  // constructing trimAsBE back to Word will change value, as offset has change, alternatively parameterize with size/type
  Uint8List trimAsBE(int wordLength) => Uint8List.sublistView(this, lengthInBytes - wordLength);
  // constructing trimAsLE back to Word preserves value
  Uint8List trimAsLE(int wordLength) => Uint8List.sublistView(this, 0, wordLength);

  Uint8List modify(int index, int value) => Uint8List.sublistView(this)..[index] = value;
}

extension BytesOfIterable on Iterable<int> {
  // static Uint8List bytesOf(Iterable<int> bytes, [int? count]) => Uint8List(8)..setAll(0, bytes.take(8));
  Uint8List toBytes([int? length]) => TypedDataCtors.fromBytes(this);

  String toStringAsEncoded([int start = 0, int? end]) => String.fromCharCodes(this, start, end);
  // String toStringAsEncodedTrimNulls([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  // String toStringAsEncodedNonNulls([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(String.fromCharCode(0), '');
  // String toStringAsEncodedAlphaNumeric([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}

extension StringOfBytes on List<int> {
  // Chars use array index
  // from User I/O as int literal
  String charAsValue(int index) => this[index].toString(); // 1 => '1'
  List<int> modifyAsValue(int index, String value) => this..[index] = int.parse(value); // '1' => 1

  String charAsCode(int index) => String.fromCharCode(this[index]); // 0x31 => '1'
  List<int> modifyAsCode(int index, String value) => this..[index] = value.runes.single; // '1' => 0x31
}

////////////////////////////////////////////////////////////////////////////////
/// List values
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
}

// extension ByteBufferData on ByteBuffer {
//   int wordAt<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) => asByteData().wordAt<R>(byteOffset, endian);
//   int? wordAtOrNull<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) => asByteData().wordAtOrNull<R>(byteOffset, endian);
//   void setWordAt<R extends NativeType>(int byteOffset, int value, [Endian endian = Endian.little]) => asByteData().setWordAt<R>(byteOffset, value, endian);

//   int toInt([int byteOffset = 0, Endian endian = Endian.little]) => asByteData().getInt64(byteOffset, endian);
//   // List<int> cast<R extends TypedData>(int byteOffset, [Endian endian = Endian.little])
// }

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
