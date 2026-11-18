import 'dart:async';
import 'dart:typed_data';

import 'package:cmdr/connection/mot_connection/mot_packet.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression vectors for [MotPacketCodec]. Every expected byte is derived from the firmware codec, not from this codec's output:
// FireSourcery_Library `Motor/MotProtocol/MotPacket.h`, `MotPacket.c` and `Framework/Protocol/Packet.h`, multi-byte fields little-endian
// as the ARM target stores them. `MotPacket_Frame.md` beside them tabulates the same rules.

const MotPacketCodec _codec = MotPacketCodec();

/// `sizeof(MotPacket_Header_T)`, MotPacket.h:138-147: `Start, Id, Length, Sequence, Checksum:2, Flags:2`.
const int _dataHeaderLength = 8;

/// `sizeof(MotPacket_Control_T)`, MotPacket.h:155-162: `Start, SyncId, Option, Checksum`.
const int _controlFrameLength = 4;

/// `MotPacket_BuildControl`, MotPacket.c:50-58: Start 0xA5 (MotPacket.h:45), the id (MotPacket.h:76-80), Option 0, then `Start ^ SyncId ^ Option`.
const Map<MotPacketControlId, List<int>> _controlFrames = {
  MotPacketControlId.MOT_PACKET_PING: [0xA5, 0xA0, 0x00, 0x05],
  MotPacketControlId.MOT_PACKET_SYNC_ACK: [0xA5, 0xA2, 0x00, 0x07],
  MotPacketControlId.MOT_PACKET_SYNC_NACK: [0xA5, 0xA3, 0x00, 0x06],
  MotPacketControlId.MOT_PACKET_SYNC_ABORT: [0xA5, 0xA4, 0x00, 0x01],
};

/// A `MotPacket_VarWriteFixedReq_T` (MotPacket.h:265) framed by `MotPacket_BuildHeader` (MotPacket.c:65-74): Id 0xB2 (MotPacket.h:95),
/// Length 8 + 8, Sequence and Flags 0, and the 16-bit sum of every byte but the checksum's own two,
/// 0xA5 + 0xB2 + 0x10 + 0x34 + 0x12 + 0x01 + 0xEF + 0xCD + 0xAB + 0x89 = 0x049E.
const FixedVarWriteRequestValues _varWrite = (id: 0x1234, flags: 0x0001, value: 0x89ABCDEF);
const List<int> _varWriteFrame = [0xA5, 0xB2, 0x10, 0x00, 0x9E, 0x04, 0x00, 0x00, /**/ 0x34, 0x12, 0x01, 0x00, 0xEF, 0xCD, 0xAB, 0x89];

/// The controller's VERSION answer, `Version` (MotorController_MotProtocol.c:72-83): Protocol `MOT_PACKET_VERSION_WORD32` 0xFF1A070D
/// (MotPacket.h:39-43), Library `MOTOR_LIBRARY_VERSION` 0x00000100 (Motor/Version.h:35-39), Firmware a board's own word, 0x0A0B0C0D here.
/// Length 8 + 12 (`MotPacket_VersionResp_T`, MotPacket.h:238), checksum 0xA5 + 0x01 + 0x14 + (0x0D + 0x07 + 0x1A + 0xFF) + 0x01 + (0x0D + 0x0C + 0x0B + 0x0A) = 0x0216.
const VersionResponseValues _version = (protocol: 0xFF1A070D, library: 0x00000100, firmware: 0x0A0B0C0D);
const List<int> _versionFrame = [0xA5, 0x01, 0x14, 0x00, 0x16, 0x02, 0x00, 0x00, /**/ 0x0D, 0x07, 0x1A, 0xFF, 0x00, 0x01, 0x00, 0x00, 0x0D, 0x0C, 0x0B, 0x0A];

/// Every byte 0xFF, so a header field the builder leaves unwritten shows in the frame.
PacketBuffer _dirtyBuffer() => PacketBuffer(_codec)..copy(Uint8List.fromList(List.filled(_codec.lengthMax, 0xFF)));

