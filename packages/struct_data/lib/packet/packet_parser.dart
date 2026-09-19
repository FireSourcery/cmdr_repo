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
    // Every shape must be at least as long as what it takes to size one, or a whole frame of
    // that shape could arrive and still not be readable.
    assert(codec.prefixLength <= codec.controlFormat.headerLength && codec.prefixLength <= codec.dataFormat.headerLength);
  }

  /// Bytes past the end of the frame just completed — the next frame, in whole or in part.
  late Uint8List trailing = Uint8List.sublistView(viewLengthBytes);

  ///
  /// [Header] — what has arrived
  ///
  /// These are read from [byteData], which [PacketBuffer] bounds by what is valid, so a
  /// field that has not arrived reads as null rather than as stale bytes.
  ///

  /// The delimiter, id and frame length, once enough has arrived to read them.
  ///
  /// One view, from the codec — the parser reads an id here in order to *choose* a shape, so
  /// it cannot reach through a shape to find one.
  PacketHeaderPrefix? get prefixOrNull => (length >= codec.prefixLength) ? codec.prefixOf(byteData) : null;

  /// The id in the buffer. Null if it has not arrived, or is not in the table.
  PacketId? get idOrNull => switch (idFieldOrNull) {
    final int intId => codec.idOf(intId),
    null => null,
  };

  /// The shape being assembled, once the id says which. Null before that.
  PacketFrameFormat? get formatOrNull => switch (idOrNull) {
    // final PacketControlId id => codec.controlFormat,
    // final PacketPayloadId id => codec.dataFormat,
    final PacketId id => codec.formatOf(id),
    null => null,
  };

  /// Total length of the frame being assembled.
  ///
  /// The prefix answers for a shape that fixes its own length; null from it means variable,
  /// and then the shape's length field is what says.
  int? get frameLengthOrNull => prefixOrNull?.frameLength() ?? lengthFieldOrNull;

  /// The frame length the prefix declares, against what the codec can hold.
  ///
  /// Asked of [frameLengthOrNull] rather than of a length field, so it answers for a control
  /// shape — which declares its length by being one — as well as for a data frame.
  bool? get isFrameLengthValid => switch (frameLengthOrNull) {
    final int frameLength => frameLength >= codec.prefixLength && frameLength <= codec.lengthMax,
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

  int? get startFieldOrNull => prefixOrNull?.startField;
  int? get idFieldOrNull => prefixOrNull?.idField;

  /// The length field of the shape being assembled. Resolves only once the id has named a
  /// shape, so a control frame is measured against its own format and never the data one.
  int? get lengthFieldOrNull => switch (formatOrNull) {
    final PacketFrameFormat shape => shape.lengthField?.getWordOrNull(byteData, shape.endian),
    null => null,
  };

  /// The integrity field the assembling shape declares, if it has arrived.
  int? get checksumFieldOrNull => switch (formatOrNull) {
    final PacketFrameFormat shape => shape.checksumField?.getWordOrNull(byteData, shape.endian),
    null => null,
  };

  bool? get isStartFieldValid => switch (startFieldOrNull) {
    final int value => value == codec.startId,
    null => null,
  };

  bool? get isIdFieldValid => switch (idFieldOrNull) {
    final int value => codec.idOf(value) != null,
    null => null,
  };

  bool? get isLengthFieldValid => switch (lengthFieldOrNull) {
    final int value => value >= codec.prefixLength && value <= codec.lengthMax,
    null => null,
  };

  /// Meaningful only after [completePacket] — the checksum covers exactly the frame, so the
  /// view has to end where the frame does. Null on a shape that declares no checksum, which
  /// is asked of the frame's own shape: a control frame is checked against its own check byte
  /// instead of being waved through because the data shape's field lay past its end.
  bool? get isChecksumFieldValid => switch ((formatOrNull, checksumFieldOrNull)) {
    (final PacketFrameFormat shape, final int carried) => carried == shape.checksumOf(byteData, length),
    _ => null,
  };

  /// for valueOrNull from header status
  // bool isValidStart(int value) => (value == format.startId);
  // bool isValidId(int value) => (format.idOf(value) != null);
  // bool isValidLength(int value) => (value == value.clamp(format.headerLength, format.lengthMax)); // where length is total length
  // bool isValidChecksum(int value) => (value == checksum());
  // int? get startFieldOrNull => format.startFieldDef.getInOrNull(packetData);
  // int? get idFieldOrNull => format.idFieldDef.getInOrNull(packetData);
  // int? get lengthFieldOrNull => format.lengthFieldDef.getInOrNull(packetData);
  // int? get checksumFieldOrNull => format.checksumFieldDef.getInOrNull(packetData);
  // bool? get isStartFieldValid => startFieldOrNull.ifNonNull(isValidStart);
  // bool? get isIdFieldValid => idFieldOrNull.ifNonNull(isValidId);
  // bool? get isLengthFieldValid => lengthFieldOrNull.ifNonNull(isValidLength);
  // bool? get isChecksumFieldValid => checksumFieldOrNull.ifNonNull(isValidChecksum); // assert(length == lengthFieldOrNull), isPacketComplete == true

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
    if (viewLengthBytes.seekChar(codec.startId) case final Uint8List found) {
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
    trailing = Uint8List.sublistView(viewLengthBytes, frameLength);
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
          case HeaderParser(isFrameLengthValid: false):
            throw PacketStatusException.meta;

          // Recognised and still arriving.
          case HeaderParser(isComplete: false):
            assert(parser.length < parser.codec.lengthMax, 'a frame over lengthMax should have failed isFrameLengthValid');
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
