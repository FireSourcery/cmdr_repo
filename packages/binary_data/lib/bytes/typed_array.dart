import 'dart:math';
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
  // ByteData dataAt(int offset, [int? length]) => asByteData(offset, length);
}

extension ByteDataTypedArray on ByteData {
  // int get end => offsetInBytes + lengthInBytes; // index of last byte + 1
  // int get length => lengthInBytes;

  /// offsetInBytes
  /// length using parameter T type size
  // let ByteBuffer handle RangeError
  T arrayAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => asTypedIntList<T>(offset, length);

  // // testPart
  // /// `this.length`
  bool testLength(int offset, int length) => (offset + length > offsetInBytes + lengthInBytes);
  T? arrayOrNullAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => testLength(offset, length ?? 0) ? arrayAt<T>(offset, length) : null;
}


// ///  offsets in elements
// extension on TypedData {  
  // bool testEnd(int start, int end) => (offset + start > length) || (end > offset + start + length);
  // bool testLength(int start, int length)
  // R asTypedArray<R extends TypedData>([int typedOffset = 0, int? end]) => TypedArray<R>.cast(this, typedOffset, end) as R;
  // R? asTypedArrayOrNull<R extends TypedData>([int typedOffset = 0, int? end]) => testBounds(typedOffset, end) ? asTypedArray<R>(typedOffset, end) : null;
// }

////////////////////////////////////////////////////////////////////////////////
/// as `this` type
/// outer interface only
////////////////////////////////////////////////////////////////////////////////
// extension ThisTypeView on TypedData {
//   TypeKey<TypedData> get typeKey {
//     return switch (this) {
//       Uint8List() => const TypeKey<Uint8List>(),
//       Uint16List() => const TypeKey<Uint16List>(),
//       Uint32List() => const TypeKey<Uint32List>(),
//       Int8List() => const TypeKey<Int8List>(),
//       Int16List() => const TypeKey<Int16List>(),
//       Int32List() => const TypeKey<Int32List>(),
//       ByteData() => const TypeKey<ByteData>(),
//       _ => throw UnimplementedError(),
//     };
//   }

//   TypeRestrictedKey<TypedData, TypedData> get typeRestrictedKey {
//     return switch (this) {
//       Uint8List() => const TypeRestrictedKey<Uint8List, TypedData>(),
//       Uint16List() => const TypeRestrictedKey<Uint16List, TypedData>(),
//       Uint32List() => const TypeRestrictedKey<Uint32List, TypedData>(),
//       Int8List() => const TypeRestrictedKey<Int8List, TypedData>(),
//       Int16List() => const TypeRestrictedKey<Int16List, TypedData>(),
//       Int32List() => const TypeRestrictedKey<Int32List, TypedData>(),
//       ByteData() => const TypeRestrictedKey<ByteData, TypedData>(),
//       _ => throw UnimplementedError(),
//     };
//   }
// }
