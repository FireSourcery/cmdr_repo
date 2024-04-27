import 'package:meta/meta.dart';

import 'packet.dart';

/// alternative to with HeaderHandler implements HeaderHandler
// abstract interface class HeaderParser implements Packet {
// }

// abstract mixin class HeaderHandler implements HeaderParser {
// }

/// PacketRxHeaderParser
/// Header as Packet Control Block
/// Packet Meta Parser
/// handled by base module. different format use new class
/// implemented with shared Sync Header by default
///
abstract mixin class HeaderHandler implements Packet {
  // PacketId? idOf(int intId); // factory constructor of enum id, returns
  PacketSyncId get nack;
  PacketSyncId get abort;
  PacketSyncId get ack;
  // final Set<PacketId> syncIds = {ack, nack, abort };
  // PacketId? get packetId => (idFieldOrNull != null) ? idOf(idFieldOrNull!) : null;

  // todo note buffer may be larger than configMax
  HeaderHandler castBuffer(Uint8List bytes) => (castBytes(bytes) as HeaderHandler);

  HeaderStatus parseHeader() {
    return switch (packetIdOrNull) {
      null => HeaderStatus(this),
      PacketSyncId() => SyncHeaderStatus(this),
      PacketTypeId() => PayloadHeaderStatus(this),
      PacketId() => HeaderStatus(this),
    };
  }

  // trim leading
  void seekValidStart() {
    final offset = bytes.indexWhere((element) => element == configStartField);
    castBytes(Uint8List.sublistView(bytes, (offset == -1) ? bytes.length : offset));
  }

  // trim trailing
  // call only after packet is complete to truncate view
  // (HeaderHandler packet, Uint8List trailing) effectively returns pointers to (packetStart, packetEnd/trailingStart, trailingEnd)
  void completePacket() {
    assert(parseHeader().isCompletePacket ?? false);
    length = switch (packetId) {
      PacketSyncId() => idField.end,
      PacketTypeId() => lengthFieldValue,
      PacketId() => lengthFieldValue,
    };
  }

  // after complete has been called
  PacketId get validPacketId {
    assert(parseHeader().isCompletePacket ?? false);
    return idOf(idFieldValue)!;
  }

  // builder must be different instance from parser
  // build common header
  // void buildHeader(PacketId id, [int? requestLength]) {
  //   switch (id) {
  //     case PacketSyncId():
  //       buildSync(id);
  //     case PacketTypeId():
  //       buildPayloadHeader(id, requestLength);
  //     //  case PacketId() : null,
  //   }
  // }

  // void buildSync(PacketSyncId syncId) {
  //   fillStartField();
  //   idFieldValue = syncId.asInt;
  //   length = idField.end;
  // }

  // void buildPayloadHeader(PacketTypeId requestId, [int? requestLength]) {
  //   fillStartField();
  //   idFieldValue = requestId.asInt;
  //   lengthFieldValue = requestLength ?? length;
  //   checksumFieldValue = checksum();
  // }
}

/// determine complete, error, or wait
// ParseLength
// ParseId
// ParseChecksum
interface class HeaderStatus {
  HeaderStatus(this.view);
  HeaderStatus.of(this.view);
  @protected
  final HeaderHandler view;

  // PacketId? get packetId => (view.idFieldOrNull != null) ? view.idOf(view.idFieldOrNull!) : null;
  @mustBeOverridden
  bool? get isCompletePacket => null;
  // bool? get isPacketComplete => (view.lengthFieldOrNull != null) ? (view.length >= view.lengthFieldOrNull!) : null;
  // @override
  // bool? get isHeaderComplete => null;

  int? get packetLength => (isCompletePacket != null) ? (view.lengthFieldOrNull!) : null;
  int? get excessLength => (packetLength != null) ? (view.length - packetLength!) : null; // view remainder

  bool get isStartValid => (view.startFieldOrNull! == view.configStartField);
  bool? get isIdValid => (view.idFieldOrNull != null) ? (view.idOf(view.idFieldOrNull!) != null) : null;

  // check field value, todo include length as well?
  bool? get isLengthValid => (view.lengthFieldOrNull != null) ? (view.lengthFieldOrNull! <= view.configLengthMax && view.lengthFieldOrNull! >= view.configHeaderLength) : null;
  // length must be set first
  bool? get isChecksumValid => (view.length == view.lengthFieldOrNull) ? (view.checksumFieldOrNull! == view.checksum()) : null;
}

class PayloadHeaderStatus extends HeaderStatus {
  PayloadHeaderStatus(super.view);

  // @override
  // bool? get isHeaderComplete => (view.length >= view.configHeaderLength);
  @override
  bool get isCompletePacket => (view.lengthFieldOrNull != null) ? (view.length >= view.lengthFieldOrNull!) : false;
}

class SyncHeaderStatus extends HeaderStatus {
  SyncHeaderStatus(super.view);

  // @override
  // bool get isHeaderComplete => view.idFieldOrNull != null;
  @override
  bool get isCompletePacket => view.idFieldOrNull != null; // view.length > idField.end
  @override
  int? get packetLength => (isCompletePacket) ? (view.idField.end) : null;
  @override
  bool? get isLengthValid => null;
  // @override
  // bool? get isChecksumValid => null;
}

/// this way id can be const, build and parse can be root methods.
/// alternatively id hold build/parse function with packet passed as parameter
typedef PayloadHandlerConstructor<P> = PayloadHandler<P> Function();

/// payload handler per id
/// handle 'as' packet, alteratively pass packet/id as parameter
/// convert in place, on allocated buffer
/// this way all functions are associate as root methods to their respective objects
// extend packet - builder pattern, id contains cast functions
// packet converter/builder
// abstract interface class PayloadHandlerWithMeta<P, M> implements Packet {
// abstract interface class PayloadHandlerReqResp<T, R> implements Packet {
abstract interface class PayloadHandler<P> implements Packet {
  // PayloadHandler<P> castAsHandler(Packet buffer) => this..bytes = buffer.bytes;
  // dynamic buildPayloadOn(Packet buffer, P args) => castAsHandler(buffer).buildPayload(args);
  // P parsePayloadOn(Packet buffer, [dynamic metaStatus]) => castAsHandler(buffer).parsePayload(metaStatus);

  // returns intermediary status
  dynamic buildPayload(P args);
  P parsePayload([dynamic status]);

  // alternatively pass call build with type
  //M? buildMeta(P input)
  //M? buildHeaderExtension(P input)

  // header Extension handler per type with mixin
  // Packet Function() get headerHandler;
  // HeaderStatus parseHeaderExtension(Packet packet);
  // void buildHeaderExtension(Packet packet, [int? requestLength]);
}
