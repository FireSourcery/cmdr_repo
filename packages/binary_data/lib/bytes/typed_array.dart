import 'dart:math';
import 'dart:typed_data';

import 'package:type_ext/basic_types.dart';

import 'typed_data_ext.dart';
export 'dart:typed_data';

/// [TypedArray<T extends TypedData>] - `Generic TypedData`
/// via collected constructors
//  ArrayData, TypedArray
extension type const TypedArray<T extends TypedData>._(T _this) implements TypedData {
  // prefer super function anti pattern. cannot compose from all sub type groups without overlap
  static T typedArrayOf<T extends TypedData>(TypedData data, [int typedOffset = 0, int? end]) {
    return switch (T) {
      const (TypedData) || const (dynamic) => data.typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => sublistView<G>(data, typedOffset, end) as T),
      const (ByteData) => throw UnsupportedError('ByteData is not a typed list'),
      _ => sublistView<T>(data, typedOffset, end),
    };
  }

  // throws range error
  // offset uses parameter 'data' instance type, not T type,
  TypedArray.cast(TypedData data, [int typedOffset = 0, int? end]) : _this = typedArrayOf<T>(data, typedOffset, end);
  // TypedArray.castSize(TypedData data, int widthInBytes, [int typedOffset = 0, int? end]) : _this = sizedArrayOf(widthInBytes, data, typedOffset, end) as dynamic;

  // does this need to cast?
  TypedArray(int length) : this.cast(ByteData(length * bytesPerElementOf<T>()));

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
  T seek(int index) => TypedArray<T>.cast(this, index).asThis;
  T? seekOrNull(int index) => (index > -1) ? seek(index) : null;
}

/// [const IntArray<T extends TypedData>] - `Typed Int List`
/// TypeData subset that with List<int> interface
// todo change _this to List<int>?
// or should the representation be a List<int>? for direct index a
extension type const IntArray<T extends TypedData>._(T _this) implements TypedData, TypedArray<T> {
  static TypedData sizedArrayOf(int widthInBytes, TypedData data, [int offsetInBytes = 0, int? length]) {
    return switch (widthInBytes) {
      1 => Uint8List.sublistView(data, offsetInBytes, length),
      2 => Uint16List.sublistView(data, offsetInBytes, length),
      4 => Uint32List.sublistView(data, offsetInBytes, length),
      8 => Uint64List.sublistView(data, offsetInBytes, length),
      _ => throw UnsupportedError('widthInBytes: $widthInBytes'),
    };
  }

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
        _this = TypedArray<T>.cast(data) as T;

  // pass this through cast
  factory IntArray(int length) => TypedArray<T>(length) as IntArray<T>;

  /// same as `TypedData.fromList` when `length < this.length`
  /// fills length when `length > this.length` and accepts [Iterable<int>] where as `TypedData.fromList` does not
  factory IntArray.from(Iterable<int> values, [int? length]) {
    final newLength = length ?? values.length;
    return IntArray<T>(newLength)..asThis.setAll(0, values.take(newLength));
  }

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

/// offset uses type of 'data' not T type. typedOffset * data.elementSizeInBytes = byteSize
T sublistView<T extends TypedData>(TypedData data, [int typedOffset = 0, int? end]) {
  return switch (T) {
    const (Uint8List) => Uint8List.sublistView(data, typedOffset, end),
    const (Uint16List) => Uint16List.sublistView(data, typedOffset, end),
    const (Uint32List) => Uint32List.sublistView(data, typedOffset, end),
    const (Int8List) => Int8List.sublistView(data, typedOffset, end),
    const (Int16List) => Int16List.sublistView(data, typedOffset, end),
    const (Int32List) => Int32List.sublistView(data, typedOffset, end),
    const (ByteData) => ByteData.sublistView(data, typedOffset, end),
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

////////////////////////////////////////////////////////////////////////////////
/// List values
/// TypedData Cat Conversion
////////////////////////////////////////////////////////////////////////////////
/// Effectively moving up ByteBuffer layer, to TypedData view segment accounting for offset
extension GenericSublistView on TypedData {
  int get end => offsetInBytes + lengthInBytes; // index of last byte + 1
  // int get length => lengthInBytes ~/ elementSizeInBytes;

  // bool testBounds(int offset, int length) => (offset >= 0 && length >= 0 && offset + length <= lengthInBytes);
  bool testBounds(int offset, int? end) => ((offset * elementSizeInBytes) <= (end ?? this.end));

  // offset uses type of 'this', not R type.
  R asTypedArray<R extends TypedData>([int typedOffset = 0, int? end]) => TypedArray<R>.cast(this, typedOffset, end).asThis; // return empty list if offset > length by default?
  R? asTypedArrayOrNull<R extends TypedData>([int typedOffset = 0, int? end]) => testBounds(typedOffset, end) ? asTypedArray<R>(typedOffset, end) : null;

  // List<int> asSizedArray(int widthInBytes, [int offsetInBytes = 0, int? length]) => sizedArrayOf(widthInBytes, this, offsetInBytes, length);

  // orEmpty by default?
  /// [TypedIntList]/[IntArray]
  List<int> asIntList<R extends TypedData>([int typedOffset = 0, int? end]) => IntArray<R>.cast(this, typedOffset, end).asThis;
  List<int> asIntListOrEmpty<R extends TypedData>([int typedOffset = 0, int? end]) => testBounds(typedOffset, end) ? asIntList<R>(typedOffset, end) : const <int>[];

  /// move to array list?
  /// as `this` type
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
  TypedData? seek(int index) => typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => asTypedArrayOrNull<G>(index));

  // IntList only
  String asString() => typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => asIntListOrEmpty<G>()).asString();
}

/// Slices on [List] cannot return TypedData
extension TypedDataSlices on TypedData {
  Iterable<T> typedSlices<T extends TypedData>(int length) sync* {
    if (length < 1) throw RangeError.range(length, 1, null, 'length');
    for (var offset = 0; offset < lengthInBytes; offset += length) {
      yield TypedArray<T>.cast(this, offset, min(offset + length, lengthInBytes)).asThis;
      // todo range of bytes being viewed must be multiples.
    }
  }
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

// todo merge
extension SeekBytes on Uint8List {
  Uint8List? seekIndex(int index) => (index > -1) ? Uint8List.sublistView(this, index) : null;
  Uint8List? seekChar(int match) => seekIndex(indexOf(match));
  Uint8List? seekSequence(Iterable<int> match) => seekIndex(indexOfSequence(match));
}
