part of 'packet.dart';

/// [PacketId] — one row of a protocol's id table.
///
/// The id table is the protocol's vocabulary: which byte means which exchange, what shape
/// that exchange's payloads take, and which id answers which. A [PacketCodec] owns the frame
/// around a payload; the id owns the payload.
///
/// Kept as `interface` rather than `sealed` deliberately. A `sealed` supertype cannot be
/// implemented outside its own library, and every protocol declares its ids in its own
/// library, so sealing here would make the package unusable. Exhaustiveness is recovered a
/// different way — see [PacketCodec.isSyncShape], which asks the one question framing
/// actually depends on instead of switching over subtypes.
///
/// `implements Enum` because an id is a named constant: it gives `name` for diagnostics and
/// makes an id table a plain `enum` declaration. Note that this is load-bearing — an enum
/// does *not* satisfy a hand-declared `String get name`, only the `EnumName` extension that
/// `implements Enum` brings, so every id must be an enum value.
abstract interface class PacketId implements Enum {
  int get intId;
}

/// An id carried by the short control frame: no length field, no payload.
///
/// Ack, nack and abort are the universal members. A protocol may put more here — MotProtocol
/// frames its several PING ids this way — so membership is about the *frame shape*, not about
/// whether the id means "control".
abstract interface class PacketSyncId implements PacketId {}

/// An id that carries a payload, together with the codec for it.
///
/// One id, one payload type, one codec — which is the unit that actually exists on the wire.
/// A one-way command is exactly this and nothing more: it can be built and sent, and the
/// type says no answer is coming.
abstract interface class PacketPayloadId<V> implements PacketId {
  PayloadCaster<V> get caster;
}

/// A payload id that expects an answer: the byte it arrives under, and the codec that reads
/// it.
///
/// **Two non-nullable members, not three nullable ones.** The original model had `responseId`,
/// `requestCaster` and `responseCaster` all nullable, and put the nullability on the wrong
/// axis: `responseId` was null for "the answer comes back under the same byte", which is the
/// common case, while the response *codec* differs even then — so it was carried separately
/// and unwrapped with `!` at every call site.
///
/// The fix is that both casters are required and [responseId] defaults to the request's own
/// byte in the constructor. Same byte, different codec — the common case — is then the short
/// form, and a different byte is one extra argument. Nothing is nullable, so nothing is
/// unwrapped.
///
/// [responseId] is an `int` rather than a [PacketPayloadId] deliberately. Modelling the answer
/// as its own id also removes the nullability, but it forces a second id table: [PacketId]
/// implements [Enum], so every id must be an enum value, and an exchange then spans two rows
/// in two enums. Nothing downstream needs the answer to *be* an id — routing wants the byte,
/// and decoding wants the caster — so carrying both directly keeps one row per exchange.
///
/// One-way is expressed by *not* being a [PacketRequestId]. The type, rather than a null,
/// carries whether an answer is expected.
abstract interface class PacketRequestId<T, R> implements PacketPayloadId<T> {
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
final class PacketIdMap {
  PacketIdMap(Iterable<Iterable<PacketId>> idSets)
    : _byIntId = Map<int, PacketId>.unmodifiable({
        for (final idSet in idSets)
          for (final id in idSet) id.intId: id,
      });

  final Map<int, PacketId> _byIntId;

  PacketId? call(int intId) => _byIntId[intId];

