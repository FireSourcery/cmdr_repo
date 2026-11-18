part of 'packet.dart';

/// [PacketCodec] — the wire format of one protocol, as const data.
///
/// A protocol contributes data and nothing else: its frame shapes as [PacketFrameFormat]s and
/// its id table through [idOf] and [formatOf], with no [Packet] subclass and no casters. Every
/// descriptor access passes the shape's [PacketFrameFormat.endian].
///
/// `base`, so a protocol must `extend` and inherits the derived members below rather than
/// reimplementing them.
///
/// The frame diagrams, and what changed from `PacketFormat`: `doc/packet_design.md` in this package.
abstract base class const PacketCodec() {
  /// A complete frame is never longer than this. Sizes every buffer.
  int get lengthMax;

  /// Frame delimiter. Protocol-wide rather than a shape's: the parser seeks it knowing
  /// nothing else about the frame.
  int get startId;

  /// The frame shapes. [dataFormat] carries a payload; [controlFormat] is the bare control
  /// frame. A protocol with more shapes adds them and overrides [formatOf].
  PacketFrameFormat get dataFormat;
  PacketFrameFormat get controlFormat;

  /// Control ids. Framed with [controlFormat].
  PacketControlId get ack;
  PacketControlId get nack;
  PacketControlId get abort;

  /// The id table. Null for a byte this protocol does not define.
  PacketId? idOf(int intId);

  /// The shape [id] is framed with.
  PacketFrameFormat formatOf(PacketId id);

  // Packet cast(TypedData data); //   Packet constructor for user Packet subtype overrides.

  /// Bytes that must have arrived before [prefixOf] can be read — the device's `LENGTH_MIN`.
  ///
  /// The default spans as far as the data shape's length field, which is what the default
  /// [prefixOf] reads. A protocol whose prefix is a struct states that struct's size.
  int get prefixLength => dataFormat.lengthField?.end ?? dataFormat.idField.end;

  /// A frame's delimiter, id and total length, read before it is known which shape the frame
  /// is.
  ///
  /// This is the codec's, not a shape's, because it is what *chooses* a shape: the parser
  /// reads an id here and only then knows which [PacketFrameFormat] the rest of the frame
  /// follows. So every shape of the codec places its delimiter and id where this reads them;
  /// the default reads them through [dataFormat]'s descriptors.
  ///
  /// Only valid once [prefixLength] bytes are present.
  ///
  /// The default resolves the shape from the id and then reads that shape's descriptors,
  /// which tolerate a partial buffer. It has to resolve the shape: a control frame declares
  /// its length by *being* one, so a prefix that only knew the data shape would read its
  /// length out of whatever byte the data shape puts there.
  ///
  /// **A protocol whose [PacketFrameFormat.headerOf] is a struct should override this** with a
  /// struct sized to [prefixLength] — `Struct.create` throws below its own length, and this is
  /// read while the buffer is still filling.
  PacketHeaderPrefix prefixOf(ByteData frame) => _CodecPrefix(this, frame);

  /// Largest payload a data frame can carry. A budget, not a layout: the buffer's capacity
  /// less the data shape's header, which is the codec's arithmetic and not a shape's.
  int get payloadLengthMax => lengthMax - dataFormat.headerLength;
}

/// [PacketFrameFormat] — one frame shape: where its header fields lie, how long the header is,
/// how its integrity is computed, and how it is read as named fields.
///
/// A protocol has more than one shape, so the descriptors live on the shape, not the codec.
///
/// **A configuration interface with shared derivations.** A `mixin class`, so a shape is a
/// named `const` class that states the few members it differs on and inherits the rest.
/// [lengthField] and [checksumField] default to absent, so a control shape names neither.
///
/// [headerOf] and [checksumOf] are the two members a shape overrides with behaviour rather
/// than data — the first to read and write its header as a struct with named fields instead of
/// through the descriptors, the second where its integrity is not a byte sum.
///
/// Why a shape is data, and what changed from `PacketFormat`: `doc/packet_design.md` in this package.
abstract mixin class PacketFrameFormat() {
  /// Header bytes. For a data shape the payload begins here; for a control shape this is the
  /// whole frame.
  int get headerLength;

  /// Byte order of every multi-byte field. On the shape rather than on the codec so a format
  /// is self-contained — [checksumOf] and the header view need no context passed in.
  Endian get endian => Endian.little;

  /// Present in every shape. The parser reads these before it knows which shape it has, so
  /// every format of one codec must place them where [PacketCodec.prefixOf] reads them.
  ByteField get startField;
  ByteField get idField;

  /// Total frame length as carried on the wire — header plus payload, matching the device
  /// codec. Absent on a shape that fixes its own length, which is what a control frame does.
  ByteField? get lengthField => null;

  /// Absent on a shape that carries no integrity field.
  ByteField? get checksumField => null;

  bool get hasLength => lengthField != null;
  bool get hasChecksum => checksumField != null;

  /// Total frame length for [payloadLength] bytes of body. A shape with no length field
  /// carries no payload.
  int frameLengthOf(int payloadLength) => hasLength ? headerLength + payloadLength : headerLength;

  /// This shape's header over [frame], by name.
  ///
  /// The default reads and writes through the descriptors above, which is also the only thing
  /// that works on a partial buffer. A shape whose header is an `ffi.Struct` overrides this —
  /// and because build and parse both go through it, overriding swaps both directions at once.
  ///
  /// The one invariant: an override must describe the same layout as the descriptors, which
  /// stay authoritative for framing.
  PacketHeader headerOf(ByteData frame) => _FormatHeader(this, frame);

  /// Checksum over the first [lengthInBytes] of [frame], excluding the checksum field's own
  /// bytes, masked to that field's width.
  ///
  /// The default sums the two spans either side of the field. That is valid for a byte sum and
  /// not for a CRC — `crc(a) + crc(b) != crc(a + b)` — which is why the hook is the whole
  /// checksum rather than a pluggable reduction. Only called on a shape with [hasChecksum].
  int checksumOf(ByteData frame, int lengthInBytes) {
    final ByteField key = checksumField!;
    final int mask = (1 << (key.size * 8)) - 1;
    return (_sumBytes(Uint8List.sublistView(frame, 0, key.offset)) + _sumBytes(Uint8List.sublistView(frame, key.end, lengthInBytes))) & mask;
  }

  static int _sumBytes(Uint8List bytes) => bytes.sum;
}

