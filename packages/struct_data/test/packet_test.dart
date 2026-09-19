import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:struct_data/packet/packet_parser.dart';
import 'package:test/test.dart';

///
/// A worked protocol, shaped like MotProtocol: 0xA5 delimiter, 8-byte data header,
/// 4-byte control frame, little endian, 16-bit sum checksum.
///
/// The whole declaration is one `const` codec plus two enums. Under the previous module the
/// same protocol also needed a `Packet` subclass, two `ffi.Struct` header classes, and four
/// factory members on the format (`cast`, `caster`, `headerOf`, `syncHeaderOf`).
///

final class TestCodec extends PacketCodec {
  const TestCodec();

  @override
  int get lengthMax => 40;

  /// `[Start, Id, Length, Sequence, Checksum:2, Flex:2]` then payload.
  @override
  PacketFrameFormat get dataFormat => const PacketFrameFormat(
    length: 8,
    startId: 0xA5,
    startField: ByteField<Uint8>(0),
    idField: ByteField<Uint8>(1),
    lengthField: ByteField<Uint8>(2),
    checksumField: ByteField<Uint16>(4),
  );

  /// `[Start, Id, Option, _]` — no checksum, so the parser waves it through.
  @override
  PacketFrameFormat get syncFormat => const PacketFrameFormat(
    length: 4,
    startId: 0xA5,
    startField: ByteField<Uint8>(0),
    idField: ByteField<Uint8>(1),
  );

  @override
  PacketFrameFormat formatOf(PacketId id) => (id is PacketSyncId) ? syncFormat : dataFormat;

  @override
  PacketSyncId get ack => TestSyncId.ack;
  @override
  PacketSyncId get nack => TestSyncId.nack;
  @override
  PacketSyncId get abort => TestSyncId.abort;

  @override
  PacketId? idOf(int intId) => _ids(intId);

  // Requests and sync only: `TestRespId.echo` shares 0x10 with the request it answers, and
  // what `idOf` has to answer is what an arriving byte means. Response codecs are reached
  // through `PacketRequestId.responseId`, never through this table.
  static final PacketIdMap _ids = PacketIdMap([TestSyncId.values, TestReqId.values, TestCommandId.values]);
}

/// MotProtocol's real control frame: `{Start, SyncId, Option, Checksum}` with
/// `Checksum = Start ^ SyncId ^ Option` (MotPacket.c:50). A shape whose integrity is not a
/// byte sum, and whose field sits where the data shape's payload would be.
final class XorControlFormat extends PacketFrameFormat {
  const XorControlFormat() : super(length: 4, startId: 0xA5, startField: const ByteField<Uint8>(0), idField: const ByteField<Uint8>(1), checksumField: const ByteField<Uint8>(3));

  @override
  int checksumOf(ByteData frame, int lengthInBytes) {
    var xor = 0;
    for (int i = 0; i < checksumField!.offset; i++) {
      xor ^= frame.getUint8(i);
    }
    return xor;
  }
}

/// A header written through explicit field access instead of the format's descriptors — the
/// `castHeader` route, which a protocol would use to reach a struct with named fields. It
/// also stamps byte 3, a reserved field no descriptor names.
///
/// Held by the format, so it serves build *and* parse: swapping the view swaps both
/// directions without overriding any of the logic around them.
final class ManualHeader implements PacketHeader {
  const ManualHeader(this.frame);

  final ByteData frame;

  @override
  int get startField => frame.getUint8(0);
  @override
  set startField(int value) {
    frame.setUint8(0, value);
    frame.setUint8(3, 0xAB); // sequence, say
  }

  @override
  int get idField => frame.getUint8(1);
  @override
  set idField(int value) => frame.setUint8(1, value);

  @override
  int get lengthField => frame.getUint8(2);
  @override
  set lengthField(int value) => frame.setUint8(2, value);

  @override
  int get checksumField => frame.getUint16(4, Endian.little);
  @override
  set checksumField(int value) => frame.setUint16(4, value, Endian.little);

  @override
  int get payloadLength => lengthField - 8;
}

final class ManualCodec extends TestCodec {
  const ManualCodec();

