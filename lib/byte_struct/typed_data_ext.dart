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

/// Word value
extension BytesOfInt on int {
  // returns as 8 bytes
  ByteData toByteData([Endian endian = Endian.big]) => TypedDataCtors.fromInt(this, endian);
  Uint8List toBytes([Endian endian = Endian.big]) => TypedDataCtors.fromInt(this, endian).buffer.asUint8List();

  /// skip ByteData buffer for a known segment
  int valueSizedAt(int offset, int size) => (this >> (offset * 8)) & ((1 << (size * 8)) - 1);
  // int valueTypedAt<T extends NativeType>(int offset) => valueSizedAt(offset, sizeOf<T>());
  // int modifyByte(int index, int value) => (this & ~ _bitmask) | (value << index) ;

  int get byteLength => (bitLength / 8).ceil();
}

/// List values
