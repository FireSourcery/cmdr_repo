import 'dart:ffi';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// [TypedDataBuffer] - `BytesBuilderBuffer`
/// effectively, a fixed size [BytesBuilder] - allocated with a persistent buffer
class TypedDataBuffer implements BytesBuilder {
  TypedDataBuffer.origin(this._byteBuffer) : bufferAsBytes = _byteBuffer.asUint8List(0);

  TypedDataBuffer.of(this.bufferAsBytes) : _byteBuffer = bufferAsBytes.buffer;

  TypedDataBuffer(int size) : this.of(Uint8List(size));

  final ByteBuffer _byteBuffer; // TypedDataBuffer can directly retain byteBuffer, its own buffer starts at offset 0

  @protected
  final Uint8List bufferAsBytes; // full bytes view for bytes copy

  int get lengthMax => bufferAsBytes.lengthInBytes;

  Uint8List get viewAsBytes => bufferAsBytes.buffer.asUint8List(0, viewLength); // holds truncated view, mutable length.

  @protected
  int viewLength = 0;

  @override
  int get length => viewLength;
  @override
  bool get isEmpty => viewLength == 0;
  @override
  bool get isNotEmpty => !isEmpty;

  @override
  void clear() => viewLength = 0;

  /// start at offset, or 0
  // throw if dataIn.length > lengthMax
  // a buffer backing larger than all potential calls is expected to be allocated at initialization
  // does not need length checking of Uint8List.copy
  void copy(Uint8List bytes, [int offset = 0]) {
    bufferAsBytes.setAll(offset, bytes);
    viewLength = bytes.length + offset;
  }

  /// start at current length
  @override
  void add(covariant Uint8List bytes) {
    bufferAsBytes.setAll(viewLength, bytes);
    viewLength += bytes.length;
  }

  @override
  void addByte(int byte) => bufferAsBytes[viewLength++] = byte;

  /// return must be processed before next add
  @override
  Uint8List takeBytes() {
    final result = bufferAsBytes.buffer.asUint8List(0, viewLength);
    clear();
    return result;
  }

  @override
  Uint8List toBytes() => bufferAsBytes.sublist(0);
}

// alternative implementation for fragmented trailing buffer
// disallow changing dataView as pointer directly, caller use length
// int get viewLength => dataView.lengthInBytes;
// @protected
// set viewLength(int value) {
//   // runtime assertion is handled by parser
//   assert(value <= lengthMax); // minus offset if view does not start at buffer 0, case of inheritance
//   dataView = _byteBuffer.asUint8List(0, value);
//   // _bytesView = _byteBuffer.asUint8List(0, value); // need Uint8List.view. sublistView will not exceed current length
// }

typedef TypedDataCaster<T> = T Function(TypedData typedData);
