import 'dart:async';
import 'dart:typed_data';

import 'packet_buffer.dart';

export 'packet_buffer.dart';

/// [HeaderParser] — the receive buffer, and the state of a [PacketTransformer].
///
/// Framing only. Whether a frame's *contents* make sense is the caller's question; this
/// decides where one frame ends and the next begins.
///
/// **This is the only thing that ever sees a partial frame**, so the three-state reading of
/// a header — absent / present-and-wrong / present-and-right — lives here rather than on
/// [Packet]. A [Packet] is a view of a whole frame and reads its fields without a null; the
/// nulls below mean "these bytes have not arrived yet", which is a statement about a buffer
/// filling up, not about a packet.
///
/// That is also why these read through the codec's field descriptors instead of casting a
/// struct over the buffer: a struct cast throws below full length, and below full length is
/// exactly where this operates.
///
/// Always copies the remainder rather than shifting a view over it. That double-buffers, and
/// it is the deliberate trade the previous version made too: the alternative is tracking a
/// start offset through every field read, and the buffer is a few hundred bytes.
final class HeaderParser extends PacketBuffer {
  HeaderParser(PacketCodec codec, [int? size]) : super(codec, size ?? codec.lengthMax * 4) {
    assert(codec.hasConsistentIdPrefix, 'every shape must place start and id identically — the parser reads them to choose a shape');
  }

  /// Bytes past the end of the frame just completed — the next frame, in whole or in part.
  late Uint8List trailing = Uint8List.sublistView(viewAsBytes);

  ///
  /// [Header] — what has arrived
  ///
  /// These are read from [byteData], which [PacketBuffer] bounds by what is valid, so a
  /// field that has not arrived reads as null rather than as stale bytes.
  ///

  int? _fieldOrNull(ByteField? key) => key?.getWordOrNull(byteData, codec.endian);

  /// The shape being assembled, once the id says which. Null before that.
  PacketFrameFormat? get formatOrNull => switch (idOrNull) {
    final PacketId id => codec.formatOf(id),
    null => null,
  };

  int? get startFieldOrNull => _fieldOrNull(codec.startField);
  int? get idFieldOrNull => _fieldOrNull(codec.idField);
  int? get lengthFieldOrNull => _fieldOrNull(formatOrNull?.lengthField);
  int? get checksumFieldOrNull => _fieldOrNull(formatOrNull?.checksumField);

  /// The id in the buffer. Null if it has not arrived, or is not in the table.
  PacketId? get idOrNull => switch (idFieldOrNull) {
    final int intId => codec.idOf(intId),
    null => null,
  };

  /// Total length of the frame being assembled — from the shape where it fixes its own
  /// length, from the length field otherwise. Null until enough has arrived to say.
  int? get frameLengthOrNull => switch (formatOrNull) {
    final PacketFrameFormat shape when !shape.hasLength => shape.length,
    final PacketFrameFormat _ => lengthFieldOrNull,
    null => null,
  };

  /// Whether the whole declared frame is in the buffer.
  bool get isComplete => switch (frameLengthOrNull) {
    final int frameLength => length >= frameLength,
    null => false,
  };

  ///
  /// [Header] — field validity
  ///
  /// `null` not yet arrived, `false` arrived and wrong, `true` arrived and right.
  ///

  bool? get isStartFieldValid => switch (startFieldOrNull) {
    final int value => value == codec.startId,
    null => null,
  };

  bool? get isIdFieldValid => switch (idFieldOrNull) {
    final int value => codec.idOf(value) != null,
    null => null,
  };

  /// Against the total frame length the codec admits.
  bool? get isLengthFieldValid => switch (lengthFieldOrNull) {
    final int value => value >= codec.headerLength && value <= codec.lengthMax,
    null => null,
  };

  /// Meaningful only after [completePacket] — the checksum covers exactly the frame, so the
  /// view has to end where the frame does. Null on a shape that declares no checksum, which
  /// is now asked of the frame's own shape: a control frame is checked against its own check
  /// byte instead of being waved through because the data shape's field lay past its end.
  bool? get isChecksumFieldValid => switch (checksumFieldOrNull) {
    final int value => value == formatOrNull!.checksumOf(byteData, length),
    null => null,
  };

