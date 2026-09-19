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
base class PacketBuffer extends TypedDataBuffer with Packet {
  PacketBuffer(this.codec, [int? size]) : super(size ?? codec.lengthMax);

  @override
  final PacketCodec codec;

  /// Bounded by [lengthInBytes], not by the allocation.
  ///
  /// So an accessor cannot read past what is valid: a header field that has not arrived
  /// reads as out of range rather than as stale bytes from the frame before. Building does
  /// not go through here — see [bufferAsByteData].
  @override
  ByteData get byteData => ByteData.sublistView(viewAsBytes);

  @override
  int get lengthInBytes => viewLength;

  /// The whole allocation, unbounded by the current end.
  ///
  /// A frame being built has no length until its payload declares one, and a fixed-size
  /// `ffi.Struct` payload must be cast over its full extent whatever the frame's length. Both
  /// want the allocation rather than the view.
  @override
  ByteData get storage => ByteData.sublistView(bufferAsBytes);

  /// A detached view of what is valid now.
  ///
  /// Handed out instead of `this` so a listener receives a frame rather than the buffer that
  /// assembled it, and cannot drive it.
  Packet get view => PacketView.of(codec, viewAsBytes);

  /// Payload bytes currently valid. Setting it moves the end.
  set payloadLength(int value) => viewLength = codec.headerLength + value;

  ///
  /// [Build]
  ///
  /// Writes through [bufferAsByteData] and moves the end only once the frame is whole, so
  /// there is no window in which the view describes a half-built frame. The previous version
  /// opened the view to `lengthMax` for the duration of the build and had to restore it on
  /// every exit.
  ///

  /// Build, then bring the end in to the frame.
  ///
  /// No view to open: building goes through [storage], so the end only ever moves once, to
  /// the finished frame.
  @override
  PayloadMeta buildPayload<V>(PacketPayloadId<V> id, V values) {
    try {
      final PayloadMeta meta = super.buildPayload(id, values);

      // An `assert`, not a throw: a payload's size comes from its own struct, so this is a
      // table error rather than anything the link can produce. A payload that actually
      // overruns is stopped by the bounds check on its own write into the span it was handed
      // — this catches only one *declaring* a length it did not write.
      assert(meta.length <= codec.payloadLengthMax, 'declared payload exceeds the frame');

      viewLength = codec.formatOf(id).frameLengthOf(meta.length);
      return meta;
    } on Object {
      // The end has not moved, so the buffer still claims the frame staged before — but that
      // frame's body may have just been written over by the payload that threw, leaving a
      // valid-looking header on contents that no longer match it. Clearing is what keeps that
      // visible: nothing is staged, rather than something that still looks like a frame.
      clear();
      rethrow;
    }
  }

  /// Build a bare control frame and bring the end in to it.
  void buildSync(PacketId id) {
    final PacketFrameFormat format = codec.formatOf(id);
    format.buildHeader(storage, id);
    viewLength = format.length;
  }

  @override
  String toString() => toDebugString();
}
