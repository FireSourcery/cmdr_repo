import 'dart:collection';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

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

int bytesPerElementOf<T extends TypedData>() {
  return switch (T) {
    const (Uint8List) => Uint8List.bytesPerElement,
    const (Uint16List) => 2,
    const (Uint32List) => 4,
    const (Int8List) => 1,
    const (Int16List) => 2,
    const (Int32List) => 4,
    _ => throw UnimplementedError(),
  };
}

/// pow2 only
int alignDown(int value, int align) => (value & (-align));
int alignUp(int value, int align) => (-(-value & (-align)));
bool isAligned(int value, int align) => ((value & (align - 1)) == 0);

////////////////////////////////////////////////////////////////////////////////
/// List values
/// TypedData Cat Conversion
////////////////////////////////////////////////////////////////////////////////
/// Effectively ByteBuffer conversion function, but on view segment accounting for offset
extension GenericSublistView on TypedData {
  int get end => offsetInBytes + lengthInBytes; // index of last byte + 1

  // throws range error
  // offset uses "this" instance type, not R type,
  R _sublistView<R extends TypedData>([int typedOffset = 0, int? end]) {
    return switch (R) {
      const (Uint8List) => Uint8List.sublistView(this, typedOffset, end),
      const (Uint16List) => Uint16List.sublistView(this, typedOffset, end),
      const (Uint32List) => Uint32List.sublistView(this, typedOffset, end),
      const (Int8List) => Int8List.sublistView(this, typedOffset, end),
      const (Int16List) => Int16List.sublistView(this, typedOffset, end),
      const (Int32List) => Int32List.sublistView(this, typedOffset, end),
      const (ByteData) => ByteData.sublistView(this, typedOffset, end),
      _ => throw UnimplementedError(),
    } as R;
  }

  R? sublistViewOrNull<R extends TypedData>([int typedOffset = 0, int? end]) => (typedOffset * elementSizeInBytes < lengthInBytes) ? _sublistView<R>(typedOffset, end) : null;

  ByteData asByteData() => ByteData.sublistView(this);
  R asTypedList<R extends TypedData>([int typedOffset = 0, int? end]) => _sublistView<R>(typedOffset, end);
  // R cast<R extends TypedData>() => _sublistView<R>();
  // sublist with extendable length, R == this.runtimeType
  // R toTypedList<R extends TypedData>([int? length]) => (ByteData((length ?? this.length) * bytesPerElementOf<R>()).intListView<R>()..setAll(0, take(length ?? this.length))) as R;

  // prefer super function anti pattern, since sublistView cannot compose from all types without overlap
  // use to essentially case type for convenience
  // orEmpty by default?
  List<int> asIntList<R extends TypedData>([int typedOffset = 0, int? end]) {
    assert(switch (R) { const (Uint8List) || const (Uint16List) || const (Uint32List) || const (Int8List) || const (Int16List) || const (Int32List) => true, _ => false }, '$R is not an int list');
    return _sublistView<R>(typedOffset, end) as List<int>;
  }

  List<int> asIntListOrEmpty<R extends TypedData>([int typedOffset = 0, int? end]) => (typedOffset * elementSizeInBytes < lengthInBytes) ? asIntList<R>(typedOffset, end) : const <int>[];

  static Endian hostEndian = Endian.host; // resolve once storing results

  // List<num> numListViewHost<R extends TypedData>([int typedOffset = 0, Endian endian = Endian.little]) {
  //   return (hostEndian != endian) ? EndianCastList<R>(this, endian) : sublistView<R>(typedOffset) as R;
  // }
}

