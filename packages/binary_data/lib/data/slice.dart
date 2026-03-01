import 'dart:math';

/// [Slicer]
/// mixin to partitionable objects
// mixin Sliceable<T extends Sliceable<dynamic>> { constrain to subtypes of self
mixin Sliceable<T> {
  // int get start => 0;
  int get totalLength;
  T slice(int start, int end);

  Iterable<T> slices(int sliceLength) sync* {
    for (var index = 0; index < totalLength; index += sliceLength) {
      yield slice(index, min(index + sliceLength, totalLength));
    }
  }
}

class Slicer<T> {
  const Slicer(this.slicer, this.length);
  final T Function(int start, int end) slicer;
  final int length; // total length of the data
  // final int start;

  Iterable<T> slices(int sliceLength) sync* {
    for (var index = 0; index < length; index += sliceLength) {
      yield slicer(index, min(index + sliceLength, length));
    }
  }
}

extension RecordSlices<T extends Record> on T {
  Iterable<T> slices(T Function(int start, int end) slicer, int totalLength, int sliceLength) => Slicer(slicer, totalLength).slices(sliceLength);
}

// with length property
// extension LengthSlices<T extends dynamic> on T {
//   int get totalLength => this.length;
//   Iterable<T> slices(T Function(int start, int end) slicer, int sliceLength) => Slicer(slicer, totalLength).slices(sliceLength);
// }
