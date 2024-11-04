import 'dart:math';
import 'dart:typed_data';

void memoryCopy(TypedData destination, TypedData source, [int? lengthInBytes]) {
  int effectiveLength = min(destination.lengthInBytes, lengthInBytes ?? source.lengthInBytes);
  Uint8List.sublistView(destination).setAll(0, Uint8List.sublistView(source, 0, effectiveLength));
}

extension TypedDataExt on TypedData {
  // this method uses length, not end, unlike setRange
  // is it more optimal to cast one side only?
  void copyFrom(TypedData source, [int? lengthInBytes]) => memoryCopy(this, source, lengthInBytes);
}



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
