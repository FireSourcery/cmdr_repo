// ignore_for_file: annotate_overrides

import 'dart:typed_data';

///
/// Struct Components Header/Payload
///
// extension type const HeaderView<K extends ByteField>(ByteStruct<K> _struct) {
//   // All fields accessible, bounds-checked
//   int? operator [](K key) => key.getInOrNull(_struct);
//   void operator []=(K key, int value) => key.setIn(_struct, value);
// }
///
/// [Header]
///
typedef PacketHeaderCaster = PacketHeader Function(TypedData typedData);
// typedef PacketHeaderSyncCaster = PacketHeaderSync Function(TypedData typedData);
// typedef PacketHeaderCaster<P extends PacketHeader> = P Function(TypedData typedData);

//  base side handles format beloning to packet.

// abstract interface class HeaderFormat {
//   ByteField get startField;
//   ByteField get idField;
//   ByteField get lengthField;
//   ByteField get checksumField;

//   List<ByteField> get fields;
//   int get length;
//   int get syncLength;

//   // Build operations (currently on Packet)
//   void buildSync(ByteData target, int startId, PacketId packetId);
//   void buildRequest(ByteData target, int startId, PacketId requestId, int payloadLength, int Function(int) checksumFn);

//   // Validate operations (currently on Packet)
//   bool? isStartValid(ByteData data, int expectedStart);
//   bool? isIdValid(ByteData data, PacketId? Function(int) idLookup);
// }

// collective handler.
// abstract class PacketHeader extends ByteStructBase<PacketHeader, ByteField> {
//   PacketHeader(super.byteData);

//   int get startField;
//   int get idField;
//   int get lengthField;
//   int get checksumField;

//   set startField(int value);
//   set idField(int value);
//   set lengthField(int value);
//   set checksumField(int value);

//   // bool get isIdValid => isValidId(headerAsSyncType.idFieldValue);
//   // bool get isLengthValid => isValidLength(headerAsPayloadType.lengthFieldValue);
//   // bool get isChecksumValid => isValidChecksum(headerAsPayloadType.checksumFieldValue);

//   // void buildHeaderAsRequest(PacketId requestId, int payloadLength) {
//   // void buildHeaderAsSync(PacketId requestId, int payloadLength) {
//   // void build(PacketId packetId, Packet? packet); // can be overridden for additional types
//   // void buildHeaderAsRequest(PacketId requestId, int payloadLength) {
//   // packetClass.startFieldDef.setInOrNot(packetData, packetClass.startId);
//   // packetClass.idFieldDef.setInOrNot(packetData, requestId.intId);
//   // packetClass.lengthFieldDef.setInOrNot(packetData, payloadLength + packetClass.headerLength);
//   // packetClass.checksumFieldDef.setInOrNot(packetData, checksum(payloadLength + packetClass.headerLength));
// }

// fields over ffi.struct

/// Minimal header
/// ControlChar
abstract interface class PacketIdHeader {
  int get startField;
  int get idField;
  set startField(int value);
  set idField(int value);
}

abstract interface class PacketHeader implements PacketIdHeader {
  int get startField; // > 1 byte user handle using Word module
  int get idField;
  int get lengthField;
  int get checksumField;

  set startField(int value);
  set idField(int value);
  set lengthField(int value);
  set checksumField(int value);

  // void build(PacketId packetId, Packet? packet); // can be overridden for additional types
}

abstract interface class PacketFixedHeader implements PacketIdHeader {
  int get startField;
  int get idField;
  int get checksumField;

  set startField(int value);
  set idField(int value);
  set checksumField(int value);
}

// meta char
abstract interface class PacketSyncHeader implements PacketIdHeader {
  int get startField;
  int get idField;
  set startField(int value);
  set idField(int value);
}

// extension PacketHeaderMethods on PacketHeader {}
