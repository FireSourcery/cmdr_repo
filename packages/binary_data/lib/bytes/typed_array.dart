import 'dart:math';
import 'dart:typed_data';

import 'typed_data_ext.dart';
export 'dart:typed_data';

/// [TypedArray<T extends TypedData>] - `Generic TypedData`
/// via collected constructors
//  or should this be on ByteBuffer?
//  GenericTypedData, ArrayData, TypedArray
extension type const TypedArray<T extends TypedData>._(T _this) implements TypedData {
  // throws range error
  // offset uses parameter 'data' instance type, not T type,
  // prefer super function anti pattern. cannot compose from all sub type groups without overlap
  TypedArray._sublistView(TypedData data, [int typedOffset = 0, int? end])
      : _this = switch (T) {
          const (Uint8List) => Uint8List.sublistView(data, typedOffset, end),
          const (Uint16List) => Uint16List.sublistView(data, typedOffset, end),
          const (Uint32List) => Uint32List.sublistView(data, typedOffset, end),
          const (Int8List) => Int8List.sublistView(data, typedOffset, end),
          const (Int16List) => Int16List.sublistView(data, typedOffset, end),
          const (Int32List) => Int32List.sublistView(data, typedOffset, end),
          const (ByteData) => ByteData.sublistView(data, typedOffset, end),
          // is it possible for data to only have TypedData as type?
          // const (TypedData) || const (dynamic) => data.callAsThis<T>(<G extends TypedData>() => TypedArray<G>._sublistView(data, typedOffset, end) as T),
          _ => throw UnimplementedError(),
        } as T;

  // offset uses type of 'data', not T type.
  TypedArray.cast(TypedData data, [int typedOffset = 0, int? end]) : this._sublistView(data, typedOffset, end);

  // does this need to cast?
  TypedArray(int length) : this._sublistView(ByteData(length * bytesPerElementOf<T>()));
  // TypedArray._(int length)
  //     : _this = switch (T) {
  //         const (Uint8List) => Uint8List(length),
  //         const (Uint16List) => Uint16List(length),
  //         const (Uint32List) => Uint32List(length),
  //         const (Int8List) => Int8List(length),
  //         const (Int16List) => Int16List(length),
  //         const (Int32List) => Int32List(length),
  //       };

  // final endianOffset = switch (endian) { Endian.big => 8 - size, Endian.little => 0, Endian() => throw StateError('Endian') };
  // TypedArray.word([int? value]) : this(8);

  // sublist with extendable length
  factory TypedArray.from(TypedData data, [int? length]) {
    final byteLength = (length != null) ? length * bytesPerElementOf<T>() : data.lengthInBytes;
    return TypedArray<T>.cast(Uint8List(byteLength)..setAll(0, Uint8List.sublistView(data, 0, byteLength)));
    // return TypedArray<T>(byteLength).copyFrom(source, byteLength);
  }

  T get asThis => _this;

  // TypedList version of List<int>.skip
  T seek(int index) => TypedArray<T>._sublistView(this, index).asThis;
  T? seekOrNull(int index) => (index > -1) ? seek(index) : null;
}

/// [const IntArray<T extends TypedData>] - `Typed Int List`
/// TypeData subset that with List<int> interface
// todo change _this to List<int>?
// or should the representation be a List<int>?
extension type const IntArray<T extends TypedData>._(T _this) implements TypedData, TypedArray<T> {
  IntArray._fromList(List<int> data)
      : _this = switch (T) {
          const (Uint8List) => Uint8List.fromList(data),
          const (Uint16List) => Uint16List.fromList(data),
          const (Uint32List) => Uint32List.fromList(data),
          const (Int8List) => Int8List.fromList(data),
          const (Int16List) => Int16List.fromList(data),
          const (Int32List) => Int32List.fromList(data),
          _ => throw UnsupportedError('$T is not an int list'),
        } as T;

  IntArray.cast(TypedData data, [int typedOffset = 0, int? end])
      : assert(switch (T) { const (Uint8List) || const (Uint16List) || const (Uint32List) || const (Int8List) || const (Int16List) || const (Int32List) => true, _ => false }, '$T is not an int list'),
        _this = TypedArray<T>.cast(data) as T;

  // pass this through cast
  factory IntArray(int length) => TypedArray<T>(length) as IntArray<T>;

  /// same as `TypedData.fromList` when `length < this.length`
  /// fills length when `length > this.length` and accepts [Iterable<int>] where as `TypedData.fromList` does not
  factory IntArray.from(Iterable<int> values, [int? length]) => IntArray<T>(length ?? values.length)..asThis.setAll(0, values.take(length ?? values.length));

  List<int> get asThis => _this as List<int>;

  // Derived from Iterable<int> String functions
  // Only available for TypeData implementing List<int>

  String asString() => String.fromCharCodes(asThis);

  T? seekElement(int match) => seekOrNull(asThis.indexOf(match));
  T? seekSequence(Iterable<int> match) => seekOrNull(asThis.indexOfSequence(match));
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
/// TypedDataOfIterable
////////////////////////////////////////////////////////////////////////////////
extension TypedDataOfIterable on Iterable<int> {
  // return as List<int>?
  R toIntArray<R extends TypedData>([int? length]) => IntArray<R>.from(this, length) as R;

  /// Match
  /// included here for IntArray.seekSequence
  /// avoid naming collision with List.indexOf
  int indexOfSequence(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));

  /// String
  /// toStringAsCharCodes
  String toStringAsCode([int start = 0, int? end]) => String.fromCharCodes(this, start, end);
  String asString() => toStringAsCode();
}

/// Slices on List<int> cannot return TypedData
extension TypedDataSlices on TypedData {
  Iterable<T> typedSlices<T extends TypedData>(int length) sync* {
    if (length < 1) throw RangeError.range(length, 1, null, 'length');
    for (var offset = 0; offset < lengthInBytes; offset += length) {
      yield TypedArray<T>.cast(this, offset, min(offset + length, lengthInBytes)).asThis;
      // todo range of bytes being viewed must be multiples.
    }
  }
}

// todo merge
extension SeekBytes on Uint8List {
  Uint8List? seekViewOfIndex(int index) => (index > -1) ? Uint8List.sublistView(this, index) : null;
  Uint8List? seekViewOfChar(int match) => seekViewOfIndex(indexOf(match));
  Uint8List? seekViewOfMatch(Iterable<int> match) => seekViewOfIndex(indexOfSequence(match));
}
