part of 'packet.dart';

/// [PacketCodec] — the wire format of one protocol, as const data.
///
/// Successor to `PacketFormat`. Three things changed.
///
/// **No factory members.** `PacketFormat<T extends Packet>` required `cast`, `caster`,
/// `headerOf` and `syncHeaderOf` so that generic code could manufacture a protocol's own
/// `Packet` subclass. [Packet] is now a mixin over `(codec, byteData)`, so a protocol
/// contributes data and nothing else — no subclass, no casters. `MotPacketInterface` +
/// `MotPacket` + `MotPacketHeader` + `MotPacketHeaderSync` collapse into one `const`
/// subclass of this and two [PacketFrameFormat]s.
///
/// **One description of each layout.** `PacketFormat` described the header twice — once as
/// [ByteField] offsets and once as an `ffi.Struct` — and nothing kept the two in step. The
/// descriptors are the survivor: they are the only half that can read a *partial* buffer,
/// which is the parser's whole job. An `ffi.Struct` cast throws below full length.
///
/// **Endian is honoured.** Header fields were read through `ByteField.getInOrNull`, which
/// hardcodes little-endian and never consulted `PacketFormat.endian`. Every access here
/// passes [endian] explicitly.
///
/// `base`, so a protocol must `extend` and inherits the derived members below rather than
/// reimplementing them.
abstract base class PacketCodec {
  const PacketCodec();

  /// A complete frame is never longer than this. Sizes every buffer.
  int get lengthMax;

  /// The frame shapes. [dataFormat] carries a payload; [syncFormat] is the bare control
  /// frame. A protocol with more shapes adds them and overrides [formatOf].
  PacketFrameFormat get dataFormat;
  PacketFrameFormat get syncFormat;

  /// Control ids. Framed with [syncFormat].
  PacketSyncId get ack;
  PacketSyncId get nack;
  PacketSyncId get abort;

  /// The id table. Null for a byte this protocol does not define.
  PacketId? idOf(int intId);

  /// The shape [id] is framed with.
  PacketFrameFormat formatOf(PacketId id);

  // Packet cast(TypedData data); //   Packet constructor for user Packet subtype overrides.

  /// Whether [id] is framed with the control shape.
  ///
  /// This replaces switching over the [PacketId] subtype hierarchy, which could not be
  /// exhaustive — ids are declared in each protocol's own library, so the root cannot be
  /// `sealed`. Framing has exactly two answers and this asks for one of them.
  bool isSyncShape(PacketId id) => identical(formatOf(id), syncFormat);

  ///
  /// [Shape-independent] — what the parser can use before the shape is known
  ///

  int get startId => dataFormat.startId;
  Endian get endian => dataFormat.endian;
  ByteField get startField => dataFormat.startField;
  ByteField get idField => dataFormat.idField;

  /// The parser reads the delimiter and the id to *choose* a format, so it cannot use a
  /// format to find them. Every shape must therefore agree on all four. Asserted where a
  /// parser is built rather than enforced here, because the formats are `const` and this is
  /// a property of the pair.
  bool get hasConsistentIdPrefix =>
      dataFormat.startId == syncFormat.startId &&
      dataFormat.endian == syncFormat.endian &&
      dataFormat.startField.offset == syncFormat.startField.offset &&
      dataFormat.startField.size == syncFormat.startField.size &&
      dataFormat.idField.offset == syncFormat.idField.offset &&
      dataFormat.idField.size == syncFormat.idField.size;

  ///
  /// [Derived]
  ///

  int get headerLength => dataFormat.length;
  int get syncHeaderLength => syncFormat.length;

  /// Largest payload a data frame can carry.
  int get payloadLengthMax => lengthMax - headerLength;
}

