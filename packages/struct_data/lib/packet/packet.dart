import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../bytes/byte_struct.dart';

export '../bytes/byte_struct.dart';

/// [Packet], [PacketCodec] and [Payload] are mutually recursive — a codec frames a packet, a
/// packet resolves its id through the codec, a payload is built against a packet. One library
/// in parts, rather than three importing each other in a cycle.
part 'packet_codec.dart';
part 'packet_id.dart';

/// [Packet] — everything a frame can answer, over `(codec, byteData)`.
///
/// A `mixin class`, so the two things that hold frame bytes both *are* packets rather than
/// containing one: [PacketView] for a detached frame, and `PacketBuffer` for a frame being
/// filled. The buffer previously exposed a `buffered` view for writing and a `packet` view
/// for reading, and every caller had to know which it wanted; mixing this in means
/// `buffer.payloadAsList()` and `buffer.parseResponse(...)` say what they mean.
///
/// Implementors supply two members. [byteData] is the frame's bytes and [lengthInBytes] is
/// how many of them are this frame — a buffer overrides the latter, because its backing
/// allocation outlives any one frame.
///
/// A view or buffer, so a packet handed to a  callback is valid only until that buffer is next written.
/// That is what lets a frame reach an application with no copy.
///
/// Fields are read without a null in sight. A *partly arrived* frame is not a packet; it is
/// a `HeaderParser`'s buffer, and the three-state reading it needs —
/// absent / present-and-wrong / present-and-right — lives there.
abstract mixin class Packet {
  /// A detached view over [byteData].
  factory(PacketCodec codec, ByteData byteData) = PacketView;

  /// A detached view over [data].
  factory of(PacketCodec codec, TypedData data) = PacketView.of;

  PacketCodec get codec;

  /// The frame's bytes. May be a window on a longer allocation — see [lengthInBytes].
  ByteData get byteData;

  /// Bytes of [byteData] that are this frame. Named for [TypedData] rather than `length`,
  /// which read as though it were the length *field*.
  int get lengthInBytes => byteData.lengthInBytes;

  Uint8List get bytes => Uint8List.sublistView(byteData, 0, lengthInBytes);

  /// The id this frame declares. Null when the codec's table does not define it — a lookup
  /// miss on bytes that did arrive, not a frame still arriving.
  PacketId? get packetId => codec.idOf(idField);

  /// [packetId] when it is a control id, else null.
  PacketControlId? get controlId => switch (packetId) {
    final PacketControlId? id => id,
    _ => null,
  };

  bool get isControlShape => packetId is PacketControlId;

  /// The shape this frame is framed as. An id the table does not define has no declared
  /// shape, so it falls back to the data shape, which is the general one.
  PacketFrameFormat get format => switch (packetId) {
    final PacketId id => codec.formatOf(id),
    null => codec.dataFormat,
  };

  ///
  /// [Header] / [Payload] regions
  ///
  /// Payload accessors describe a data frame. A control frame has no payload, and asking one
  /// The offset comes from this frame's own [format], so a shape with a shorter header puts
  /// its payload where that header ends. It could not, while building went through a packet:
  /// a payload is written before the id is, so an offset read from the buffer's own contents
  /// was circular. Building now goes through `PacketBuffer` and the whole allocation, taking
  /// the offset from the id being built, which leaves this side free to ask the frame.
  ///
  /// A control shape's header is the whole frame, so its payload is empty rather than an
  /// error.
  ///

  int get payloadOffset => format.headerLength;
  int get payloadLength => lengthInBytes - payloadOffset;
  int get payloadLengthMax => codec.payloadLengthMax;

  Uint8List get headerBytes => Uint8List.sublistView(byteData, 0, format.headerLength);

  /// This frame's header fields, by name — the view a [Payload] is handed in both
  /// directions, and the one place a shape's [PacketFrameFormat.headerOf] takes effect.
  PacketHeader get header => format.headerOf(byteData);
  Uint8List get payload => Uint8List.sublistView(byteData, payloadOffset, lengthInBytes);

  /// Payload as a list of `R`'s element width, bounds-checked by [ByteBuffer].
  /// `length` counts **elements**, not bytes.
  R payloadAt<R extends TypedDataList<int>>([int byteOffset = 0, int? length]) => byteData.arrayAt<R>(byteOffset + payloadOffset, length);

  R? payloadAtOrNull<R extends TypedDataList<int>>([int byteOffset = 0, int? length]) => byteData.arrayOrNullAt<R>(byteOffset + payloadOffset, length);

  /// The whole payload, as elements of `R`.
  ///
  /// Every call site of [payloadAt] in the Mot payload table spelled this out as
  /// `payloadAt<Uint16List>(0, parsePayloadLength ~/ 2)` — the divisor restating a width the
  /// type argument already carries.
  R payloadAsList<R extends TypedDataList<int>>() => payloadAt<R>(0, payloadLength ~/ bytesPerElementOf<R>());

  ///
  /// [Header] — shape and fields
  ///

  /// Present in every shape.
  int get startField => codec.prefixOf(byteData).startField;
  int get idField => codec.prefixOf(byteData).idField;

  /// Total frame length as carried on the wire. Reports the shape's own fixed length where it
  /// declares no length field, so this answers for every shape — [frameLength] is the same
  /// number under the name the framing uses.
  int get lengthField => header.lengthField;

  /// The integrity field this shape declares, or 0 where it declares none.
  int get checksumField => header.checksumField;

  int get frameLength => header.frameLength();

  /// Checksum over this frame, for comparison against [checksumField].
  int checksum([int? lengthInBytes]) => format.checksumOf(byteData, lengthInBytes ?? this.lengthInBytes);

  /// Whether the checksum this frame carries matches its contents.
  ///
  /// True for a shape that declares no checksum: there is nothing to contradict.
  bool get isChecksumValid => !format.hasChecksum || checksumField == checksum();

  ///
  /// [Payload] — parse
  ///
  /// Read-only. Building belongs to `PacketBuffer`, which writes through the whole
  /// allocation: a frame's length is not decided until its payload reports one, so a build
  /// cannot be bounded by [lengthInBytes] while it is still computing it.
  ///

  /// alias for [header], provided for consistency with the parse methods.
  PacketHeader parseHeader() => header;

  /// Read this frame's payload as [id] declares it.
  ///
  /// Takes the id rather than a caster: the id carries its own codec now, so there is one
  /// way in instead of a caster-taking method plus an id-taking wrapper around it.
  V parsePayload<V>(PacketPayloadId<V> id) => _parseAs<V>(id.caster);

  /// Read this frame as the answer to [id] — the same call, through the request's other codec.
  R parseResponse<T, R>(PacketRequestId<T, R> id) => _parseAs<R>(id.responseCaster);

  V _parseAs<V>(PayloadCaster<V> caster) => caster(Uint8List.sublistView(storage, format.headerLength)).parse(header);

  /// The bytes a frame may be built in or cast over — its own view by default.
  ///
  /// Distinct from [byteData], which is bounded by what is *valid*. `PacketBuffer` widens this
  /// to its whole allocation, for two reasons that pull the same way: a frame being built has
  /// no length until its payload declares one, and an `ffi.Struct` payload with a fixed
  /// `Array` cannot be cast over a region shorter than itself. So a payload codec is given the
  /// full span and told the real count through [PacketHeader.payloadLength].
  ///
  /// Reading past [lengthInBytes] through here is reading whatever the previous frame left.
  ByteData get storage => byteData;

  /// Build [id]'s payload and header into this frame, and return the header written.
  ///
  /// Takes a [PacketPayloadId], not a [PacketRequestId]: building is the same work whether an
  /// answer is expected, and a one-way command is built through here too. A [PacketRequestId]
  /// *is* a payload id, so a request needs no separate method.
  ///
  /// The body alone — [buildHeader] is the other half, [buildRequest] is both.
  ///
  /// Split so either half can be overridden on its own: the region a payload is handed and
  /// the header written over it are independent decisions, and a [Packet] that wants to place
  /// one differently should not have to restate the other.
  PayloadMeta buildPayload<V>(PacketPayloadId<V> id, V values) => id.caster(Uint8List.sublistView(storage, codec.formatOf(id).headerLength)).build(values);

  /// Write [id]'s header over the body [meta] describes.
  ///
  /// Constructing a frame belongs to the frame, not to the format — [PacketFrameFormat] says
  /// what a shape *is*, and this is the one place that acts on it. One pass, after the payload
  /// has run: the payload reports its size and this converts, which is the same division
  /// `BUILD_TX_FRAME` draws on the device.
  ///
  /// The header is cleared first, so reserved bytes — a sequence counter, an option byte —
  /// never carry whatever the previous frame left there. Checksum last: it covers the length.
  void buildHeader(PacketId id, [PayloadMeta meta = PayloadMeta.empty]) {
    final PacketFrameFormat shape = codec.formatOf(id);
    final ByteData frame = storage;

    for (int i = 0; i < shape.headerLength; i++) {
      frame.setUint8(i, 0);
    }

    final PacketHeader written = shape.headerOf(frame)
      ..startField = codec.startId
      ..idField = id.intId
      ..lengthField = shape.frameLengthOf(meta.length);

    if (shape.hasChecksum) written.checksumField = shape.checksumOf(frame, written.frameLength());
  }

  /// A whole frame: [buildPayload], then the [buildHeader] describing what it wrote.
  ///
  /// In that order because the header carries a length only the payload knows.
  PayloadMeta buildRequest<T, R>(PacketRequestId<T, R> id, T values) {
    final PayloadMeta meta = buildPayload<T>(id, values);
    buildHeader(id, meta);
    return meta;
  }

  /// Reads defensively, unlike the accessors above: `toString` must not throw, and it is
  /// wanted most on a frame that is malformed or short.
  String toDebugString() {
    // Guarded, not asked through `prefixOf`: that is only valid past `prefixLength`, and a
    // short frame is exactly when this is wanted.
    final PacketHeaderPrefix? prefix = (lengthInBytes >= codec.prefixLength) ? codec.prefixOf(byteData) : null;
    final int? id = prefix?.idField;
    final String idText = (id == null) ? 'none' : (codec.idOf(id)?.toStringAsHex() ?? '0x${id.toRadixString(16)}');
    final PacketFrameFormat shape = (id == null) ? codec.dataFormat : format;
    int? field(ByteField? key) => key?.getWordOrNull(byteData, shape.endian);
    final Object body = (lengthInBytes > shape.headerLength) ? Uint8List.sublistView(byteData, shape.headerLength, lengthInBytes) : const <int>[];
    return '[start: ${prefix?.startField}, id: $idText, length: ${field(shape.lengthField)}, checksum: ${field(shape.checksumField)}]$body';
  }
}

/// A detached [Packet] over a frame that is exactly its own bytes.
///
/// What the parser hands out: a listener gets a frame, not the buffer that assembled it.
final class PacketView(final PacketCodec codec, final ByteData byteData) with Packet {
  PacketView.of(PacketCodec codec, TypedData data) : this(codec, ByteData.sublistView(data));

  @override
  String toString() => toDebugString();
}
