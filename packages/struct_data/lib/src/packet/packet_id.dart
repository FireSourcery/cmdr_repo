part of 'packet.dart';

/// [PacketId] — one row of a protocol's id table.
///
/// The id table is the protocol's vocabulary: which byte means which exchange, what shape
/// that exchange's payloads take, and which id answers which. A [PacketCodec] owns the frame
/// around a payload; the id owns the payload.
///
/// Kept as `interface` rather than `sealed` deliberately. A `sealed` supertype cannot be
/// implemented outside its own library, and every protocol declares its ids in its own
/// library, so sealing here would make the package unusable. Framing does not need
/// exhaustiveness anyway: it asks one question, and [PacketControlId] answers it by type.
///
/// `implements Enum` because an id is a named constant: it gives `name` for diagnostics and
/// makes an id table a plain `enum` declaration. Note that this is load-bearing — an enum
/// does *not* satisfy a hand-declared `String get name`, only the `EnumName` extension that
/// `implements Enum` brings, so every id must be an enum value.
abstract interface class PacketId() implements Enum {
  int get intId;
}

/// An id carried by the short control frame: no length field, no payload.
///
/// Ack, nack and abort are the universal members, and a protocol may add more — MotProtocol
/// frames its several PING ids this way. Membership is by *frame shape*, which is what the
/// framing acts on. Why it is not `PacketSyncId`: `doc/packet_design.md` in this package.
abstract interface class PacketControlId() implements PacketId {}

/// An id that carries a payload, together with the codec for it.
///
/// One id, one payload type, one codec — which is the unit that actually exists on the wire.
/// A one-way command is exactly this and nothing more: it can be built and sent, and the
/// type says no answer is coming.
abstract interface class PacketPayloadId<V>() implements PacketId {
  PayloadCaster<V> get caster;
}

/// A payload id that expects an answer: the byte it arrives under, and the codec that reads
/// it.
///
/// Both casters are required and [responseId] defaults to the request's own byte in the
/// constructor, so the common case — same byte, different codec — is the short form. One-way
/// is expressed by *not* being a [PacketRequestId]: the type, rather than a null, carries
/// whether an answer is expected.
///
/// Why two non-nullable members, and why [responseId] is an `int` rather than a
/// [PacketPayloadId]: `doc/packet_design.md` in this package.
abstract interface class PacketRequestId<T, R>() implements PacketPayloadId<T> {
  /// The byte the answer arrives under. Defaults to this id's own.
  int get responseId;

  /// The codec that reads the answer. Distinct from [caster], which reads the request.
  PayloadCaster<R> get responseCaster;
}

extension PacketIdString on PacketId {
  String toStringAsHex() => '$name(0x${intId.toRadixString(16).toUpperCase().padLeft(2, '0')})';
}

/// intId -> [PacketId], for [PacketCodec.idOf].
///
/// A protocol may instead keep its own `static final` map, which is what MotProtocol does.
/// This exists so one does not have to.
///
/// Lists the ids a codec must recognise on arrival. A response is not a separate id — it is
/// a byte and a codec on its request's row — so there is nothing here to collide with it.
final class PacketIdMap(Iterable<Iterable<PacketId>> idSets) {
  this
    : _byIntId = Map<int, PacketId>.unmodifiable({
        for (final idSet in idSets)
          for (final id in idSet) id.intId: id,
      });

  final Map<int, PacketId> _byIntId;

  PacketId? call(int intId) => _byIntId[intId];

  Iterable<PacketId> get ids => _byIntId.values;
}

/// [Payload] constructor, over a view of the payload region.
typedef PayloadCaster<V> = Payload<V> Function(TypedData payload);

/// [Payload] — a view over the payload bytes of a packet that can convert to and from `V`.
///
/// Built in place on the packet's own buffer, so neither direction allocates a second copy.
/// An implementation is typically an `ffi.Struct` with named fields, cast over the payload.
///
/// What a payload may depend on, and why: `lib/src/packet/packet_payload.md` in this package.
abstract interface class Payload<V>() {
  /// Write `values` into this payload, and return what the framing needs to describe it.
  ///
  /// **Deliberately not symmetric with [parse].** On build there is no header yet: a payload
  /// contributes its length, and the framing writes the header once, afterwards, so a payload
  /// never sets `idField`, `startField` or `checksumField`. Why, and the device's
  /// `p_TxMeta`: `doc/packet_design.md` in this package.
  @pragma('vm:prefer-inline')
  PayloadMeta build(V values);

  /// Read this payload as `V`, against the header of the frame carrying it.
  ///
  /// A full [PacketHeader], not a [PacketHeaderPrefix]: a payload is only ever handed a whole
  /// frame, and only a whole header answers [PacketHeaderPrefix.payloadLength] without a null.
  ///
  /// The region a [PayloadCaster] is handed runs to the end of [Packet.storage], which on a
  /// `PacketBuffer` is the whole allocation, so a variable-length body bounds itself by
  /// [PacketHeader.payloadLength]; a fixed-size body ignores the header. A body governed by its
  /// own header reads it too — an id distinguishing which of several shapes a shared handler is
  /// seeing, a flags field.
  @pragma('vm:prefer-inline')
  V parse(covariant PacketHeader header);
}

/// What a payload told the framing: how long its body is.
///
/// A value, not a view — the build side's counterpart to [PacketHeaderPrefix], deliberately
/// *not* the same type: the two directions do not carry the same information. See
/// [Payload.build].
///
/// A field rather than a method, for the same reason the prefix's is a method: this one is
/// stored, that one is computed.
class const PayloadMeta(
  /// Payload bytes. Excludes the header.
  final int length,
) {
  static const PayloadMeta empty = PayloadMeta(0);

  @override
  String toString() => 'PayloadMeta(length: $length)';
}