  @override
  PacketFrameFormat get dataFormat => const PacketFrameFormat(
    length: 8,
    startId: 0xA5,
    startField: ByteField<Uint8>(0),
    idField: ByteField<Uint8>(1),
    lengthField: ByteField<Uint8>(2),
    checksumField: ByteField<Uint16>(4),
    headerCaster: ManualHeader.new,
  );
}

final class XorSyncCodec extends TestCodec {
  const XorSyncCodec();

  @override
  PacketFrameFormat get syncFormat => const XorControlFormat();
}

enum TestSyncId implements PacketSyncId {
  ping(0xA0),
  ack(0xA2),
  nack(0xA3),
  abort(0xA4)
  ;

  const TestSyncId(this.intId);
  @override
  final int intId;
}

/// One row per exchange. [responseId] defaults to the request's own byte, so only an answer
/// under a *different* byte says so.
enum TestReqId<T, R> implements PacketRequestId<T, R> {
  /// Same byte, different codec — the common case, and the short form.
  echo<Uint8List, Uint8List>(0x10, BytesPayload.cast, BytesPayload.cast),

  /// A different answer byte, one extra argument.
  query<Uint8List, Uint8List>(0x20, BytesPayload.cast, BytesPayload.cast, 0x21),

  /// A body governed by its own frame's header.
  tagged<Uint8List, (int, Uint8List)>(0x40, BytesPayload.cast, IdTaggedPayload.cast),

  /// A fixed-size struct, shorter on the wire than in Dart.
  fixed<Uint16List, Uint16List>(0x50, FixedArrayPayload.cast, FixedArrayPayload.cast)
  ;

  const TestReqId(int id, this.caster, this.responseCaster, [int? responseId]) : intId = id, responseId = responseId ?? id;

  @override
  final int intId;
  @override
  final PayloadCaster<T> caster;
  @override
  final PayloadCaster<R> responseCaster;
  @override
  final int responseId;
}

/// A one-way command: a payload id that is not a request id, so no answer can be awaited of
/// it. The distinction is the type, where it used to be a null `responseCaster`.
enum TestCommandId<T> implements PacketPayloadId<T> {
  notify<Uint8List>(0x30, BytesPayload.cast)
  ;

  const TestCommandId(this.intId, this.caster);

  @override
  final int intId;
  @override
  final PayloadCaster<T> caster;
}

/// A payload whose result depends on a field of the frame carrying it — the case that
/// justifies [Payload.parse] taking the packet at all. A handler shared by several ids reads
/// which one it is seeing; MotProtocol's data-mode handler does exactly this on the device.
final class IdTaggedPayload implements Payload<(int id, Uint8List body)> {
  IdTaggedPayload(this.region);

  factory IdTaggedPayload.cast(TypedData payload) => IdTaggedPayload(Uint8List.sublistView(payload));

  final Uint8List region;

  @override
  PayloadMeta build((int, Uint8List) values) {
    region.setAll(0, values.$2);
    return PayloadMeta(values.$2.length);
  }

  @override
  (int, Uint8List) parse(PacketHeader header) => (header.idField, Uint8List.sublistView(region, 0, header.payloadLength));
}

/// A fixed-size `ffi.Struct` payload, the case the over-long span exists for.
///
/// `Struct.create` throws on a region shorter than the struct, so this cannot be cast over a
/// frame's own payload — a 4-byte body in a 32-byte struct. It is cast over the whole span and
/// bounded by [PacketHeader.payloadLength]. `Var16ReadResponse` in the Mot table is exactly
/// this shape, and its comment says so: "the ffi.Struct boundary must be the full extent".
@Packed(1)
base class FixedArrayPayload extends Struct implements Payload<Uint16List> {
  factory FixedArrayPayload.cast(TypedData payload) => Struct.create<FixedArrayPayload>(payload);

  @Array(16)
  external Array<Uint16> values;

  @override
  PayloadMeta build(Uint16List input) {
    for (int i = 0; i < input.length; i++) {
      values[i] = input[i];
    }
    return PayloadMeta(input.length * Uint16List.bytesPerElement);
  }

  /// Zero-copy, and needing only the count: `Array.elements` aliases the frame, so slicing
  /// its backing to [PacketHeader.payloadLength] yields a view of the real bytes. This is the
  /// workaround `Var16ReadResponse` describes in a comment and never applied.
  @override
  Uint16List parse(PacketHeader header) {
    final TypedData elements = values.elements as TypedData;
    return elements.buffer.asUint16List(elements.offsetInBytes, header.payloadLength ~/ Uint16List.bytesPerElement);
  }
}

