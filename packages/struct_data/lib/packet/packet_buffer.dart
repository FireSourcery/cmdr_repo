import 'dart:typed_data';

import 'packet.dart';

export 'packet.dart';

/// [PacketBuffer] — a fixed allocation that *is* the frame it currently holds.
///
/// Mixes in [Packet], so there is one object rather than a buffer plus two views of it. The
/// previous version exposed `buffered` (the whole allocation, to write through) and `packet`
/// (what was valid, to read), and every caller had to pick. Here [lengthInBytes] is the end,
/// and building simply opens it: while a request is being assembled the whole allocation is
/// the frame, and the end is brought in once the payload reports its size.
///
/// [byteData] is bounded by that end rather than spanning the allocation, so an accessor
/// cannot read past what is valid — a header field that has not arrived reads as out of
/// range rather than as stale bytes from the frame before.
///
/// Replaces `PacketBuffer extends ByteStructBuffer<T extends Packet>`. `ByteStructBuffer`
/// existed to carry a `TypedDataCaster<T>` so a generic buffer could produce a protocol's own
/// `Packet` subclass; with no subclass to produce there is no caster to carry, and the
/// intermediate class had no other member and no other user.
base class PacketBuffer(@override final PacketCodec codec, [int? size]) extends TypedDataBuffer with Packet {
  this : super(size ?? codec.lengthMax);

  /// Bounded by [lengthInBytes], not by the allocation.
  ///
  /// So an accessor cannot read past what is valid: a header field that has not arrived
  /// reads as out of range rather than as stale bytes from the frame before. Building does
  /// not go through here — see [bufferAsByteData].
  @override
  ByteData get byteData => ByteData.sublistView(viewLengthBytes);

  @override
  int get lengthInBytes => viewLength;

  /// The whole allocation, unbounded by the current end.
  ///
  /// A frame being built has no length until its payload declares one, and a fixed-size
  /// `ffi.Struct` payload must be cast over its full extent whatever the frame's length. Both
  /// want the allocation rather than the view.
  @override
  ByteData get storage => ByteData.sublistView(fullLengthBytes);

  /// A detached view of what is valid now.
  ///
  /// Handed out instead of `this` so a listener receives a frame rather than the buffer that
  /// assembled it, and cannot drive it.
  Packet get view => PacketView.of(codec, viewLengthBytes);

  /// Payload bytes currently valid. Setting it moves the end.
  set payloadLength(int value) => viewLength = codec.dataFormat.headerLength + value;

  ///
  /// [Build]
  ///
  /// Writing goes through [storage], so nothing here opens the view. The end moves in
  /// [buildHeader] — a frame's extent is not known until its header is written, and that is
  /// where it becomes known.
  ///

  /// Also brings the end in to the frame the header describes.
  @override
  void buildHeader(PacketId id, [PayloadMeta meta = PayloadMeta.empty]) {
    // An `assert`, not a throw: a payload's size comes from its own struct, so this is a table
    // error rather than anything the link can produce. A payload that actually overruns is
    // stopped by the bounds check on its own write into the span it was handed — this catches
    // only one *declaring* a length it did not write.
    assert(meta.length <= codec.payloadLengthMax, 'declared payload exceeds the frame');

    super.buildHeader(id, meta);
    viewLength = codec.formatOf(id).frameLengthOf(meta.length);
  }

  /// Stages nothing if the payload throws.
  ///
  /// The end has not moved, so the buffer still claims the frame staged before — but that
  /// frame's body may have just been written over by the payload that threw, leaving a
  /// valid-looking header on contents that no longer match it.
  @override
  PayloadMeta buildRequest<T, R>(PacketRequestId<T, R> id, T values) {
    try {
      return super.buildRequest(id, values);
    } on Object {
      clear();
      rethrow;
    }
  }

  /// A bare control frame.
  void buildControl(PacketId id) => buildHeader(id);

  @override
  String toString() => toDebugString();
}