  Iterable<PacketId> get ids => _byIntId.values;
}

/// [Payload] — a view over the payload bytes of a packet that can convert to and from `V`.
///
/// Built in place on the packet's own buffer, so neither direction allocates a second copy.
/// An implementation is typically an `ffi.Struct` with named fields, cast over the payload.
///
/// ## What a payload may depend on
///
/// Its own bytes, and the header of the frame carrying them. Not the request that provoked
/// it.
///
/// Two mechanisms were in play. The previous Dart module threaded a `PayloadMeta` from the
/// request into the response's `parse`, so a reply could be decoded using what the request
/// had recorded. The device side instead hands a handler the metadata of the frame it is
/// decoding — `Packet_Xfer_T.p_RxMeta`. Only the second survives here.
///
/// The empirical reason: across every `Payload` implementation in the Mot table, the
/// request-state parameter is accepted and never read. Not once. It was a channel with no
/// traffic, and the responses that look like they need it — a variable-length read — get
/// their count from the payload region's own length instead.
///
/// The design reason is that the two are not alternatives; they answer different questions,
/// and only one is a question a decoder should be asking. Giving a decoder the header of
/// *its own* frame is the standard arrangement: Kaitai Struct exposes `_parent` and `_root`
/// to a substructure, Construct threads a parse context down into nested subconstructs, and
/// HTTP/2 implementations decode a frame body against the type and flags from that frame's
/// header. A body governed by fields in its own header is ordinary.
///
/// Threading values from a *different* frame is the unusual one. RPC frameworks — gRPC,
/// Thrift, Cap'n Proto — take the response *type* from the request, which this design does
/// too through [PacketRequestId.responseId], but decode the response's contents from the
/// response alone. A decoder that needs the request to make sense of the reply stops working
/// the moment a frame is retransmitted, arrives out of order, or is read back from a log.
///
/// [build] is handed a header too, cleared and stamped with the delimiter and id, and states
/// its size on it. That replaces returning a one-field `PayloadMeta` and makes the two
/// directions speak one type — the device handler's `p_RxMeta` / `p_TxMeta` pair, reached
/// differently: it extracts wire fields into a normalized struct because C has to, while this
/// is a view over the frame's own bytes.
abstract interface class Payload<V> {
  /// Write `values` into this payload, and return what the framing needs to describe it.
  ///
  /// **Deliberately not symmetric with [parse].** The two directions do not carry the same
  /// information, and pretending they do costs correctness:
  ///
  /// On parse a header exists, full of values a body may be governed by. On build there is no
  /// header yet — its fields come from two places, the id table and this payload — so a
  /// payload does not *read* a header, it *contributes to* one. Handing it a live header to
  /// write into means the header must be stamped before the payload runs, which is what makes
  /// a half-built frame possible; and it hands a payload write access to `idField`,
  /// `startField` and `checksumField`, none of which are its to set. Returning what it decided
  /// lets the framing write the header once, afterwards, from a payload that cannot corrupt
  /// it.
  ///
  /// The device agrees once `p_TxMeta` is read for what it is: not a view of the frame but a
  /// normalized staging struct that `BUILD_TX_FRAME` serializes afterwards. A handler there
  /// also reports metadata for the framing to place — by writing a struct rather than
  /// returning one. The symmetry on that side is between two staging structs, not between a
  /// struct and a live frame.
  @pragma('vm:prefer-inline')
  PayloadMeta build(V values);

  /// Read this payload as `V`, against the header of the frame carrying it.
  ///
  /// Most implementations ignore it: the payload region a [PayloadCaster] is handed is bounded
  /// exactly, so a variable-length body already knows its own extent without asking. It is
  /// there for a body governed by its own header — an id distinguishing which of several
  /// shapes a shared handler is seeing, a flags field.
  @pragma('vm:prefer-inline')
  V parse(covariant PacketHeader header);
}

/// What a payload decided, for the framing to write.
///
/// Normalized, the counterpart of [PacketHeader]'s mapped fields: [length] is payload bytes,
/// so a payload states its size without knowing how long a header is or whether the wire
/// counts one. [PacketFrameFormat.buildHeader] performs that conversion, in one place.
///
/// A one-field carrier today. It stays a named type because it is the channel by which a
/// payload tells the framing anything at all — a flags word or a sequence would arrive the
/// same way, and arriving here rather than through a live header is what keeps the ordering
/// sound.
final class PayloadMeta {
  const PayloadMeta(this.length);

  /// Payload bytes. Excludes the header.
  final int length;

  static const PayloadMeta empty = PayloadMeta(0);

  @override
  String toString() => 'PayloadMeta(length: $length)';
}

/// [Payload] constructor, over a view of the payload region.
typedef PayloadCaster<V> = Payload<V> Function(TypedData payload);
