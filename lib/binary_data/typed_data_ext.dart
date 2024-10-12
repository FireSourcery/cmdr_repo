import 'dart:collection';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';

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
    const (Uint16List) => Uint16List.bytesPerElement,
    const (Uint32List) => Uint32List.bytesPerElement,
    const (Int8List) => Int8List.bytesPerElement,
    const (Int16List) => Int16List.bytesPerElement,
    const (Int32List) => Int32List.bytesPerElement,
    _ => throw UnimplementedError(),
  };
}

/// constructors
/// or should this be on ByteBuffer?
extension type const TypedList<T extends TypedData>._(T _this) implements TypedData {
  TypedList(int length) : _this = ByteData(length * bytesPerElementOf<T>()).sublistView<T>();
  TypedList.cast(TypedData data) : _this = data.sublistView<T>();

  // sublist with extendable length
  factory TypedList.from(TypedData data, [int? length]) {
    final byteLength = (length != null) ? length * bytesPerElementOf<T>() : data.lengthInBytes;
    return TypedList<T>.cast(Uint8List(byteLength)..setAll(0, data.sublistView<Uint8List>()));
  }

  // factory TypedList.fromIntList(List<int> data, [int? length]) = TypedIntList<R>.from;
}

// TypeData subset that implements List<int>
extension type const TypedIntList<T extends TypedData>._(T _this) implements TypedData {
  factory TypedIntList(int length) => TypedList<T>(length) as TypedIntList<T>;
  // TypedIntList(int length)
  //     : _this = switch (T) {
  //         const (Uint8List) => Uint8List(length),
  //         const (Uint16List) => Uint16List(length),
  //         const (Uint32List) => Uint32List(length),
  //         const (Int8List) => Int8List(length),
  //         const (Int16List) => Int16List(length),
  //         const (Int32List) => Int32List(length),
  //         _ => throw UnsupportedError('$T is not an int list'),
  //       };

  TypedIntList.cast(TypedData data)
      : assert(switch (T) { const (Uint8List) || const (Uint16List) || const (Uint32List) || const (Int8List) || const (Int16List) || const (Int32List) => true, _ => false }, '$T is not an int list'),
        _this = data.sublistView<T>();

  TypedIntList._from(List<int> data)
      : _this = switch (T) {
          const (Uint8List) => Uint8List.fromList(data),
          const (Uint16List) => Uint16List.fromList(data),
          const (Uint32List) => Uint32List.fromList(data),
          const (Int8List) => Int8List.fromList(data),
          const (Int16List) => Int16List.fromList(data),
          const (Int32List) => Int32List.fromList(data),
          _ => throw UnsupportedError('$T is not an int list'),
        } as T;

  factory TypedIntList.from(List<int> values, [int? length]) {
    if (length case int length when length > values.length) {
      return TypedIntList<T>.cast(TypedList<T>(length))..data.setAll(0, values);
    } else {
      return TypedIntList<T>._from(values);
    }
  }

  // List<int> get data => _this.asIntList<T>();
  List<int> get data => _this as List<int>;

  // String functions only available for TypeData types implementing List<int>
  T? seekViewOfIndex(int index) => (index > -1) ? sublistView<T>(index) : null; // this can move to TypedList
  T? seekViewOfChar(int match) => seekViewOfIndex(data.indexOf(match));
  T? seekViewOfMatch(Iterable<int> match) => seekViewOfIndex(data.indexOfMatch(match));
}

////////////////////////////////////////////////////////////////////////////////
/// List values
/// TypedData Cat Conversion
////////////////////////////////////////////////////////////////////////////////
/// Effectively ByteBuffer conversion function, but on view segment accounting for offset
extension GenericSublistView on TypedData {
  int get end => offsetInBytes + lengthInBytes; // index of last byte + 1

  // int get length => lengthInBytes ~/ elementSizeInBytes;

  // Type get type => switch (this) {
  //   Uint8List() => Uint8List,
  //   Uint16List() => Uint16List,
  //   Uint32List() => Uint32List,
  //   Int8List() => Int8List,
  //   Int16List() => Int16List,
  //   Int32List() => Int32List,
  //   ByteData() => ByteData,
  //   _ => throw UnimplementedError(),
  // };

  TypedData callAsThis(R Function<R extends TypedData>() callback) {
    return switch (this) {
      Uint8List() => callback<Uint8List>(),
      Uint16List() => callback<Uint16List>(),
      Uint32List() => callback<Uint32List>(),
      Int8List() => callback<Int8List>(),
      Int16List() => callback<Int16List>(),
      Int32List() => callback<Int32List>(),
      ByteData() => callback<ByteData>(),
      _ => throw UnimplementedError(),
    };
  }