/// Payload that is just its bytes.
final class BytesPayload implements Payload<Uint8List> {
  BytesPayload(this.region);

  factory BytesPayload.cast(TypedData payload) => BytesPayload(Uint8List.sublistView(payload));

  final Uint8List region;

  @override
  PayloadMeta build(Uint8List values) {
    region.setAll(0, values);
    return PayloadMeta(values.length);
  }

  /// [region] is the whole span available, not this frame's payload, so the declared count
  /// is what bounds it.
  @override
  Uint8List parse(PacketHeader header) => Uint8List.sublistView(region, 0, header.payloadLength);
}

void main() {
  const TestCodec codec = TestCodec();

  Uint8List requestBytes(PacketPayloadId<Uint8List> id, List<int> payload) {
    final PacketBuffer out = PacketBuffer(codec);
    out.buildPayload<Uint8List>(id, Uint8List.fromList(payload));
    return Uint8List.fromList(out.bytes); // copy: the buffer is reused
  }

  /// Drive the transformer synchronously and collect what it emits.
  ///
  /// A sync controller so the whole exchange settles inside the test body — the emitted
  /// [Packet] is a view of the parser's buffer, so it is copied on the way out.
  (List<Uint8List> packets, List<Object> errors) run(List<Uint8List> chunks, {PacketCodec c = codec}) {
    final List<Uint8List> packets = [];
    final List<Object> errors = [];
    final controller = StreamController<Uint8List>(sync: true);

    controller.stream.transform(c.transformer).listen((p) => packets.add(Uint8List.fromList(p.bytes)), onError: errors.add);

    for (final chunk in chunks) {
      controller.add(chunk);
    }
    return (packets, errors);
  }

  group('build', () {
    test('data header describes the payload it was given', () {
      final PacketBuffer out = PacketBuffer(codec);
      final PayloadMeta built = out.buildPayload<Uint8List>(TestReqId.echo, Uint8List.fromList([1, 2, 3]));

      expect(built.length, 3);
      expect(out.length, codec.headerLength + 3, reason: 'view sized to header + payload');

      final Packet p = out;
      expect(p.startField, 0xA5);
      expect(p.packetId, TestReqId.echo);
      expect(p.lengthField, codec.headerLength + 3, reason: 'length field is the TOTAL frame length');
      expect(p.frameLength, p.lengthInBytes);
      expect(p.payloadLength, 3);
      expect(p.isChecksumValid, isTrue);
    });

    test('an oversized payload throws, and stages nothing', () {
      final PacketBuffer out = PacketBuffer(codec);
      out.buildPayload<Uint8List>(TestReqId.echo, Uint8List.fromList([1, 2, 3]));

      // The region a payload is handed is bounded by the frame, so one that overruns is
      // stopped by its own write. The buffer asserts only against a payload that *declares* a
      // length it did not write.
      expect(() => out.buildPayload<Uint8List>(TestReqId.echo, Uint8List(codec.payloadLengthMax + 1)), throwsRangeError);

      // Not "the previous frame survives": the header is opened before the payload runs, so
      // by the time one throws the buffer is already dirty. What is guaranteed is that it
      // does not still look like a frame.
      expect(out.isEmpty, isTrue);
    });

    test('a format may be read and written through a header caster', () {
      const ManualCodec manual = ManualCodec();
      final PacketBuffer out = PacketBuffer(manual);
      out.buildPayload<Uint8List>(TestReqId.echo, Uint8List.fromList([4, 5]));

      expect(out.bytes[3], 0xAB, reason: 'the caster reaches bytes the descriptors do not name');
      expect(out.isChecksumValid, isTrue, reason: 'and agrees with them on the ones they do');
      expect(out.header, isA<ManualHeader>(), reason: 'parse goes through the same view');

      final (packets, errors) = run([Uint8List.fromList(out.bytes)], c: manual);
      expect(errors, isEmpty);
      expect(Packet.of(manual, packets.single).payloadAsList<Uint8List>(), [4, 5]);
    });

    test('control frame is exactly syncHeaderLength and carries no stale bytes', () {
      final PacketBuffer out = PacketBuffer(codec);
      out.copy(Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF])); // dirty the buffer
      out.buildSync(TestSyncId.ack);

      expect(out.lengthInBytes, codec.syncHeaderLength);
      expect(out.bytes, [0xA5, 0xA2, 0x00, 0x00]);
      expect(out.syncId, TestSyncId.ack);
    });

    test('the data header clears reserved bytes it does not write', () {
      final PacketBuffer out = PacketBuffer(codec);
      out.copy(Uint8List.fromList(List<int>.filled(20, 0xFF))); // dirty the header region

      out.buildPayload<Uint8List>(TestReqId.echo, Uint8List.fromList([1]));

      expect(out.bytes[3], 0, reason: 'sequence');
      expect(out.bytes.sublist(6, 8), [0, 0], reason: 'flex');
    });

    test('a PacketBuffer is itself a Packet', () {
      final PacketBuffer out = PacketBuffer(codec);
      out.buildPayload<Uint8List>(TestReqId.echo, Uint8List.fromList([7, 7]));

      expect(out, isA<Packet>());
      expect(out.payloadAsList<Uint8List>(), [7, 7], reason: 'no intermediate view needed');
      expect(out.view.bytes, out.bytes, reason: 'view is a detached copy of the same frame');
      expect(identical(out.view, out), isFalse);
    });

    test('a codec may own its control-frame check byte', () {
      const XorSyncCodec xor = XorSyncCodec();
      final PacketBuffer out = PacketBuffer(xor);
      out.buildSync(TestSyncId.ack);

      expect(out.bytes, [0xA5, 0xA2, 0x00, 0xA5 ^ 0xA2]);
      expect(out.isChecksumValid, isTrue, reason: 'checked against its own shape, not the data shape');
    });
  });

  group('id table', () {
    test('responseId defaults to the request byte, and both codecs are declared', () {
      expect(TestReqId.echo.responseId, TestReqId.echo.intId, reason: 'answers under the request byte, unstated');
      expect(TestReqId.query.responseId, isNot(TestReqId.query.intId), reason: 'or under a byte of its own, stated');

      // Both directions are required, so neither is unwrapped at a call site.
      expect(TestReqId.tagged.caster, isNot(same(TestReqId.tagged.responseCaster)));
    });

    test('a payload may be governed by its own frame header', () {
      final PacketBuffer out = PacketBuffer(codec);
      out.buildPayload<Uint8List>(TestReqId.tagged, Uint8List.fromList([9, 9]));

      final PacketBuffer incoming = PacketBuffer(codec)..copy(Uint8List.fromList(out.bytes));
      final (int id, Uint8List body) = incoming.parseResponse(TestReqId.tagged);

      expect(id, 0x40, reason: 'read from the frame being decoded, not from the request');
      expect(body, [9, 9]);
    });

    test('a fixed-size struct payload casts over the span, not the frame', () {
      final PacketBuffer out = PacketBuffer(codec);
      final PayloadMeta built = out.buildRequest(TestReqId.fixed, Uint16List.fromList([0x1111, 0x2222]));

      expect(built.length, 4, reason: 'two words on the wire');
      expect(out.lengthInBytes, codec.headerLength + 4, reason: 'the frame is short, the struct is not');

      // Round-trip through a buffer, as the socket does. The payload region here is 4 bytes;
      // `Struct.create` needs 32, so a caster handed the frame's own payload would throw.
      final PacketBuffer incoming = PacketBuffer(codec)..copy(Uint8List.fromList(out.bytes));
      expect(incoming.parseResponse(TestReqId.fixed), [0x1111, 0x2222]);

      // And that is not hypothetical: bounding the region is exactly what fails.
      expect(() => FixedArrayPayload.cast(incoming.payload), throwsA(isA<Error>()), reason: 'the bounded payload is too short to cast');
    });

    test('a fixed-size struct payload reads the frame, not a copy of it', () {
      final PacketBuffer out = PacketBuffer(codec);
      out.buildRequest(TestReqId.fixed, Uint16List.fromList([0x1111, 0x2222]));

      final Uint16List parsed = out.parseResponse(TestReqId.fixed);
      expect(parsed, [0x1111, 0x2222]);

      // `Array.elements` aliases the struct's own bytes, so the view tracks the buffer.
      out.storage.setUint16(codec.headerLength, 0x9999, Endian.little);
      expect(parsed[0], 0x9999, reason: 'a view of the frame, not a snapshot of it');
    });

    test('a one-way command is a payload id and not a request id', () {
      // No answer can be awaited of it, and that is the type rather than a null codec.
      expect(TestCommandId.notify, isA<PacketPayloadId<Uint8List>>());
      expect(TestCommandId.notify, isNot(isA<PacketRequestId<Uint8List, dynamic>>()));

      final PacketBuffer out = PacketBuffer(codec);
      expect(out.buildPayload<Uint8List>(TestCommandId.notify, Uint8List.fromList([1])).length, 1);
    });
  });

  group('parse', () {
    test('one whole frame in one chunk', () {
      final (packets, errors) = run([
        requestBytes(TestReqId.echo, [1, 2, 3]),
      ]);

      expect(errors, isEmpty);
      expect(packets, hasLength(1));
      final Packet p = Packet.of(codec, packets.single);
      expect(p.packetId, TestReqId.echo);
      expect(p.payloadAsList<Uint8List>(), [1, 2, 3]);
    });

    test('one frame arriving one byte at a time', () {
      final frame = requestBytes(TestReqId.echo, [9, 8, 7, 6]);
      final (packets, errors) = run([
        for (final b in frame) Uint8List.fromList([b]),
      ]);

      expect(errors, isEmpty);
      expect(packets, hasLength(1));
      expect(Packet.of(codec, packets.single).payloadAsList<Uint8List>(), [9, 8, 7, 6]);
    });

    test('two frames in one chunk, plus a fragment of a third', () {
      final a = requestBytes(TestReqId.echo, [1]);
      final b = requestBytes(TestReqId.echo, [2, 2]);
      final c = requestBytes(TestReqId.echo, [3, 3, 3]);

      final (packets, errors) = run([
        Uint8List.fromList([...a, ...b, ...c.take(3)]),
        Uint8List.fromList(c.skip(3).toList()),
      ]);

      expect(errors, isEmpty);
      expect(packets, hasLength(3));
      expect(packets.map((p) => Packet.of(codec, p).payloadAsList<Uint8List>()), [
        [1],
        [2, 2],
        [3, 3, 3],
      ]);
    });

    test('leading garbage before the delimiter is skipped', () {
      final frame = requestBytes(TestReqId.echo, [5, 5]);
      final (packets, errors) = run([
        Uint8List.fromList([0x00, 0x11, 0x22, ...frame]),
      ]);

      expect(errors, isEmpty);
      expect(packets, hasLength(1));
      expect(Packet.of(codec, packets.single).payloadAsList<Uint8List>(), [5, 5]);
    });

    test('a corrupted payload is reported and the next frame still arrives', () {
      final bad = requestBytes(TestReqId.echo, [1, 2, 3]);
      bad[codec.headerLength] ^= 0xFF; // flip a payload byte, checksum now wrong
      final good = requestBytes(TestReqId.echo, [4, 5, 6]);

      final (packets, errors) = run([
        Uint8List.fromList([...bad, ...good]),
      ]);

      expect(errors, [PacketStatusException.checksum]);
      expect(packets, hasLength(1), reason: 'seekTrailing recovers the following frame');
      expect(Packet.of(codec, packets.single).payloadAsList<Uint8List>(), [4, 5, 6]);
    });

    test('a control frame parses on its own shape, with no length field', () {
      final PacketBuffer out = PacketBuffer(codec);
      out.buildSync(TestSyncId.ping);

      final (packets, errors) = run([Uint8List.fromList(out.bytes)]);

      expect(errors, isEmpty);
      expect(packets, hasLength(1));
      final Packet p = Packet.of(codec, packets.single);
      expect(p.syncId, TestSyncId.ping);
      expect(p.isSyncShape, isTrue);
      expect(p.frameLength, codec.syncHeaderLength);
      // This codec's control shape declares no checksum: the header reports its neutral value
      // rather than throwing, so a control frame answers the same questions a data frame does.
      expect(p.checksumField, 0);
      expect(p.isChecksumValid, isTrue, reason: 'nothing to contradict');
    });

    test('a control frame is checked against its own shape', () {
      const XorSyncCodec xor = XorSyncCodec();
      final PacketBuffer out = PacketBuffer(xor);
      out.buildSync(TestSyncId.ack);
      final Uint8List good = Uint8List.fromList(out.bytes);
      final Uint8List bad = Uint8List.fromList(good)..[3] ^= 0xFF;

      expect(run([good], c: xor).$2, isEmpty);
      // The data shape's checksum field lies past a control frame entirely, so with one set
      // of descriptors on the codec this frame could be neither written nor checked.
      expect(run([bad], c: xor).$2, [PacketStatusException.checksum]);
    });

    test('a control frame followed by a data frame', () {
      final PacketBuffer out = PacketBuffer(codec);
      out.buildSync(TestSyncId.ack);
      final sync = Uint8List.fromList(out.bytes);
      final data = requestBytes(TestReqId.echo, [7]);

      final (packets, errors) = run([
        Uint8List.fromList([...sync, ...data]),
      ]);

      expect(errors, isEmpty);
      expect(packets.map((p) => Packet.of(codec, p).packetId), [TestSyncId.ack, TestReqId.echo]);
    });
  });

  group('round trip', () {
    test('request out, response in, through a socket-shaped exchange', () {
      final PacketBuffer out = PacketBuffer(codec);
      final PacketBuffer incoming = PacketBuffer(codec);

      final PayloadMeta request = out.buildRequest(TestReqId.echo, Uint8List.fromList([1, 2, 3, 4]));
      expect(request.length, 4);

      // the device echoes it back verbatim
      incoming.copy(Uint8List.fromList(out.bytes));

      expect(incoming.parseResponse(TestReqId.echo), [1, 2, 3, 4]);
    });

    test('transformer, socket copy and payload parse agree on the length', () {
      // The chain ProtocolSocket runs: bytes off the link, framed by the transformer, copied
      // into the socket's own buffer, then parsed. A short body in a long allocation, so any
      // step using the wrong length shows up.
      final PacketBuffer out = PacketBuffer(codec);
      out.buildRequest(TestReqId.fixed, Uint16List.fromList([0x1111, 0x2222, 0x3333]));
      final Uint8List wire = Uint8List.fromList(out.bytes);

      expect(wire.length, codec.headerLength + 6);

      // delivered split, to make the parser do real work
      final (packets, errors) = run([Uint8List.sublistView(wire, 0, 5), Uint8List.sublistView(wire, 5)]);
      expect(errors, isEmpty);
      expect(packets, hasLength(1));
      expect(packets.single.length, wire.length, reason: 'the transformer emits exactly the frame');

      // ProtocolSocket.add: copy into the socket's own max-length buffer
      final PacketBuffer incoming = PacketBuffer(codec)..copy(packets.single);

      expect(incoming.lengthInBytes, wire.length, reason: 'copy sizes the view to the frame');
      expect(incoming.payloadLength, 6, reason: 'bytes present');
      expect(incoming.header.payloadLength, 6, reason: 'bytes declared — they agree on a whole frame');
      expect(incoming.storage.lengthInBytes, codec.lengthMax, reason: 'the span stays the allocation, for the cast');

      expect(incoming.parseResponse(TestReqId.fixed), [0x1111, 0x2222, 0x3333]);
    });

    test('a partly arrived frame is read by the parser, not by Packet', () {
      final frame = requestBytes(TestReqId.echo, [1, 2, 3]);
      final HeaderParser parser = HeaderParser(codec);

      parser.receive(Uint8List.sublistView(frame, 0, 3));

      expect(parser.startFieldOrNull, 0xA5);
      expect(parser.idFieldOrNull, TestReqId.echo.intId);
      expect(parser.idOrNull, TestReqId.echo);
      expect(parser.isStartFieldValid, isTrue);
      expect(parser.isIdFieldValid, isTrue);
      expect(parser.checksumFieldOrNull, isNull, reason: 'a struct cast would have thrown here');
      expect(parser.isChecksumFieldValid, isNull);
      // The length field is byte 2, so the frame sizes itself well before it is whole.
      expect(parser.frameLengthOrNull, frame.length);
      expect(parser.isComplete, isFalse);

      parser.receive(Uint8List.sublistView(frame, 3));

      expect(parser.frameLengthOrNull, frame.length);
      expect(parser.isComplete, isTrue);
      expect(parser.isChecksumFieldValid, isTrue);
      expect(parser.payloadAsList<Uint8List>(), [1, 2, 3]);
    });
  });
}
