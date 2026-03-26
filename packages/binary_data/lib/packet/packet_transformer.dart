import 'dart:async';
import 'package:meta/meta.dart';

import 'packet.dart';

export 'packet.dart';

/// [Packet Rx Meta Parser Buffer]
/// Rx Packet Buffer and the state of the PacketTransformer
// handles framing, caller validate data
class HeaderParser extends PacketBuffer {
  HeaderParser(PacketFormat packetInterface, [int? size]) : super(packetInterface, size ?? packetInterface.lengthMax * 4);

  late Uint8List trailing = Uint8List.sublistView(viewAsBytes);

  int get _startId => packetClass.startId;

  HeaderStatus get status => HeaderStatus(viewAsPacket);

  // cannot cast struct without full length
  // always copies remainder, double buffers.
  // but does not need additional logic to handle remainder, simpler logic than shifting views
  // sets view length to bound validity checks
  void receive(Uint8List bytes) {
    // handle trailing here
    if (isEmpty) {
      if (bytes.seekChar(_startId) case Uint8List result) copy(result);
    } else {
      add(bytes);
    }
  }

  void seekStart() {
    if (viewAsBytes.seekChar(_startId) case Uint8List view) {
      copy(view);
    } else {
      clear(); // no startId found, clear buffer
    }
  }

  void seekTrailing() => copy(trailing);

  // trim trailing before checking checksum
  // effectively sets pointers to (packetStart, packetEnd/trailingStart, trailingEnd)
  void completePacket() {
    assert(status.isPacketComplete == true);
    final completeLength = viewAsPacket.packetLengthOrNull!; // only valid when status.isPacketComplete
    trailing = Uint8List.sublistView(viewAsBytes, completeLength);
    viewLength = completeLength;
  }

  // alternative implementation for fragmented trailing buffer
  // headerParser need caster to shift view packet.cast
  // disallow changing dataView as pointer directly, caller use length
  // int get viewLength => dataView.lengthInBytes;
}

/// immutable view of packet parsing status
/// determine complete, error, or wait for more data
/// as state machine state
class HeaderStatus {
  const HeaderStatus(this.packet);
  @protected
  final Packet packet;

  /// is full length packet or greater, caller `ensure field are valid` before calling
  bool get isPacketComplete {
    assert(isStartValid != false);
    assert(isIdValid != false);
    // assert(isLengthValid != false); //check length field if implemented
    return packet.isPacketComplete;
  }

  // bool? effectively as 3 state: null=unknown, false=invalid, true=valid
  bool? get isStartValid => packet.isStartFieldValid; // nullable when StartField is multiple bytes
  bool? get isIdValid => packet.isIdFieldValid;
  // check packet length field if implemented
  bool? get isLengthValid => packet.isLengthFieldValid;
  // packet must be complete and length set
  bool? get isChecksumValid => packet.isChecksumFieldValid; // (isPacketComplete == true), buffer.length == buffer.lengthFieldOrNull
}

extension PacketFormatTransformer on PacketFormat {
  PacketTransformer get transformer => PacketTransformer(parserBuffer: HeaderParser(this));
}

/// combine partial/fragmented packets
/// emitted [Packet] is a reference to the buffer, not a copy. handling must be synchronous, before returning control to the transformer
class PacketTransformer extends StreamTransformerBase<Uint8List, Packet> implements EventSink<Uint8List> {
  PacketTransformer({required this.parserBuffer}); // alternatively pass packetClass and create parserBuffer internally

  late final EventSink<Packet> _outputSink;
  final HeaderParser parserBuffer;

  void debugLog(Object? message) {
    // assert(() {
    //   print(message);
    //   return true;
    // }());
  }

  @override
  void add(Uint8List bytesIn) {
    debugLog('');
    debugLog('--- bytesIn: $bytesIn');
    debugLog('remainder: ${parserBuffer.viewAsBytes}');

    parserBuffer.receive(bytesIn); // optional optimize by checking fragment state first

    try {
      // while - potentially 1+ packets queued, do while HeaderStatus(isPacketComplete: false)
      while (parserBuffer.viewAsBytes.isNotEmpty) {
        debugLog('- parseHeader Loop Start: ${parserBuffer.viewAsBytes}');

        switch (parserBuffer.status) {
          case HeaderStatus(isStartValid: false):
            parserBuffer.seekStart();
            debugLog('parserBuffer seekStart(): ${parserBuffer.viewAsBytes}');

          case HeaderStatus(isIdValid: false):
            throw PacketStatusException.meta;

          // isFullLength
          case HeaderStatus(isPacketComplete: true):
            parserBuffer.completePacket(); // set length for checksum operation
            debugLog('parserBuffer completePacket() ${parserBuffer.viewAsBytes} trailing ${parserBuffer.trailing}');
            switch (parserBuffer.status.isChecksumValid) {
              case true || null: // null when no checksum implemented
                /// pass on the packet, full buffer including
                _outputSink.add(parserBuffer.viewAsPacket); // data pointer is either from Link, or remainderBuffer
                /// transformed stream handles using same headerView before continuing
                parserBuffer.seekTrailing(); // if excess packets queued, repeat parsing loop with trailing buffer as new buffer

              case false:
                throw PacketStatusException.checksum;
            }

          /// in case of [sync][sync], todo check before check complete
          case HeaderStatus(isLengthValid: false):
            throw PacketStatusException.meta;

          /// no recognizable id, or recognized as incomplete
          case HeaderStatus(isPacketComplete: false):
            assert(parserBuffer.viewLength < parserBuffer.packetClass.lengthMax); // should be caught by isLengthValid
            return;
        }
      }
    } on PacketStatusException catch (e) {
      // unparsable error
      switch (e) {
        case PacketStatusException.meta:
          parserBuffer.clear(); // ensure remainder buffer is cleared this way
        case PacketStatusException.checksum:
          parserBuffer.seekTrailing();
          debugLog('${parserBuffer.viewAsPacket}');
          debugLog('${parserBuffer.viewAsPacket.checksumFieldOrNull}');
      }
      _outputSink.addError(e);
    } catch (e) {
      parserBuffer.clear();
      _outputSink.addError(e);
    } finally {
      debugLog('- finally');
      debugLog('parserBuffer bytes ${parserBuffer.viewAsBytes}');
    }
  }

  @override
  void addError(Object e, [StackTrace? st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();

  EventSink<Uint8List> _mapSink(EventSink<Packet> sink) => this.._outputSink = sink;
  @override
  Stream<Packet> bind(Stream<Uint8List> stream) => Stream<Packet>.eventTransformed(stream, _mapSink);
}

sealed class PacketStatus {}

enum PacketStatusOk implements PacketStatus { ok }

enum PacketStatusException implements PacketStatus, Exception { meta, checksum }
