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

/// [TypedArray<T extends TypedData>] - `Generic TypedData`
/// wrapped + additional constructors for [TypedData] and [TypedDataList]
// extension type const TypedArray<T extends TypedDataList>._(T _this) implements TypedData, TypedDataList {
//   TypedArray(int length) : this._(typedList<T>(length));

//   // constructor for arrayAt<T>() using end
//   // offset uses parameter 'data' instance type, not T type,
//   // sublistView handle range error
//   // alternatively unified calculation on buffer directly
//   TypedArray.cast(TypedData data, [int start = 0, int? end]) : this._(sublistView<T>(data, start, end));

//   // TypedArray.cast(TypedData data, [int typedOffset = 0, int? end])
//   //   : _this = switch (T) {
//   //       // prefer super function anti pattern. cannot compose from all sub type groups without overlap
//   //       const (TypedData) || const (dynamic) => data.typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => sublistView<G>(data, typedOffset, end) as T),
//   //       _ => sublistView<T>(data, typedOffset, end),
//   //       // const (ByteData) => throw UnsupportedError('ByteData is not a typed list'),
//   //     };

//   /// effectively sublist with extendable length
//   /// length in T size
//   /// same as `TypedData.fromList` when `length < this.length`
//   /// fills length when `length > this.length` and accepts [Iterable<int>] where as `TypedData.fromList` does not
//   factory TypedArray.fromData(TypedData data, [int? length]) {
//     final byteLength = (length != null) ? length * bytesPerElementOf<T>() : data.lengthInBytes;
//     final copyLength = min(byteLength, data.lengthInBytes);
//     return TypedArray<T>.cast(Uint8List(byteLength)..setAll(0, Uint8List.sublistView(data, 0, copyLength)));

//     // return TypedArray<T>(length ?? data.lengthInBytes ~/ bytesPerElementOf<T>()).._this.buffer.asUint8List().setAll(0, Uint8List.sublistView(data, 0, copyLength));
//   }

//   //
//   factory TypedArray.fromValues(TypedDataList values, [int? length]) {
//     final newLength = length ?? values.length;
//     return TypedArray<T>(newLength)..setAll(0, values.take(newLength));

//     // if (length != null) {
//     //   return TypedArray<T>(length)..setAll(0, values.take(length));
//     // } else {
//     //   return fromList(elements);
//     // }
//   }

//   T get asThis => _this;

// }
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