/// [reads] through the codec's transformer, synchronously. Each frame is copied: what the transformer emits is a view of its buffer.
(List<Uint8List> packets, List<Object> errors) _parse(List<List<int>> reads) {
  final (List<Uint8List>, List<Object>) result = ([], []);
  final StreamController<Uint8List> link = StreamController(sync: true);
  link.stream.transform(_codec.transformer).listen((packet) => result.$1.add(Uint8List.fromList(packet.bytes)), onError: result.$2.add);
  reads.map(Uint8List.fromList).forEach(link.add);
  return result;
}

void main() {
  group('control frame', () {
    for (final MapEntry(key: id, value: frame) in _controlFrames.entries) {
      test('$id builds to the MotPacket_BuildControl bytes, and parses back', () {
        expect((_dirtyBuffer()..buildControl(id)).bytes, frame);

        final (packets, errors) = _parse([frame]);
        expect(errors, isEmpty);
        expect(packets, [frame]);
        expect(Packet.of(_codec, packets.single).controlId, id);
      });
    }
  });

  group('data frame', () {
    test('a FIXED_VAR_WRITE request builds to the MotPacket_BuildHeader bytes, and parses back', () {
      expect((_dirtyBuffer()..buildRequest(MotPacketRequestId.MOT_PACKET_FIXED_VAR_WRITE, _varWrite)).bytes, _varWriteFrame);

      final (packets, errors) = _parse([_varWriteFrame]);
      expect(errors, isEmpty);
      expect(packets, [_varWriteFrame]);
      expect(Packet.of(_codec, packets.single).parsePayload(MotPacketRequestId.MOT_PACKET_FIXED_VAR_WRITE), _varWrite);
    });

    test('the VERSION answer the controller sends parses to its three words', () {
      final (packets, errors) = _parse([_versionFrame]);
      expect(errors, isEmpty);
      expect(Packet.of(_codec, packets.single).parseResponse(MotPacketRequestId.MOT_PACKET_VERSION), _version);
    });

    // `MotPacket_MemReadReq_T {uint32_t Address; uint8_t Size, Resv; uint16_t Config}`, MotPacket.h:305; the controller sizes it from the Length byte, MotPacket.c:135-142.
    test('a MEM_READ request is a ${_dataHeaderLength + 8}-byte frame, and its Length byte says so', () {
      final PacketBuffer frame = PacketBuffer(_codec)..buildRequest(MotPacketRequestId.MOT_PACKET_MEM_READ, (address: 0x20000000, size: 32, config: 0));
      expect(frame.lengthInBytes, _dataHeaderLength + 8);
      expect(frame.lengthField, _dataHeaderLength + 8);
    });
  });

  // `MotPacket_ParseLength`, MotPacket.c:115-144: the ids the controller sizes from the id alone, not from a Length byte.
  group('id-to-length map', () {
    // MotPacket.c:120-125
    for (final MotPacketControlId id in [
      MotPacketControlId.MOT_PACKET_PING,
      MotPacketControlId.MOT_PACKET_SYNC_ACK,
      MotPacketControlId.MOT_PACKET_SYNC_NACK,
      MotPacketControlId.MOT_PACKET_SYNC_ABORT,
      MotPacketControlId.MOT_PACKET_PING_BOOT,
      MotPacketControlId.MOT_PACKET_PING_ALT,
    ]) {
      test('$id is a $_controlFrameLength-byte frame, and is sized from its id on arrival', () {
        final Uint8List frame = Uint8List.fromList((PacketBuffer(_codec)..buildControl(id)).bytes);
        expect(frame.length, _controlFrameLength);
        expect((HeaderParser(_codec)..receive(frame)).frameLengthOrNull, _controlFrameLength);
      });
    }

    // MotPacket.c:128-132, the header plus the request struct. The Length byte must agree: the controller's `Meta.Length` still comes from it (MotPacket.c:177).
    for (final (id, values, frameLength) in <(PacketRequestId<Object?, Object?>, Object?, int)>[
      (MotPacketRequestId.MOT_PACKET_STOP_ALL, null, _dataHeaderLength + 0), // MotPacket_StopReq_T {}, MotPacket.h:245
      (MotPacketRequestId.MOT_PACKET_VERSION, null, _dataHeaderLength + 0), // MotPacket_VersionReq_T {}, MotPacket.h:237
      (MotPacketRequestId.MOT_PACKET_CALL, (id: 1, arg: 2), _dataHeaderLength + 8), // MotPacket_CallReq_T {uint32_t Id, Arg}, MotPacket.h:252
      (MotPacketRequestId.MOT_PACKET_FIXED_VAR_READ, (id: 1, flags: 0), _dataHeaderLength + 4), // MotPacket_VarReadFixedReq_T {uint16_t MotVarId, Flags}, MotPacket.h:262
      (MotPacketRequestId.MOT_PACKET_FIXED_VAR_WRITE, _varWrite, _dataHeaderLength + 8), // MotPacket_VarWriteFixedReq_T {uint16_t MotVarId, Flags; uint32_t Value}, MotPacket.h:265
    ]) {
      test('$id is a $frameLength-byte frame, and its Length byte says so', () {
        final PacketBuffer frame = PacketBuffer(_codec)..buildRequest(id, values);
        expect(frame.lengthInBytes, frameLength);
        expect(frame.lengthField, frameLength);
      });
    }
  });

  test('the data checksum sums every byte but its own two, Sequence and Flags included', () {
    // `MotPacket_Checksum` (MotPacket.c:45-48) is `Packet_Checksum` at offset 4, size 2, which for a frame past the field sums bytes 0..3
    // and 6..Length-1 into a uint16_t (Packet.h:381-401). [_varWriteFrame] with Sequence 0x5A, Flags 0xC33C and 0xFFFF in the field:
    // 0x049E + 0x5A + 0x3C + 0xC3 = 0x05F7.
    final Uint8List frame = Uint8List.fromList(_varWriteFrame)..setAll(3, [0x5A, 0xFF, 0xFF, 0x3C, 0xC3]);
    expect(const MotDataFormat().checksumOf(ByteData.sublistView(frame), frame.length), 0x05F7);
  });

  group('framing errors', () {
    // A variable-length id's Length under its own header is refused before any checksum, MotPacket.c:134-141 and MotPacket_Frame.md:119-121.
    // The id is VAR32_WRITE 0xB6 (MotPacket.h:105), whose one-entry payload is FIXED_VAR_WRITE's (MotPacket.h:296): a fixed-length id is sized
    // from the id instead (MotPacket.c:128-132) and never reaches that check. Lengths 4 and 5 once completed a frame ahead of its checksum field
    // and passed unchecked. The next frame comes in a read of its own: a meta error drops the rest of its read.
    for (int declared = 0; declared < _dataHeaderLength; declared++) {
      test('a declared length of $declared is refused, and the next frame still parses', () {
        final List<int> short = List.of(_varWriteFrame)..setAll(1, [0xB6, declared]); // Id, Length: MotPacket.h:141-142
        final (packets, errors) = _parse([short, _versionFrame]);
        expect(errors, [PacketStatusException.meta]);
        expect(packets, [_versionFrame]);
      });
    }

    test('a corrupted checksum is refused, and the parser resyncs on the frame behind it', () {
      final List<int> corrupted = List.of(_varWriteFrame)..[4] ^= 0xFF; // Checksum low byte, MotPacket.h:144
      final (packets, errors) = _parse([
        [...corrupted, 0x00, 0x11, ..._versionFrame],
      ]);
      expect(errors, [PacketStatusException.checksum]);
      expect(packets, [_versionFrame]);
    });

    // 0xA5, `MOT_PACKET_SYNC_RESV` (MotPacket.h:81), is no sync shape (MotPacket.c:98-110, MotPacket_Frame.md:89): the controller reads its byte 2
    // as a data Length, and a Length of 0 is under the header, MotPacket.c:141.
    test('id 0xA5 is not a control frame: the 4 bytes one would be are refused', () {
      final (packets, errors) = _parse([
        [0xA5, 0xA5, 0x00, 0xA5 ^ 0xA5 ^ 0x00],
        _versionFrame,
      ]);
      expect(errors, [PacketStatusException.meta]);
      expect(packets, [_versionFrame]);
    });
  });
}