/// [PacketFrameFormat] — one frame shape: where its header fields lie, how long the header
/// is, and how its integrity is computed.
///
/// A protocol has more than one shape. MotProtocol has two, and they disagree about more
/// than length: the data header is 8 bytes with a 16-bit sum at offset 4, the control frame
/// is 4 bytes with a 1-byte XOR at offset 3. A single set of four descriptors on the codec
/// could describe only one of them, which is why the previous version could neither write
/// nor check a control frame's check byte — the data checksum field lies past the end of a
/// control frame entirely.
///
/// `base`, so a shape whose integrity is not a byte sum extends it and overrides
/// [checksumOf]. That is the seam rather than a pluggable `int Function(Uint8List)`: a CRC
/// is not decomposable over the two spans either side of the field.
base class PacketFrameFormat {
  const PacketFrameFormat({
    required this.length,
    required this.startId,
    required this.startField,
    required this.idField,
    this.lengthField,
    this.checksumField,
    this.endian = Endian.little,
    this.headerCaster,
  });

  /// Header bytes. For a data shape the payload begins here; for a control shape this is the
  /// whole frame.
  final int length;

  /// Frame delimiter, written at [startField].
  final int startId;

  /// Byte order of every multi-byte field.
  ///
  /// On the shape rather than on the codec so that a format is self-contained: [buildHeader]
  /// and [checksumOf] then need no context passed in, which is what lets an override be
  /// written against the shape alone. [PacketCodec] derives its own from [dataFormat].
  final Endian endian;

  /// Present in every shape. The parser reads these before it knows which shape it has, so
  /// every format of one codec must place them identically — see
  /// [PacketCodec.hasConsistentIdPrefix].
  final ByteField startField;
  final ByteField idField;

  /// Total frame length as carried on the wire — header plus payload, matching the device
  /// codec. Null for a shape that fixes its own length, which is what a control frame does.
  final ByteField? lengthField;

  /// Null for a shape that carries no integrity field.
  final ByteField? checksumField;

  /// Produces the [PacketHeader] view this shape is read and written through.
  ///
  /// Null uses the descriptors above. A protocol supplies one to read and write its header
  /// as a struct with named fields instead — the `castHeader` route. Because build and parse
  /// both go through the view, swapping it swaps *both* directions at once, without
  /// overriding any of the logic around it.
  ///
  /// The one invariant: a caster must describe the same layout as the descriptors. The
  /// descriptors stay authoritative for framing, because the parser reads fields out of a
  /// buffer that is still filling and a struct cast throws below full length.
  final PacketHeaderCaster? headerCaster;

  bool get hasLength => lengthField != null;
  bool get hasChecksum => checksumField != null;

  /// Total frame length for [payloadLength] bytes of body. A shape with no length field
  /// carries no payload.
  int frameLengthOf(int payloadLength) => hasLength ? length + payloadLength : length;

  /// Checksum over the first [lengthInBytes] of [frame], excluding the checksum field's own
  /// bytes, masked to that field's width.
  ///
  /// The default sums the two spans either side of the field. Only call it on a shape with
  /// [hasChecksum].
  int checksumOf(ByteData frame, int lengthInBytes) {
    final ByteField key = checksumField!;
    final int mask = (1 << (key.size * 8)) - 1;
    return (_sum(Uint8List.sublistView(frame, 0, key.offset)) + _sum(Uint8List.sublistView(frame, key.end, lengthInBytes))) & mask;
  }

  static int _sum(Uint8List bytes) => bytes.sum;

  ///
  /// [Build]
  ///

  /// The header of [frame], by name.
  PacketHeader headerOf(ByteData frame) => headerCaster?.call(frame) ?? _FormatHeader(this, frame);

  /// Write [id]'s header over a body of [payloadLength] bytes.
  ///
  /// One pass, after the payload has run — the payload reports its size and the framing
  /// converts. The normalized number a payload speaks becomes the wire's total here, and
  /// nowhere else, which is the same conversion `BUILD_TX_FRAME` performs on the device.
  ///
  /// The header is cleared first, so reserved bytes — a sequence counter, an option byte —
  /// never carry whatever the previous frame left there. Checksum last: it covers the length.
  void buildHeader(ByteData frame, PacketId id, [int payloadLength = 0]) {
    for (int i = 0; i < length; i++) {
      frame.setUint8(i, 0);
    }

    final PacketHeader header = headerOf(frame)
      ..startField = startId
      ..idField = id.intId
      ..lengthField = frameLengthOf(payloadLength);

    if (hasChecksum) header.checksumField = checksumOf(frame, header.lengthField);
  }

  @override
  String toString() => 'PacketFrameFormat(length: $length)';
}

