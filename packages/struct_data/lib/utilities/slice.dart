import 'dart:math';

/// [Slicer]

class Slicer<T> {
  const Slicer(this.slicer, this.length);
  final T Function(int start, int end) slicer;
  final int length;

  Iterable<T> slices(int sliceLength) sync* {
    for (var index = 0; index < length; index += sliceLength) {
      yield slicer(index, min(index + sliceLength, length));
    }
  }
}

extension RecordSlices<T extends Record> on T {
  Iterable<T> slices(T Function(int start, int end) slicer, int totalLength, int sliceLength) => Slicer(slicer, totalLength).slices(sliceLength);
}

/// mixin to partitionable objects
mixin Sliceable<T> {
  int get totalLength;
  T slice(int start, int end);

  Iterable<T> slices(int sliceLength) sync* {
    for (var index = 0; index < totalLength; index += sliceLength) {
      yield slice(index, min(index + sliceLength, totalLength));
    }
  }
}