/// **Getters map onto bytes; methods compute.** `startField` and `idField` each sit at an
/// offset and move bytes. [frameLength] and [payloadLength] are derived — from a length field
/// where the shape carries one, from the shape itself where it does not — and are written as
/// methods so the difference is visible at the call site rather than only in the docs. Neither
/// has a setter: writing a length is the framing's job, through
/// [PacketFrameFormat.frameLengthOf], in one place.
///
/// **This is the minimum that determines how long a frame is** — which is what the parser
/// needs and all it needs, and what [Payload.parse] is handed. Everything past it is a
/// particular shape's business: see [PacketHeader].
///
/// Dart virtualises with getters, so this is a view over the frame's own bytes and nothing is
/// copied — unlike the device, which extracts into a `Packet_Meta_T` because C must.
abstract interface class PacketHeaderPrefix() {
  /// The delimiter and the id sit at the same offset in every shape of one codec — the
  /// parser reads them to choose a shape, so it cannot use a shape to find them.
  int get startField;
  set startField(int value);

  int get idField;
  set idField(int value);

  /// Total bytes of this frame, or null where the shape does not fix it and a length field
  /// must be read. Answering null is how a prefix says "variable".
  int? frameLength();

  /// Payload bytes, on the same terms as [frameLength].
  int? payloadLength();
}

/// A full header: the prefix, plus the fields a data shape carries.
///
/// One type covers every shape rather than a union per shape. A field a shape does not carry
/// reads as its neutral value and ignores writes — [lengthField] reports the shape's own fixed
/// length, [checksumField] reports 0 — so a control frame answers the same questions a data
/// frame does, without a caller testing which it has.
abstract interface class PacketHeader() implements PacketHeaderPrefix {
  /// Total frame length as carried on the wire. Reports the shape's fixed length, and
  /// ignores writes, where the shape declares no length field.
  int get lengthField;
  set lengthField(int value);

  /// Reports 0, and ignores writes, where the shape declares no checksum.
  int get checksumField;
  set checksumField(int value);

  /// Never null here: a full header carries the length field a prefix may have to defer to.
  @override
  int frameLength();

  @override
  int payloadLength();
}

/// The default [PacketCodec.prefixOf]: the delimiter and id from the shape-independent
/// positions, and the frame length from whichever shape the id turns out to name.
///
/// Descriptor-driven throughout, because this is read while the buffer is still filling and a
/// struct cast throws below its own length.
final class const _CodecPrefix(final PacketCodec _codec, final ByteData _frame) implements PacketHeaderPrefix {
  /// Every shape places the delimiter and the id identically, so the data shape answers for
  /// where they are. Which shape the *rest* of the frame follows is [_shape].
  PacketFrameFormat get _prefix => _codec.dataFormat;

  PacketFrameFormat get _shape {
    final PacketId? id = _codec.idOf(idField);
    return (id == null) ? _codec.dataFormat : _codec.formatOf(id);
  }

  @override
  int get startField => _prefix.startField.getWord(_frame, _prefix.endian);
  @override
  set startField(int value) => _prefix.startField.setWord(_frame, value, _prefix.endian);

  @override
  int get idField => _prefix.idField.getWord(_frame, _prefix.endian);
  @override
  set idField(int value) => _prefix.idField.setWord(_frame, value, _prefix.endian);

  /// Null on a shape that carries a length field — reading that field is the caller's, once
  /// it holds the resolved [PacketFrameFormat].
  @override
  int? frameLength() => _shape.hasLength ? null : _shape.headerLength;

  @override
  int? payloadLength() => _shape.hasLength ? null : 0;

  @override
  String toString() => '[start: $startField, id: $idField, frame: ${frameLength()}]';
}

/// The default [PacketHeader]: the format's own descriptors, read and written in place.
final class const _FormatHeader(final PacketFrameFormat _format, final ByteData _frame) implements PacketHeader {
  @override
  int get startField => _format.startField.getWord(_frame, _format.endian);
  @override
  set startField(int value) => _format.startField.setWord(_frame, value, _format.endian);

  @override
  int get idField => _format.idField.getWord(_frame, _format.endian);
  @override
  set idField(int value) => _format.idField.setWord(_frame, value, _format.endian);

  @override
  int get lengthField => _format.lengthField?.getWord(_frame, _format.endian) ?? _format.headerLength;
  @override
  set lengthField(int value) => _format.lengthField?.setWord(_frame, value, _format.endian);

  @override
  int get checksumField => _format.checksumField?.getWord(_frame, _format.endian) ?? 0;
  @override
  set checksumField(int value) => _format.checksumField?.setWord(_frame, value, _format.endian);

  @override
  int frameLength() => lengthField;

  @override
  int payloadLength() => lengthField - _format.headerLength;

  @override
  String toString() => '[start: $startField, id: $idField, length: $lengthField, checksum: $checksumField]';
}
