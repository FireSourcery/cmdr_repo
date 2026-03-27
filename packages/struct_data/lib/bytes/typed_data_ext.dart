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
  // int get offset => offsetInBytes ~/ elementSizeInBytes;
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

/// TypedList version of [List<int>.skip]
// effectively asTypedList<T>() with this type
extension TypedDataListSeek<T extends TypedDataList<int>> on T {
  /// avoid naming collision with List.indexOf
  int indexOfSequence(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));

  T? seek(int index) => (index > -1) ? sublistView<T>(this, index) : null;

  T? seekChar(int match) => seek(indexOf(match));
  T? seekSequence(Iterable<int> match) => seek(indexOfSequence(match));

  String asString([int start = 0, int? end]) => String.fromCharCodes(this, start, end);
}
