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
  factory Packet(PacketCodec codec, ByteData byteData) = PacketView;

  /// A detached view over [data].
  factory Packet.of(PacketCodec codec, TypedData data) = PacketView.of;

  PacketCodec get codec;

  /// The frame's bytes. May be a window on a longer allocation — see [lengthInBytes].
  ByteData get byteData;

  /// Bytes of [byteData] that are this frame. Named for [TypedData] rather than `length`,
  /// which read as though it were the length *field*.
  int get lengthInBytes => byteData.lengthInBytes;

  Uint8List get bytes => Uint8List.sublistView(byteData, 0, lengthInBytes);

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

  int get payloadOffset => format.length;
  int get payloadLength => lengthInBytes - payloadOffset;
  int get payloadLengthMax => codec.payloadLengthMax;

  Uint8List get headerBytes => Uint8List.sublistView(byteData, 0, format.length);

  /// This frame's header fields, by name — the view a [Payload] is handed in both
  /// directions, and the one place a custom [PacketFrameFormat.headerCaster] takes effect.
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

  /// The id this frame declares. Null when the codec's table does not define it — a lookup
  /// miss on bytes that did arrive, not a frame still arriving.
  PacketId? get packetId => codec.idOf(idField);

  /// [packetId] when it is a control id, else null.
  PacketSyncId? get syncId => switch (packetId) {
    final PacketSyncId id => id,
    _ => null,
  };

  bool get isSyncShape => switch (packetId) {
    final PacketId id => codec.isSyncShape(id),
    null => false,
  };

  /// The shape this frame is framed as. An id the table does not define has no declared
  /// shape, so it falls back to the data shape, which is the general one.
  PacketFrameFormat get format => switch (packetId) {
    final PacketId id => codec.formatOf(id),
    null => codec.dataFormat,
  };

  /// Present in every shape.
  int get startField => codec.startField.getWord(byteData, codec.endian);
  int get idField => codec.idField.getWord(byteData, codec.endian);

  /// Total frame length as carried on the wire. Reports the shape's own fixed length where it
  /// declares no length field, so this answers for every shape — [frameLength] is the same
  /// number under the name the framing uses.
  int get lengthField => header.lengthField;

  /// The integrity field this shape declares, or 0 where it declares none.
  int get checksumField => header.checksumField;

  int get frameLength => header.lengthField;

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

  /// Read this frame's payload as [id] declares it.
  ///
  /// Takes the id rather than a caster: the id carries its own codec now, so there is one
  /// way in instead of a caster-taking method plus an id-taking wrapper around it.
  V parsePayload<V>(PacketPayloadId<V> id) => _parseAs<V>(id.caster);

  /// Read this frame as the answer to [id] — the same call, through the request's other codec.
  R parseResponse<T, R>(PacketRequestId<T, R> id) => _parseAs<R>(id.responseCaster);

  V _parseAs<V>(PayloadCaster<V> caster) => caster(Uint8List.sublistView(storage, format.length)).parse(header);

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
  /// Writes as far as this view reaches. `PacketBuffer` overrides it to open the view first,
  /// because a frame's length is not decided until its payload declares one.
  PayloadMeta buildPayload<V>(PacketPayloadId<V> id, V values) {
    final PacketFrameFormat shape = codec.formatOf(id);
    final PayloadMeta meta = id.caster(Uint8List.sublistView(storage, shape.length)).build(values);
    shape.buildHeader(storage, id, meta.length);
    return meta;
  }

  /// Build [id]'s request. The same work as [buildPayload], named and typed for the caller
  /// that expects an answer — a [PacketRequestId] carries the response id that will decode it.
  PayloadMeta buildRequest<T, R>(PacketRequestId<T, R> id, T values) => buildPayload<T>(id, values);

  /// Reads defensively, unlike the accessors above: `toString` must not throw, and it is
  /// wanted most on a frame that is malformed or short.
  String toDebugString() {
    int? field(ByteField? key) => key?.getWordOrNull(byteData, codec.endian);

    final int? id = field(codec.idField);
    final String idText = (id == null) ? 'none' : (codec.idOf(id)?.toStringAsHex() ?? '0x${id.toRadixString(16)}');
    final PacketFrameFormat shape = (id == null) ? codec.dataFormat : format;
    final Object body = (lengthInBytes > shape.length) ? Uint8List.sublistView(byteData, shape.length, lengthInBytes) : const <int>[];
    return '[start: ${field(codec.startField)}, id: $idText, length: ${field(shape.lengthField)}, checksum: ${field(shape.checksumField)}]$body';
  }
}

/// A detached [Packet] over a frame that is exactly its own bytes.
///
/// What the parser hands out: a listener gets a frame, not the buffer that assembled it.
final class PacketView with Packet {
  PacketView(this.codec, this.byteData);

  PacketView.of(this.codec, TypedData data) : byteData = ByteData.sublistView(data);

  @override
  final PacketCodec codec;

  @override
  final ByteData byteData;

  @override
  String toString() => toDebugString();
}