extension TypedListSlices on TypedData {
  Iterable<T> typedSlices<T extends TypedData>(int length) sync* {
    if (length < 1) throw RangeError.range(length, 1, null, 'length');
    for (var offset = 0; offset < lengthInBytes; offset += length) {
      yield _sublistView<T>(offset, min(offset + length, lengthInBytes));
      // todo range of bytes being viewed must be multiples.
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
/// Word value
////////////////////////////////////////////////////////////////////////////////
extension GenericWord on ByteData {
  // throws range error
  /// ValueAt by type
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

  // int uintAt(int byteOffset, int size, [Endian endian = Endian.little]) {
  //   return switch (size) {
  //     const (1) => getUint8(byteOffset),
  //     const (2) => getUint16(byteOffset, endian),
  //     const (4) => getUint32(byteOffset, endian),
  //     _ => throw UnimplementedError(),
  //   };
  // }
}

////////////////////////////////////////////////////////////////////////////////
/// Word value for intervals not of pow2
////////////////////////////////////////////////////////////////////////////////
extension SizedWord on TypedData {
  // caller assert(lengthInBytes >= 8)
  int toInt64([Endian endian = Endian.little]) => buffer.asByteData().getInt64(offsetInBytes, endian); // equivalent to ByteData.sublistView(this).getInt64(0, endian)

  // creates a new buffer
  // caller assert(lengthInBytes < 8)
  // when lengthInBytes > 8, toInt64 avoids copying buffer
  int valueAt(int byteOffset, int size, [Endian endian = Endian.little]) {
    assert(size <= 8);
    final endianOffset = switch (endian) { Endian.big => 8 - size, Endian.little => 0, Endian() => throw StateError('Endian') };
    return (Uint8List(8)..setAll(endianOffset, buffer.asUint8List(offsetInBytes + byteOffset, size))).toInt64(endian);
  }

  int toInt([Endian endian = Endian.little]) => (lengthInBytes >= 8) ? toInt64(endian) : valueAt(0, lengthInBytes, endian);
}

////////////////////////////////////////////////////////////////////////////////
/// List values
/// Non TypedData Conversion
////////////////////////////////////////////////////////////////////////////////
extension TypedDataOfIterable on Iterable<int> {
  // same as Uint8List.fromList when length < this.length
  // fills length when length > this.length
  Uint8List toBytes([int? length]) => Uint8List(length ?? this.length)..setAll(0, take(length ?? this.length)); // from iterable extend length

  // from iterable extend length
  static ByteData _fromLength<R extends TypedData>(int length) => ByteData(length * bytesPerElementOf<R>());
  // R must be IntList
  R toTypedList<R extends TypedData>([int? length]) => (_fromLength<R>(length ?? this.length).asIntList<R>()..setAll(0, take(length ?? this.length))) as R;

  /// String
  String toStringAsEncoded([int start = 0, int? end]) => String.fromCharCodes(this, start, end);

  // String toStringAsEncodedTrimNulls([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  // String toStringAsEncodedNonNulls([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(String.fromCharCode(0), '');
  // String toStringAsEncodedAlphaNumeric([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  int indexOfMatch(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));
}

extension StringOfList on List<int> {
  // Chars use array index
  // from User I/O as int literal
  String charAsValue(int index) => this[index].toString(); // 1 => '1'
  List<int> modifyAsValue(int index, String value) => this..[index] = int.parse(value); // '1' => 1

  String charAsCode(int index) => String.fromCharCode(this[index]); // 0x31 => '1'
  List<int> modifyAsCode(int index, String value) => this..[index] = value.runes.single; // '1' => 0x31
}

extension StringOfBytes on Uint8List {
  // int indexOfBytes(Uint8List match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));
  Uint8List? seekViewOfIndex(int index) => (index > -1) ? Uint8List.sublistView(this, index) : null;
  Uint8List? seekViewOfChar(int match) => seekViewOfIndex(indexOf(match));
  Uint8List? seekViewOfMatch(Iterable<int> match) => seekViewOfIndex(indexOfMatch(match));
}

extension StringOfTypedData on TypedData {
  // index in this.elementSizeInBytes
  R? seekViewOfIndex<R extends TypedData>(int index) => (index > -1) ? _sublistView<R>(index) : null;
  R? seekViewOfChar<R extends TypedData>(int match) => seekViewOfIndex(asIntList<R>().indexOf(match));
  R? seekViewOfMatch<R extends TypedData>(Iterable<int> match) => seekViewOfIndex(asIntList<R>().indexOfMatch(match));
}

// extension ByteBufferData on ByteBuffer {
//   int toInt([int byteOffset = 0, Endian endian = Endian.little]) => asByteData().getInt64(byteOffset, endian);
// }

// extension ByteBufferData on ByteBuffer {
//   int wordAt<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) => asByteData().wordAt<R>(byteOffset, endian);
//   int? wordAtOrNull<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) => asByteData().wordAtOrNull<R>(byteOffset, endian);
//   void setWordAt<R extends NativeType>(int byteOffset, int value, [Endian endian = Endian.little]) => asByteData().setWordAt<R>(byteOffset, value, endian);
//   int toInt([int byteOffset = 0, Endian endian = Endian.little]) => asByteData().getInt64(byteOffset, endian);
//   // List<int> castList<R extends TypedData>(int byteOffset, [Endian endian = Endian.little])
// }

class EndianCastList<R extends TypedData> extends ListBase<num> {
  EndianCastList(this._source, this._endian);

  final TypedData _source;
  final Endian _endian;

  @override
  int get length => _source.lengthInBytes ~/ _source.elementSizeInBytes;
  // int get length => (_source as List<int>).length;

  @override
  num operator [](int index) {
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
  void operator []=(int index, num value) {
    // TODO: implement []=
  }

  @override
  set length(int newLength) {
    // TODO: implement length
  }
}
