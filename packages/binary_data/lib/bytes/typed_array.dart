import 'dart:math';
import 'dart:typed_data';

import 'typed_data_ext.dart';

export 'dart:typed_data';

/// [TypedArray<T extends TypedData>] - `Generic TypedData`
/// wrapped + additional constructors for [TypedData] and [TypedDataList]
// ArrayData, TypedArray
extension type const TypedArray<T extends TypedDataList>._(T _this) implements TypedData, TypedDataList {
  TypedArray(int length) : this._(typedList<T>(length));

  // constructor for arrayAt<T>() using end
  // offset uses parameter 'data' instance type, not T type,
  // sublistView handle range error
  // alternatively unified calculation on buffer directly
  TypedArray.cast(TypedData data, [int start = 0, int? end]) : this._(sublistView<T>(data, start, end));

  // TypedArray.cast(TypedData data, [int typedOffset = 0, int? end])
  //   : _this = switch (T) {
  //       // prefer super function anti pattern. cannot compose from all sub type groups without overlap
  //       const (TypedData) || const (dynamic) => data.typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => sublistView<G>(data, typedOffset, end) as T),
  //       _ => sublistView<T>(data, typedOffset, end),
  //       // const (ByteData) => throw UnsupportedError('ByteData is not a typed list'),
  //     };

  /// effectively sublist with extendable length
  /// length in T size
  /// same as `TypedData.fromList` when `length < this.length`
  /// fills length when `length > this.length` and accepts [Iterable<int>] where as `TypedData.fromList` does not
  factory TypedArray.fromData(TypedData data, [int? length]) {
    final byteLength = (length != null) ? length * bytesPerElementOf<T>() : data.lengthInBytes;
    final copyLength = min(byteLength, data.lengthInBytes);
    return TypedArray<T>.cast(Uint8List(byteLength)..setAll(0, Uint8List.sublistView(data, 0, copyLength)));

    // return TypedArray<T>(length ?? data.lengthInBytes ~/ bytesPerElementOf<T>()).._this.buffer.asUint8List().setAll(0, Uint8List.sublistView(data, 0, copyLength));
  }

  //
  factory TypedArray.fromValues(TypedDataList values, [int? length]) {
    final newLength = length ?? values.length;
    return TypedArray<T>(newLength)..setAll(0, values.take(newLength));

    // if (length != null) {
    //   return TypedArray<T>(length)..setAll(0, values.take(length));
    // } else {
    //   return fromList(elements);
    // }
  }

  T get asThis => _this;
}

////////////////////////////////////////////////////////////////////////////////
/// [sublistView] using [length] instead of [end]
/// Effectively moving up [ByteBuffer] layer, to [TypedData] view segment accounting for [this.offsetInBytes]
// alternatively cast as TypedArray for access
////////////////////////////////////////////////////////////////////////////////
/// all offsets in elements
extension on TypedData {
  // R asTypedArray<R extends TypedData>([int typedOffset = 0, int? end]) => TypedArray<R>.cast(this, typedOffset, end) as R;
  // R? asTypedArrayOrNull<R extends TypedData>([int typedOffset = 0, int? end]) => testBounds(typedOffset, end) ? asTypedArray<R>(typedOffset, end) : null;
}

/// all offsets in bytes for simplicity
extension on TypedData {
  T Function([int offsetInBytes, int? length]) _asTypedIntList<T extends TypedDataList<int>>([int offsetInBytes = 0, int? length]) {
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

  T asTypedIntList<T extends TypedDataList<int>>([int offsetInBytes = 0, int? length]) => _asTypedIntList<T>(this.offsetInBytes + offsetInBytes, length) as T;

  ByteData asByteData([int offsetInBytes = 0, int? length]) => buffer.asByteData(this.offsetInBytes + offsetInBytes, length);
}

extension ByteDataTypedArray on ByteData {
  int get end => offsetInBytes + lengthInBytes; // index of last byte + 1
  int get length => lengthInBytes;

  //testPart
  bool testLength(int offset, int? length) {
    assert(offset >= 0, 'Offset must be non-negative: $offset');
    if (offset > this.length) return false;
    if (length != null && (offset + length > this.length)) return false;
    return true;
  }

  ByteData dataAt(int offset, [int? length]) => asByteData(offset, length);

  // let ByteBuffer handle RangeError
  T arrayAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => asTypedIntList<T>(offset, length);
  T? arrayOrNullAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => testLength(offset, length) ? arrayAt<T>(offset, length) : null;

  // List<int> arrayOrEmptyAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => testLength(offset, length) ? arrayAt<T>(offset, length) : <int>[];
  // returning the same type may be more optimal
  // static TypedDataList<int> emptyIntList = Int64List(0);
  // T intListEmpty<T extends TypedDataList<int>>() {
  //   return switch (T) {
  //         const (Uint8List) => emptyIntList,
  //         const (Uint16List) => Uint16List(0),
  //         const (Uint32List) => Uint32List(0),
  //         const (Int8List) => Int8List(0),
  //         const (Int16List) => Int16List(0),
  //         const (Int32List) => Int32List(0),
  //         _ => throw UnimplementedError(),
  //       }
  //       as T;
  // }
}

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

////////////////////////////////////////////////////////////////////////////////
/// TypedDataOfIterable
////////////////////////////////////////////////////////////////////////////////
// void memCpy(TypedData destination, TypedData source, int lengthInBytes) {
//   Uint8List.sublistView(destination).setAll(0, Uint8List.sublistView(source, 0, lengthInBytes));
// }

// void copyMemory(TypedData destination, TypedData source, [int? lengthInBytes]) {
//   final effectiveLength = (lengthInBytes ?? source.lengthInBytes).clamp(0, destination.lengthInBytes);
//   memCpy(destination, source, effectiveLength);
// }

// void copyMemoryRange(TypedData destination, TypedData source, [int destOffset = 0, int? lengthInBytes]) {
//   final effectiveLength = (lengthInBytes ?? source.lengthInBytes).clamp(0, destination.lengthInBytes - destOffset);
//   Uint8List.sublistView(destination).setAll(destOffset, Uint8List.sublistView(source, 0, effectiveLength));
// }
