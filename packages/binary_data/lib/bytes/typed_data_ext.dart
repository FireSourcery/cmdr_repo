import 'dart:math';
import 'dart:typed_data';

////////////////////////////////////////////////////////////////////////////////
/// Wrappers as top level functions
////////////////////////////////////////////////////////////////////////////////

/// length is in elements
/// same as `ByteData(length * bytesPerElementOf<T>())`
T typedList<T extends TypedDataList>(int length) {
  return switch (T) {
        const (Uint8List) => Uint8List(length),
        const (Uint16List) => Uint16List(length),
        const (Uint32List) => Uint32List(length),
        const (Int8List) => Int8List(length),
        const (Int16List) => Int16List(length),
        const (Int32List) => Int32List(length),
        _ => throw UnimplementedError(),
      }
      as T;
}

// T fromList<T extends TypedDataList<E>, E>(List<E> elements) {
//     return switch (T) {
//       const (Uint8List) => Uint8List.fromList(elements),
//       const (Uint16List) => Uint16List.fromList(elements),
//       const (Uint32List) => Uint32List.fromList(elements),
//       const (Int8List) => Int8List.fromList(elements),
//       const (Int16List) => Int16List.fromList(elements),
//       const (Int32List) => Int32List.fromList(elements),
//       _ => throw UnsupportedError('$T is not a typed data list'),
//     } as T;
// }

T fromListInt<T extends TypedDataList<int>>(List<int> elements) {
  return switch (T) {
        const (Uint8List) => Uint8List.fromList(elements),
        const (Uint16List) => Uint16List.fromList(elements),
        const (Uint32List) => Uint32List.fromList(elements),
        const (Int8List) => Int8List.fromList(elements),
        const (Int16List) => Int16List.fromList(elements),
        const (Int32List) => Int32List.fromList(elements),
        _ => throw UnsupportedError('$T is not an int list'),
      }
      as T;
}

/// GenericSublistView
/// offset in elements, type of [data], not [T] type.
// alternatively unified calculation on buffer directly
T sublistView<T extends TypedData>(TypedData data, [int start = 0, int? end]) {
  return switch (T) {
        const (Uint8List) => Uint8List.sublistView(data, start, end),
        const (Uint16List) => Uint16List.sublistView(data, start, end),
        const (Uint32List) => Uint32List.sublistView(data, start, end),
        const (Int8List) => Int8List.sublistView(data, start, end),
        const (Int16List) => Int16List.sublistView(data, start, end),
        const (Int32List) => Int32List.sublistView(data, start, end),
        const (ByteData) => ByteData.sublistView(data, start, end),
        _ => throw UnimplementedError(),
      }
      as T;
}

int bytesPerElementOf<T extends TypedData>() {
  return switch (T) {
    const (Uint8List) => Uint8List.bytesPerElement,
    const (Uint16List) => Uint16List.bytesPerElement,
    const (Uint32List) => Uint32List.bytesPerElement,
    const (Int8List) => Int8List.bytesPerElement,
    const (Int16List) => Int16List.bytesPerElement,
    const (Int32List) => Int32List.bytesPerElement,
    _ => throw UnimplementedError(),
  };
}

////////////////////////////////////////////////////////////////////////////////
/// implementations on TypedData returning as `this` type
/// parameters in element size of `this` type
////////////////////////////////////////////////////////////////////////////////
extension TypedDataLength on TypedData {
  int get length => lengthInBytes ~/ elementSizeInBytes;

  bool testBounds(int start, int? end) {
    assert(start >= 0, 'Start must be non-negative: $start');
    if (start > length) return false;
    if (end != null && (end > length)) return false;
    return true;
  }
}

/// Slices returning TypedData
/// Slices on [List] cannot return TypedData
extension TypedDataSlices<T extends TypedData> on T {
  // todo handle size with fill/truncate
  Iterable<T> typedSlices(int sliceLength) sync* {
    if (sliceLength < 1) throw RangeError.range(sliceLength, 1, null, 'length');

    for (var offset = 0; offset < length; offset += sliceLength) {
      yield sublistView<T>(this, offset, min(offset + sliceLength, length));
    }
  }
}

/// TypedList version of List<int>.skip
// effectively asTypedList<T>() with this type
extension TypedDataListSeek<T extends TypedDataList<int>> on T {
  /// avoid naming collision with List.indexOf
  int indexOfSequence(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));

  T? seek(int index) => (index > -1) ? sublistView<T>(this, index) : null;

  T? seekChar(int match) => seek(indexOf(match));
  T? seekSequence(Iterable<int> match) => seek(indexOfSequence(match));

  String asString([int start = 0, int? end]) => String.fromCharCodes(this, start, end);
  // String toStringAsCode([int start = 0, int? end]) => String.fromCharCodes(this, start, end);
}

// class EndianCastList<R extends TypedData> extends ListBase<num> {
//   EndianCastList(this._source, this._endian);

//   static Endian hostEndian = Endian.host; // resolve once storing results
//   final TypedData _source;
//   final Endian _endian;

//   // List<num> numListViewHost<R extends TypedData>([int typedOffset = 0, Endian endian = Endian.little]) {
//   //   return (hostEndian != endian) ? EndianCastList<R>(this, endian) : sublistView<R>(typedOffset) as R;
//   // }
//   @override
//   int get length => _source.lengthInBytes ~/ _source.elementSizeInBytes;
//   // int get length => (_source as List<int>).length;

//   @override
//   num operator [](int index) {
//     final byteData = ByteData.sublistView(_source);
//     return switch (R) {
//       const (Uint16List) => byteData.getUint16(index * _source.elementSizeInBytes, _endian),
//       // const (Uint16List) => Uint16List.sublistView(this, typedOffset),
//       // const (Uint32List) => Uint32List.sublistView(this, typedOffset),
//       // const (Int8List) => Int8List.sublistView(this, typedOffset),
//       // const (Int16List) => Int16List.sublistView(this, typedOffset),
//       // const (Int32List) => Int32List.sublistView(this, typedOffset),
//       // const (ByteData) => throw UnsupportedError('ByteData is not a typed list'),
//       _ => throw UnimplementedError(),
//     };
//   }

//   @override
//   void operator []=(int index, num value) {}

//   @override
//   set length(int newLength) {}
// }
