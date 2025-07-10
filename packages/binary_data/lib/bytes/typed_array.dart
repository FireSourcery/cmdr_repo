import 'dart:math';
import 'dart:typed_data';

import 'package:binary_data/bits/bits.dart';
import 'package:collection/collection.dart';
import 'package:type_ext/basic_types.dart';

import 'typed_data_ext.dart';
export 'dart:typed_data';

/// [TypedArray<T extends TypedData>] - `Generic TypedData`
/// collected constructors
//  ArrayData, TypedArray
extension type const TypedArray<T extends TypedData>._(T _this) implements TypedData {
  // prefer super function anti pattern. cannot compose from all sub type groups without overlap
  static T typedArrayOf<T extends TypedData>(TypedData data, [int typedOffset = 0, int? end]) {
    return switch (T) {
      const (TypedData) || const (dynamic) => data.typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => sublistView<G>(data, typedOffset, end) as T),
      _ => sublistView<T>(data, typedOffset, end),
      // const (ByteData) => throw UnsupportedError('ByteData is not a typed list'),
    };
  }

  // throws range error
  // offset uses parameter 'data' instance type, not T type,
  TypedArray.cast(TypedData data, [int typedOffset = 0, int? end]) : _this = typedArrayOf<T>(data, typedOffset, end); // todo split view offset and cast
  // TypedArray.castSize(TypedData data, int widthInBytes, [int typedOffset = 0, int? end]) : _this = sizedArrayOf(widthInBytes, data, typedOffset, end) as dynamic;

  // does this need to cast?
  TypedArray(int length) : this.cast(ByteData(length * bytesPerElementOf<T>()));

  // final endianOffset = switch (endian) { Endian.big => 8 - size, Endian.little => 0, Endian() => throw StateError('Endian') };
  // TypedArray.word([int? value]) : this(8);

  // sublist with extendable length
  // length in T size
  /// same as `TypedData.fromList` when `length < this.length`
  /// fills length when `length > this.length` and accepts [Iterable<int>] where as `TypedData.fromList` does not
  factory TypedArray.from(TypedData data, [int? length]) {
    final byteLength = (length != null) ? length * bytesPerElementOf<T>() : data.lengthInBytes;
    return TypedArray<T>.cast(Uint8List(byteLength)..setAll(0, Uint8List.sublistView(data, 0, byteLength)));
    // return TypedArray<T>(byteLength).copyFrom(source, byteLength);
  }

  T get asThis => _this;

  // TypedList version of List<int>.skip
  T seek(int index) => TypedArray<T>.cast(this, index).asThis;
  T? seekOrNull(int index) => (index > -1) ? seek(index) : null;
}

// this can remove for TypedList<int>
/// [const IntArray<T extends TypedData>] - `Typed Int List`
/// TypeData subset that with [List<int>] interface
extension type const IntArray<T extends TypedData>._(T _this) implements TypedData, TypedArray<T> {
  IntArray._fromList(List<int> elements) : _this = _fromList<T>(elements);

  IntArray.cast(TypedData data, [int typedOffset = 0, int? end])
      : assert(
          switch (T) {
            const (Uint8List) || const (Uint16List) || const (Uint32List) || const (Uint64List) => true,
            const (Int8List) || const (Int16List) || const (Int32List) || const (Int64List) => true,
            _ => false
          },
          '$T is not an int list',
        ),
        _this = TypedArray<T>.cast(data, typedOffset, end) as T;

  // pass this through cast
  factory IntArray(int length) => TypedArray<T>(length) as IntArray<T>;

  factory IntArray.from(Iterable<int> values, [int? length]) {
    final newLength = length ?? values.length;
    return IntArray<T>(newLength)..asThis.setAll(0, values.take(newLength));
  }

  List<int> get asThis => _this as List<int>;
}

////////////////////////////////////////////////////////////////////////////////
/// Wrappers as top level functions
////////////////////////////////////////////////////////////////////////////////
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

/// length is in elements
T typedList<T extends TypedData>(int length) {
  return switch (T) {
    const (Uint8List) => Uint8List(length),
    const (Uint16List) => Uint16List(length),
    const (Uint32List) => Uint32List(length),
    const (Int8List) => Int8List(length),
    const (Int16List) => Int16List(length),
    const (Int32List) => Int32List(length),
    _ => throw UnimplementedError(),
  } as T;
}

T _fromList<T extends TypedData>(List<int> elements) {
  return switch (T) {
    const (Uint8List) => Uint8List.fromList(elements),
    const (Uint16List) => Uint16List.fromList(elements),
    const (Uint32List) => Uint32List.fromList(elements),
    const (Int8List) => Int8List.fromList(elements),
    const (Int16List) => Int16List.fromList(elements),
    const (Int32List) => Int32List.fromList(elements),
    _ => throw UnsupportedError('$T is not an int list'),
  } as T;
}

