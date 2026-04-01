part of 'packet.dart';

///
/// [PacketId] Types
///

class PacketIdCaster {
  PacketIdCaster({required Iterable<List<PacketId>> idLists, List<PacketSyncId>? syncIds})
    : _lookUpMap = Map<int, PacketId>.unmodifiable({
        for (final idList in idLists)
          for (final id in idList) id.intId: id,
      });

  final Map<int, PacketId> _lookUpMap;

  PacketId? call(int intId) => _lookUpMap[intId];
}

// separate type label allow pattern matching
// the base type can be sealed
abstract interface class PacketId implements Enum {
  int get intId;
}

abstract interface class PacketSyncId implements PacketId {}

// // Id hold a constructor to create a handler instance to process as packet
abstract interface class PacketPayloadId<V> implements PacketId {
  PayloadCaster<V> get payloadCaster;
}

// abstract interface class PacketFixedId<V> implements PacketPayloadId<V> {
//   int get length;
// }

// abstract interface class PacketVariableId<V> implements PacketPayloadId<V> {
//   // int get lengthMax;
//   // int lengthOf(V values);
// }

/// Id as payload factory
/// A `Request` matched with a `Response`
/// paired request response id for simplicity in case of shared id by request and response
/// can under define responseId for 1-way
/// handlers as constructors, const for enum
abstract interface class PacketIdRequest<T, R> implements PacketId {
  PacketId? get responseId; // null for 1-way or matching response, override for non matching
  PayloadCaster<T>? get requestCaster;
  PayloadCaster<R>? get responseCaster;
}

extension PacketIdMethods on PacketId {
  String toStringAsHex() => '$name(0x${intId.toRadixString(16).toUpperCase().padLeft(2, '0')})';
}

///
/// [Payload<V>]
///
/// extends Struct and Payload
/// Payload need to contain a static cast function
/// factory Child.cast(TypedData target);
/// convert in place, on allocated buffer
/// build/parse with a reference to the header, although both are part of a contiguous buffer
/// payload class without direct context of header
///   allows stronger encapsulation
///   does not have to declare filler header fields
/// for simplicity, the packet header includes all meta parameters, parsing a payload does not need stateMeta
//  Alternative
// Codec functions would double buffer with return Uint8List
// same as cast, build, asTypedData
// Uint8List encodePayload(T input);
// T decodePayload(Uint8List input);

abstract interface class Payload<V> {
  @pragma('vm:prefer-inline')
  PayloadMeta build(V values, covariant Packet header);
  @pragma('vm:prefer-inline')
  V parse(covariant Packet header, covariant PayloadMeta? stateMeta);
}

// abstract interface class PayloadFixed<V extends Record> {
//   V get values;
//   set values(V values);
// }

/// [Payload] Constructor - handler per id
/// `Struct.create<T>`
typedef PayloadCaster<V> = Payload<V> Function(TypedData typedData);

/// any additional state not included in the header
// length state maintained by caller. cannot be included as struct field, that would be a part of the payload data
class PayloadMeta {
  const PayloadMeta(this.length, [this.other]);
  final int length;
  // final PacketId? packetId;
  final Record? other;
}
