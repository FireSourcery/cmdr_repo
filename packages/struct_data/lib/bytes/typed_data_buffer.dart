import 'dart:typed_data';

import 'package:meta/meta.dart';

/// [TypedDataBuffer] - `BytesBuilderBuffer`
/// effectively, a fixed size [BytesBuilder] - allocated with a persistent buffer
class TypedDataBuffer implements BytesBuilder {
  TypedDataBuffer.origin(this.byteBuffer) : fullLengthBytes = byteBuffer.asUint8List(0);

  TypedDataBuffer.of(this.fullLengthBytes) : byteBuffer = fullLengthBytes.buffer;

  TypedDataBuffer(int size) : this.of(Uint8List(size));

  final ByteBuffer byteBuffer;

  @protected
  final Uint8List fullLengthBytes; // full bytes view for bytes copy.

  @protected
  int viewLength = 0; // the `extension` to TypeData that would allow shifting the view length in place. maintaing the state between operations.

  Uint8List get viewLengthBytes => fullLengthBytes.buffer.asUint8List(0, viewLength); // holds truncated view, mutable length.

  int get lengthMax => fullLengthBytes.lengthInBytes;

  @override
  int get length => viewLength;
  @override
  bool get isEmpty => viewLength == 0;
  @override
  bool get isNotEmpty => !isEmpty;

  @override
  void clear() => viewLength = 0;

  /// start at offset, or 0
  // throws if dataIn.length > lengthMax
  // a buffer backing larger than all potential calls is expected to be allocated at initialization
  // does not need length checking of Uint8List.copy
  void copy(Uint8List bytes, [int offset = 0]) {
    fullLengthBytes.setAll(offset, bytes);
    viewLength = bytes.length + offset;
  }

  /// start at current length
  @override
  void add(covariant Uint8List bytes) {
    fullLengthBytes.setAll(viewLength, bytes);
    viewLength += bytes.length;
  }

  @override
  void addByte(int byte) => fullLengthBytes[viewLength++] = byte;

  /// return must be processed before next add
  @override
  Uint8List takeBytes() {
    final result = fullLengthBytes.buffer.asUint8List(0, viewLength);
    clear();
    return result;
  }

  @override
  Uint8List toBytes() => fullLengthBytes.sublist(0);
}