/// offset uses type of 'data' not T type.
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
  } as T;
}

//   static TypedData sizedArrayOf(int widthInBytes, TypedData data, [int offsetInBytes = 0, int? length]) {
//   return switch (widthInBytes) {
//     1 => Uint8List.sublistView(data, offsetInBytes, length),
//     2 => Uint16List.sublistView(data, offsetInBytes, length),
//     4 => Uint32List.sublistView(data, offsetInBytes, length),
//     8 => Uint64List.sublistView(data, offsetInBytes, length),
//     _ => throw UnsupportedError('widthInBytes: $widthInBytes'),
//   };
// }

int? endOf(int offset, int? length) => (length != null) ? length + offset : null;

extension on TypedData {
  ByteData asByteData([int offsetInBytes = 0, int? length]) => buffer.asByteData(this.offsetInBytes + offsetInBytes, length);

  T asTypedIntList<T extends TypedDataList<int>>([int offsetInBytes = 0, int? length]) {
    return switch (T) {
      const (Uint8List) => buffer.asUint8List(offsetInBytes, length),
      const (Uint16List) => buffer.asUint16List(this.offsetInBytes + offsetInBytes, length),
      const (Uint32List) => buffer.asUint32List(this.offsetInBytes + offsetInBytes, length),
      const (Int8List) => buffer.asInt8List(this.offsetInBytes + offsetInBytes, length),
      const (Int16List) => buffer.asInt16List(this.offsetInBytes + offsetInBytes, length),
      const (Int32List) => buffer.asInt32List(this.offsetInBytes + offsetInBytes, length),
      _ => throw UnimplementedError(),
    } as T;
  }
}

// sublistView using length instead of end
// all offsets in bytes for simplicity
extension AsGenericTypedList on ByteData {
  static int? endOf(int offset, int? length) => (length != null) ? length + offset : null;

  int get length => lengthInBytes;

  bool testLength(int offset, int? length) {
    if (offset > this.length) return false;
    if (length != null && (offset + this.length > length)) return false;
    return true;
  }

  ByteData dataAt(int offset, [int? length]) => asByteData(offset, length);

  T arrayAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => asTypedIntList<T>(offset, length);
  T? arrayOrNullAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => testLength(offset, length) ? arrayAt<T>(offset, length) : null;
  List<int> arrayOrEmptyAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => testLength(offset, length) ? arrayAt<T>(offset, length) : <int>[];

  // static TypedDataList<int> emptyIntList = Uint8List(0);

  // List<int> intArrayAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => asIntList<T>(offset, length);
  // List<int> intArrayOrEmptyAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => testLength(offset, length) ? intArrayAt<T>(offset, length) : null;
}

// extension type ByteStruct(ByteData byteData) implements ByteData {
// }

////////////////////////////////////////////////////////////////////////////////
/// List values
/// TypedData Cat Conversion
////////////////////////////////////////////////////////////////////////////////
/// Effectively moving up ByteBuffer layer, to TypedData view segment accounting for offset
/// ArrayView
extension GenericSublistView on TypedData {
  int get endInBytes => offsetInBytes + lengthInBytes; // index of last byte + 1
  int get length => lengthInBytes ~/ elementSizeInBytes;

  bool testBounds(int start, int? end) {
    if (start > length) return false;
    if (end != null && (end > length)) return false;
    return true;
  }

  // todo as offset, length
  // handles R as dynamic as `this` type, while sublistView throws error
  // offset uses type of 'this', not R type.
  R asTypedArray<R extends TypedData>([int typedOffset = 0, int? end]) => TypedArray<R>.cast(this, typedOffset, end).asThis; // return empty list if offset > length by default?
  R? asTypedArrayOrNull<R extends TypedData>([int typedOffset = 0, int? end]) => testBounds(typedOffset, end) ? asTypedArray<R>(typedOffset, end) : null;

  // List<int> asSizedArray(int widthInBytes, [int offsetInBytes = 0, int? length]) => sizedArrayOf(widthInBytes, this, offsetInBytes, length);

  // todo this interface can be remove
  /// [TypedIntList]/[IntArray]
  List<int> asIntList<R extends TypedData>([int typedOffset = 0, int? end]) => IntArray<R>.cast(this, typedOffset, end).asThis;
  List<int> asIntListOrEmpty<R extends TypedData>([int typedOffset = 0, int? end]) => testBounds(typedOffset, end) ? asIntList<R>(typedOffset, end) : const <int>[];
}

/// implementations on TypedData to return as TypedData