/// [PacketHeader] — a frame's header fields, by name, whatever layout holds them.
///
/// **Mapped fields are read/write; the one derived reading is read-only.** `startField`
/// through `checksumField` each sit at an offset and move bytes. [payloadLength] is the
/// wire's total less this header — a normalized reading of a mapped field, which is what
/// `Packet_Meta_T.Length` holds on the device. It has no setter because writing it is the
/// framing's job, through [PacketFrameFormat.frameLengthOf], in one place.
///
/// Dart virtualises with getters, so this is a view over the frame's own bytes and nothing is
/// copied — unlike the device, which has to extract into a struct.
///
/// Handed to [Payload.parse], which reads a header that exists. [Payload.build] is not given
/// one: see there for why the two directions are deliberately not symmetric.
///
/// One type covers every shape rather than a union per shape. A field a shape does not
/// carry reads as its neutral value and ignores writes: [lengthField] reports the shape's
/// own fixed length, [checksumField] reports 0. So a control frame answers the same
/// questions a data frame does, without a caller testing which it has.
abstract interface class PacketHeaderPrefix {
  /// The delimiter and the id sit at the same offset in every shape of one codec — the
  /// parser reads them to choose a shape, so it cannot use a shape to find them.
  int get startField;
  set startField(int value);

  int get idField;
  set idField(int value);
}

abstract interface class PacketHeader implements PacketHeaderPrefix {
  /// Total frame length as carried on the wire. Reports the shape's fixed length, and
  /// ignores writes, where the shape declares no length field.
  int get lengthField;
  set lengthField(int value);

  /// Reports 0, and ignores writes, where the shape declares no checksum.
  int get checksumField;
  set checksumField(int value);

  /// Payload bytes this frame declares. Derived, so read-only.
  ///
  /// **This is how a [Payload] knows how much of its region is real.** The region a
  /// [PayloadCaster] is built over is the whole space available, not the frame's own payload,
  /// because an `ffi.Struct` payload with a fixed `Array` cannot be cast over anything shorter
  /// than itself — `Struct.create` throws below full length. So the span is deliberately
  /// over-long and this is the count that bounds it.
  int get payloadLength;
}

/// Produces a [PacketHeader] over a frame. Held by [PacketFrameFormat.headerCaster].
typedef PacketHeaderCaster = PacketHeader Function(ByteData frame);

/// The default [PacketHeader]: the format's own descriptors, read and written in place.
final class _FormatHeader implements PacketHeader {
  const _FormatHeader(this._format, this._frame);

  final PacketFrameFormat _format;
  final ByteData _frame;

  @override
  int get startField => _format.startField.getWord(_frame, _format.endian);
  @override
  set startField(int value) => _format.startField.setWord(_frame, value, _format.endian);

  @override
  int get idField => _format.idField.getWord(_frame, _format.endian);
  @override
  set idField(int value) => _format.idField.setWord(_frame, value, _format.endian);

  @override
  int get lengthField => _format.lengthField?.getWord(_frame, _format.endian) ?? _format.length;
  @override
  set lengthField(int value) => _format.lengthField?.setWord(_frame, value, _format.endian);

  @override
  int get checksumField => _format.checksumField?.getWord(_frame, _format.endian) ?? 0;
  @override
  set checksumField(int value) => _format.checksumField?.setWord(_frame, value, _format.endian);

  @override
  int get payloadLength => lengthField - _format.length;

  @override
  String toString() => '[start: $startField, id: $idField, length: $lengthField, checksum: $checksumField]';
}
