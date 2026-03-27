import 'dart:async';

import 'package:struct_data/packet/packet_transformer.dart';

class PacketTransformerDebug extends StreamTransformerBase<Uint8List, Packet> implements EventSink<Uint8List> {
  PacketTransformerDebug({required this.parserBuffer}); // alternatively pass packetClass and create parserBuffer internally

  late final EventSink<Packet> _outputSink;
  final HeaderParser parserBuffer;

  void debugLog(Object? message) {
    assert(() {
      print(message);
      return true;
    }());
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
            assert(parserBuffer.length < parserBuffer.packetClass.lengthMax); // should be caught by isLengthValid
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