  // throws range error
  // offset uses "this" instance type, not R type,
  // prefer super function anti pattern, since sublistView cannot compose from all types without overlap
  R sublistView<R extends TypedData>([int typedOffset = 0, int? end]) {
    return switch (R) {
      const (Uint8List) => Uint8List.sublistView(this, typedOffset, end),
      const (Uint16List) => Uint16List.sublistView(this, typedOffset, end),
      const (Uint32List) => Uint32List.sublistView(this, typedOffset, end),
      const (Int8List) => Int8List.sublistView(this, typedOffset, end),
      const (Int16List) => Int16List.sublistView(this, typedOffset, end),
      const (Int32List) => Int32List.sublistView(this, typedOffset, end),
      const (ByteData) => ByteData.sublistView(this, typedOffset, end),
      const (TypedData) => callAsThis(<G extends TypedData>() => sublistView<G>(typedOffset, end)),
      _ => throw UnimplementedError(),
    } as R;
  }

  R? sublistViewOrNull<R extends TypedData>([int typedOffset = 0, int? end]) => (typedOffset * elementSizeInBytes < lengthInBytes) ? sublistView<R>(typedOffset, end) : null;

  // ByteData asByteData() => ByteData.sublistView(this);
  // R asTypedList<R extends TypedData>([int typedOffset = 0, int? end]) => _sublistView<R>(typedOffset, end);
  // R? asTypedListOrNull<R extends TypedData>([int typedOffset = 0, int? end]) => sublistViewOrNull<R>(typedOffset, end);

  // prefer super function anti pattern, since sublistView cannot compose from all types without overlap
  // use to essentially case type for convenience
  // orEmpty by default?
  List<int> asIntList<R extends TypedData>([int typedOffset = 0, int? end]) {
    assert(switch (R) { const (Uint8List) || const (Uint16List) || const (Uint32List) || const (Int8List) || const (Int16List) || const (Int32List) => true, _ => false }, '$R is not an int list');
    return sublistView<R>(typedOffset, end) as List<int>;
  }

  List<int> asIntListOrEmpty<R extends TypedData>([int typedOffset = 0, int? end]) => (typedOffset * elementSizeInBytes < lengthInBytes) ? asIntList<R>(typedOffset, end) : const <int>[];

  static Endian hostEndian = Endian.host; // resolve once storing results

  // List<num> numListViewHost<R extends TypedData>([int typedOffset = 0, Endian endian = Endian.little]) {
  //   return (hostEndian != endian) ? EndianCastList<R>(this, endian) : sublistView<R>(typedOffset) as R;
  // }

  void copy(TypedData source, [int offset = 0, int? length]) {
    sublistView<Uint8List>().setAll(offset, source.sublistView<Uint8List>(offset, length ?? source.lengthInBytes));
  }
}

extension TypedListSlices on TypedData {
  Iterable<T> typedSlices<T extends TypedData>(int length) sync* {
    if (length < 1) throw RangeError.range(length, 1, null, 'length');
    for (var offset = 0; offset < lengthInBytes; offset += length) {
      yield sublistView<T>(offset, min(offset + length, lengthInBytes));
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

  // int intAt(int byteOffset, int size, [Endian endian = Endian.little]) {
  //   return switch (size) {
  //     const (1) => getInt8(byteOffset),
  //     const (2) => getInt16(byteOffset, endian),
  //     const (4) => getInt32(byteOffset, endian),
  //     _ => throw UnimplementedError(),
  //   };
  // }

  // int wordAt<R extends NativeType>(int byteOffset, [Endian endian = Endian.little]) => uintAt(byteOffset, sizeOf<R>(), endian);
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
  // R toTypedList1<R extends TypedData>([int? length]) => TypedIntList<R>.from(this, length);

  /// String
  /// toStringAsCharCodes
  String toStringAsCode([int start = 0, int? end]) => String.fromCharCodes(this, start, end);

  /// Match
  /// indexOfSequence
  int indexOfMatch(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));
}

extension StringOfBytes on Uint8List {
  // int indexOfBytes(Uint8List match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));
  Uint8List? seekViewOfIndex(int index) => (index > -1) ? Uint8List.sublistView(this, index) : null;
  Uint8List? seekViewOfChar(int match) => seekViewOfIndex(indexOf(match));
  Uint8List? seekViewOfMatch(Iterable<int> match) => seekViewOfIndex(indexOfMatch(match));
}

extension StringOfTypedData<R extends TypedData> on TypedData {
  // index in this.elementSizeInBytes
  // R is determined internally by this.type
  // R? seekViewOfIndex(int index) => (index > -1) ? _sublistView<R>(index) : null;
  // R? seekViewOfChar(int match) => seekViewOfIndex(asIntList<R>().indexOf(match));
  // R? seekViewOfMatch(Iterable<int> match) => seekViewOfIndex(asIntList<R>().indexOfMatch(match));
  // R? _seekViewOfIndex<R extends TypedData>(int index) => (index > -1) ? _sublistView<R>(index) : null;
  // R? _seekViewOfChar<R extends TypedData>(int match) => seekViewOfIndex(asIntList<R>().indexOf(match));
  // R? _seekViewOfMatch<R extends TypedData>(Iterable<int> match) => seekViewOfIndex(asIntList<R>().indexOfMatch(match));
}

///

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
