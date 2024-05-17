import 'package:meta/meta.dart';

import 'packet.dart';




// PacketHeaderBuilder
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
