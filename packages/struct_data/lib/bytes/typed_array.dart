import 'dart:typed_data';

import 'typed_data_ext.dart';

export 'dart:typed_data';

////////////////////////////////////////////////////////////////////////////////
/// [sublistView] using [length] instead of [end]
/// Effectively moving up [ByteBuffer] layer, to [TypedData] view segment accounting for [this.offsetInBytes]
////////////////////////////////////////////////////////////////////////////////
/// offsets in bytes for simplicity, correspond with [ByteBuffer]
/// length using type size
extension TypedDataCast on TypedData {
  // ignore: unused_element
  T Function([int offsetInBytes, int? length]) _asTypedIntListFn<T extends TypedDataList<int>>() {
    return switch (T) {
          const (Uint8List) => buffer.asUint8List,
          const (Uint8ClampedList) => buffer.asUint8ClampedList,
          const (Uint16List) => buffer.asUint16List,
          const (Uint32List) => buffer.asUint32List,
          const (Uint64List) => buffer.asUint64List,
          const (Int8List) => buffer.asInt8List,
          const (Int16List) => buffer.asInt16List,
          const (Int32List) => buffer.asInt32List,
          const (Int64List) => buffer.asInt64List,
          _ => throw UnimplementedError(),
        }
        as T Function([int offsetInBytes, int? length]);
  }

  // T asTypedIntList<T extends TypedDataList<int>>([int offsetInBytes = 0, int? length]) => _asTypedIntListFn<T>().call(this.offsetInBytes + offsetInBytes, length);
  T asTypedIntList<T extends TypedDataList<int>>([int offsetInBytes = 0, int? length]) {
    return switch (T) {
          const (Uint8List) => buffer.asUint8List(this.offsetInBytes + offsetInBytes, length),
          const (Uint8ClampedList) => buffer.asUint8ClampedList(this.offsetInBytes + offsetInBytes, length),
          const (Uint16List) => buffer.asUint16List(this.offsetInBytes + offsetInBytes, length),
          const (Uint32List) => buffer.asUint32List(this.offsetInBytes + offsetInBytes, length),
          const (Uint64List) => buffer.asUint64List(this.offsetInBytes + offsetInBytes, length),
          const (Int8List) => buffer.asInt8List(this.offsetInBytes + offsetInBytes, length),
          const (Int16List) => buffer.asInt16List(this.offsetInBytes + offsetInBytes, length),
          const (Int32List) => buffer.asInt32List(this.offsetInBytes + offsetInBytes, length),
          const (Int64List) => buffer.asInt64List(this.offsetInBytes + offsetInBytes, length),
          _ => throw UnimplementedError(),
        }
        as T;
  }

  ByteData asByteData([int offsetInBytes = 0, int? length]) => buffer.asByteData(this.offsetInBytes + offsetInBytes, length);
}

extension ByteDataArrayAccess on ByteData {
  /// offsetInBytes
  /// length using parameter T type size
  // let ByteBuffer handle RangeError
  T arrayAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => asTypedIntList<T>(offset, length);

  // testPart
  /// `this.length`
  bool testLength(int offset, int length) => (offset + length <= lengthInBytes);
  T? arrayOrNullAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => testLength(offset, length ?? 0) ? arrayAt<T>(offset, length) : null;
}


///  offsets in elements
// extension on TypedData {  
//   bool testEnd(int start, int end) => end <= lengthInBytes; 
//   R asTypedArray<R extends TypedData>([int typedOffset = 0, int? end]) => sublistView(this, typedOffset, end) as R;
//   R? asTypedArrayOrNull<R extends TypedData>([int typedOffset = 0, int? end]) => testEnd(typedOffset, end ?? lengthInBytes) ? asTypedArray<R>(typedOffset, end) : null;
// }
 