  /// Take [bytes] from the link. Seeks the delimiter only when starting fresh; mid-frame,
  /// a delimiter byte is payload.
  void receive(Uint8List bytes) {
    if (isEmpty) {
      if (bytes.seekChar(codec.startId) case final Uint8List found) copy(found);
    } else {
      add(bytes);
    }
  }

  /// Drop everything before the next delimiter, or all of it if there is none.
  void seekStart() {
    if (viewAsBytes.seekChar(codec.startId) case final Uint8List found) {
      copy(found);
    } else {
      clear();
    }
  }

  /// Re-seat the buffer on whatever followed the frame just consumed.
  void seekTrailing() => copy(trailing);

  /// Split the buffer at the end of the completed frame.
  ///
  /// Must run before the checksum is read: the checksum covers exactly the frame, so the
  /// view has to end where the frame does and not where the last read from the link did.
  void completePacket() {
    final int frameLength = frameLengthOrNull!;
    trailing = Uint8List.sublistView(viewAsBytes, frameLength);
    viewLength = frameLength;
  }
}

/// [PacketTransformer] — a byte stream into a frame stream.
///
/// The emitted [Packet] is a **view of the parser's buffer, not a copy**. A listener must
/// finish with it before yielding control, or copy it. This is what lets a frame reach an
/// application without allocating per packet, and it is why the output sink is driven
/// synchronously.
class PacketTransformer extends StreamTransformerBase<Uint8List, Packet> implements EventSink<Uint8List> {
  PacketTransformer({required this.parser});

  final HeaderParser parser;

  late final EventSink<Packet> _outputSink;

  @override
  void add(Uint8List bytesIn) {
    parser.receive(bytesIn);

    // A read may carry more than one frame, or a fraction of one.
    //
    // The scrutinee is the parser, not a packet: every arm below is a question about how much
    // has arrived, and the answers move as frames are split off. Patterns re-read the getters
    // per arm, so the switch always sees the current buffer.
    while (parser.isNotEmpty) {
      // Recovery resynchronises and carries on within the same read.
      //
      // Terminates: `meta` empties the buffer, and `checksum` is only reachable after
      // `completePacket` has split off a whole frame, so `seekTrailing` always shortens it.
      try {
        switch (parser) {
          // Not on a frame boundary — resynchronise.
          case HeaderParser(isStartFieldValid: false):
            parser.seekStart();

          // Framed, but the id is not ours. Nothing can size this frame, so the buffer is
          // unrecoverable rather than merely misaligned.
          case HeaderParser(isIdFieldValid: false):
            throw PacketStatusException.meta;

          case HeaderParser(isComplete: true):
            assert(parser.isStartFieldValid != false);
            assert(parser.isIdFieldValid != false);
            parser.completePacket(); // bound the view before reading the checksum
            switch (parser.isChecksumFieldValid) {
              case true || null: // null when this frame shape carries no checksum
                _outputSink.add(parser.view); // detached: a listener gets a frame, not the buffer
                parser.seekTrailing();
              case false:
                throw PacketStatusException.checksum;
            }

          // A length field naming a frame the codec cannot hold. Checked after completeness
          // so that back-to-back control frames, which carry no length, are not measured.
          case HeaderParser(isLengthFieldValid: false):
            throw PacketStatusException.meta;

          // Recognised and still arriving.
          case HeaderParser(isComplete: false):
            assert(parser.length < parser.codec.lengthMax, 'a frame over lengthMax should have failed isLengthFieldValid');
            return;
        }
      } on PacketStatusException catch (e) {
        switch (e) {
          case PacketStatusException.meta:
            parser.clear(); // nothing here can be resynchronised against
          case PacketStatusException.checksum:
            parser.seekTrailing(); // the frame was well formed; the next one may be fine
        }
        _outputSink.addError(e);
      }
    }
  }

  @override
  void addError(Object e, [StackTrace? st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();

  EventSink<Uint8List> _mapSink(EventSink<Packet> sink) => this.._outputSink = sink;

  @override
  Stream<Packet> bind(Stream<Uint8List> stream) => Stream<Packet>.eventTransformed(stream, _mapSink);
}

extension PacketCodecTransformer on PacketCodec {
  PacketTransformer get transformer => PacketTransformer(parser: HeaderParser(this));
}

sealed class PacketStatus {}

enum PacketStatusOk implements PacketStatus { ok }

enum PacketStatusException implements PacketStatus, Exception { meta, checksum }