/// Slices on [List] cannot return TypedData
extension TypedDataSlices on TypedData {
  // todo range of bytes as multiples.
  Iterable<T> typedSlices<T extends TypedData>(int length) sync* {
    if (length < 1) throw RangeError.range(length, 1, null, 'length');

    for (var offset = 0; offset < lengthInBytes; offset += length) {
      yield sublistView<T>(this, offset, min(offset + length, lengthInBytes));
    }
  }
}

// todo merge
extension SeekBytes on Uint8List {
  Uint8List? seekIndex(int index) => (index > -1) ? Uint8List.sublistView(this, index) : null;
  Uint8List? seekChar(int match) => seekIndex(indexOf(match));
  Uint8List? seekSequence(Iterable<int> match) => seekIndex(indexOfSequence(match));
}

extension TypedDataListExt on TypedDataList<int> {
  // _viewOffsetInBytes(int offsetInBytes) {
  //   //alternatively switch on type
  //   return switch (this.elementSizeInBytes) {
  //     1 => Uint8List.sublistView(this, offsetInBytes),
  //     2 => Uint16List.sublistView(this, offsetInBytes ~/ 2),
  //     4 => Uint32List.sublistView(this, offsetInBytes ~/ 4),
  //     8 => Uint64List.sublistView(this, offsetInBytes ~/ 8),
  //     _ => throw UnsupportedError('Unsupported element size: ${this.elementSizeInBytes} bytes'),
  //   };
  // }

  _viewOffsetTyped(int offsetInElements) {
    //alternatively switch on type
    return switch (this.elementSizeInBytes) {
      1 => Uint8List.sublistView(this, offsetInElements),
      2 => Uint16List.sublistView(this, offsetInElements),
      4 => Uint32List.sublistView(this, offsetInElements),
      8 => Uint64List.sublistView(this, offsetInElements),
      _ => throw UnsupportedError('Unsupported element size: ${this.elementSizeInBytes} bytes'),
    };
  }

  TypedDataList<int>? seek(int index) => (index > -1) ? _viewOffsetTyped(index) : null;

  TypedDataList<int>? seekChar(int match) => seek(indexOf(match));
  TypedDataList<int>? seekSequence(Iterable<int> match) => seek(String.fromCharCodes(this).indexOf(String.fromCharCodes(match)));

  String asString() => String.fromCharCodes(this);

  // T? seekElement(int match) => seekOrNull(this.indexOf(match));
  // T? seekSequence(Iterable<int> match) => seekOrNull(this.indexOfSequence(match));
}

////////////////////////////////////////////////////////////////////////////////
/// as `this` type
/// outer interface only, no implementation
////////////////////////////////////////////////////////////////////////////////
extension ThisTypeView on TypedData {
  TypeKey<TypedData> get typeKey {
    return switch (this) {
      Uint8List() => const TypeKey<Uint8List>(),
      Uint16List() => const TypeKey<Uint16List>(),
      Uint32List() => const TypeKey<Uint32List>(),
      Int8List() => const TypeKey<Int8List>(),
      Int16List() => const TypeKey<Int16List>(),
      Int32List() => const TypeKey<Int32List>(),
      ByteData() => const TypeKey<ByteData>(),
      _ => throw UnimplementedError(),
    };
  }

  TypeRestrictedKey<TypedData, TypedData> get typeRestrictedKey {
    return switch (this) {
      Uint8List() => const TypeRestrictedKey<Uint8List, TypedData>(),
      Uint16List() => const TypeRestrictedKey<Uint16List, TypedData>(),
      Uint32List() => const TypeRestrictedKey<Uint32List, TypedData>(),
      Int8List() => const TypeRestrictedKey<Int8List, TypedData>(),
      Int16List() => const TypeRestrictedKey<Int16List, TypedData>(),
      Int32List() => const TypeRestrictedKey<Int32List, TypedData>(),
      ByteData() => const TypeRestrictedKey<ByteData, TypedData>(),
      _ => throw UnimplementedError(),
    };
  }

  // R callAsThis<R>(R Function<T extends TypedData>() callback) => typeRestrictedKey.callWithRestrictedType(callback);

  // sublistView as 'this' type
  // TypedData? seek(int index) => typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => asTypedArrayOrNull<G>(index));

  // IntList only
  String asString() => typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => asIntListOrEmpty<G>()).asString();
}

////////////////////////////////////////////////////////////////////////////////
/// TypedDataOfIterable
////////////////////////////////////////////////////////////////////////////////
// todo move or remove,
extension TypedDataOfIterable on Iterable<int> {
  /// Match
  /// included here for IntArray.seekSequence
  /// avoid naming collision with List.indexOf
  int indexOfSequence(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));

  /// String
  /// toStringAsCharCodes
  String toStringAsCode([int start = 0, int? end]) => String.fromCharCodes(this, start, end);
  String asString() => toStringAsCode();
}

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
