import 'dart:typed_data';

void memCpy(TypedData destination, TypedData source, int lengthInBytes) {
  Uint8List.sublistView(destination).setAll(0, Uint8List.sublistView(source, 0, lengthInBytes));
}

// void copyMemory(TypedData destination, TypedData source, [int? lengthInBytes]) {
//   final effectiveLength = (lengthInBytes ?? source.lengthInBytes).clamp(0, destination.lengthInBytes);
//   memCopy(destination, source, effectiveLength);
// }

void copyMemoryRange(TypedData destination, TypedData source, [int destOffset = 0, int? lengthInBytes]) {
  final effectiveLength = (lengthInBytes ?? source.lengthInBytes).clamp(0, destination.lengthInBytes - destOffset);
  Uint8List.sublistView(destination).setAll(destOffset, Uint8List.sublistView(source, 0, effectiveLength));
}

extension Uint8ListCopy on Uint8List {
  void copyMax(TypedData source, [int? length]) {
    final effectiveLength = (length ?? source.lengthInBytes).clamp(0, lengthInBytes);
    setAll(0, Uint8List.sublistView(source, 0, effectiveLength));
  }

  void copyRange(TypedData source, [int index = 0, int? length]) {
    final effectiveLength = (length ?? source.lengthInBytes).clamp(0, lengthInBytes - index);
    setAll(index, Uint8List.sublistView(source, 0, effectiveLength));
  }
}

extension TypedDataExt on TypedData {
  /// this method uses length, not end, unlike setAll/setRange
  void copyMax(TypedData source, [int? lengthInBytes]) => Uint8List.sublistView(this).copyMax(source, lengthInBytes);
  void copyRange(TypedData source, [int index = 0, int? lengthInBytes]) => Uint8List.sublistView(this).copyRange(source, index, lengthInBytes);

  Uint8List asUint8List([int offsetInBytes = 0, int? length]) => Uint8List.sublistView(this, offsetInBytes, length);
  // Int8List asInt8List([int offsetInBytes = 0, int? length]);
  // Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]);
  // Uint16List asUint16List([int offsetInBytes = 0, int? length]);
  // Int16List asInt16List([int offsetInBytes = 0, int? length]);
  // Uint32List asUint32List([int offsetInBytes = 0, int? length]);
  // Int32List asInt32List([int offsetInBytes = 0, int? length]);
  // Uint64List asUint64List([int offsetInBytes = 0, int? length]);
  // Int64List asInt64List([int offsetInBytes = 0, int? length]);
  ByteData asByteData([int offsetInBytes = 0, int? length]) => ByteData.sublistView(this, offsetInBytes, length);
}



// void doSomething(TypedData data) {
//   data.buffer.asByteData(data.offsetInBytes).getInt64(5);
//   ByteData.sublistView(data).getInt64(5);
//   Int64List.sublistView(data)[5];
// }

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
