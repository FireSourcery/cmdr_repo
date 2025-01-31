import 'dart:async';

import 'package:binary_data/models/packet.dart';
import 'package:meta/meta.dart';

import 'protocol.dart'; // or move status

/// Packet Rx Meta Parser
/// Rx Packet Buffer and the state of the PacketTransformer
class HeaderParser extends PacketBuffer {
  // HeaderParser(super.packetCaster, super.size) : super.size();
  HeaderParser(super.packetInterface, super.size) : super();

  late Uint8List trailing = Uint8List.sublistView(viewAsBytes);

  int get startId => packetClass.startId;

  HeaderStatus get status => HeaderStatus(viewAsPacket);

  /// todo track length before parsing: RangeError (typedData.lengthInBytes): The typed list is not large enough: Not greater than or equal to 8: 3

  // cannot cast struct without full length
  // always copies remainder, double buffers.
  // but does not need additional logic to handle remainder, simpler logic than switching pointers
  // sets view length to bound validity checks
  void receive(Uint8List bytes) {
    // handle trailing here
    if (isEmpty) {
      if (bytes.seekChar(startId) case Uint8List result) copy(result);
    } else {
      add(bytes);
    }
  }

  void seekStart() => switch (viewAsBytes.seekChar(startId)) { Uint8List view => copy(view), null => clear() };
  void seekTrailing() => copy(trailing);

  // trim trailing before checking checksum
  // effectively sets pointers to (packetStart, packetEnd/trailingStart, trailingEnd)
  void completePacket() {
    assert(status.isPacketComplete == true);
    final completeLength = viewAsPacket.packetLengthOrNull!; // only valid when status.isPacketComplete
    trailing = Uint8List.sublistView(viewAsBytes, completeLength);
    viewLength = completeLength;
  }

  // alternatively as caster
  // headerParser need caster to shift view packet.cast
}

/// determine complete, error, or wait for more data
class HeaderStatus {
  HeaderStatus(this.packet);
  @protected
  final Packet packet;

  /// is full length packet or greater, caller `ensure field are valid` before calling
  bool get isPacketComplete {
    assert(isStartValid != false);
    assert(isIdValid != false);
    assert(isLengthValid != false);
    return packet.isPacketComplete;
  }

  bool? get isStartValid => packet.isStartFieldValid; // nullable when StartField is multiple bytes
  bool? get isIdValid => packet.isIdFieldValid;
  // non-sync only
  bool? get isLengthValid => packet.isLengthFieldValid;
  // packet must be complete and length set
  bool? get isChecksumValid => packet.isChecksumFieldValid; // (isPacketComplete == true), buffer.length == buffer.lengthFieldOrNull
}

/// combine partial/fragmented packets
/// emitted [Packet] is a reference to the buffer, not a copy. handling must be synchronous, before returning control to the transformer
class PacketTransformer extends StreamTransformerBase<Uint8List, Packet> implements EventSink<Uint8List> {
  PacketTransformer({required this.parserBuffer});

  late final EventSink<Packet> _outputSink;
  final HeaderParser parserBuffer;

  @override
  void add(Uint8List bytesIn) {
    // assert(() {
    //   print('');
    //   print('---');
    //   print('remainder: ${parserBuffer.bytes}');
    // print('bytesIn: $bytesIn');
    //   return true;
    // }());

    parserBuffer.receive(bytesIn);

    try {
      // while - potentially 1+ packets queued, do while HeaderStatus(isPacketComplete: false)
      while (parserBuffer.viewAsBytes.isNotEmpty) {
        // print('- parseHeader Loop Start: ${parserBuffer.bytes}');

        switch (parserBuffer.status) {
          case HeaderStatus(isStartValid: false):
            parserBuffer.seekStart();
          // print('parserBuffer seekStart(): ${parserBuffer.bytes}');

          case HeaderStatus(isIdValid: false):
            throw ProtocolException.meta;

          case HeaderStatus(isPacketComplete: true):
            parserBuffer.completePacket(); // set length for checksum operation
            // print('parserBuffer completePacket() ${parserBuffer.bytes} trailing ${parserBuffer.trailing}');
            switch (parserBuffer.status.isChecksumValid) {
              case true || null: // null when no checksum implemented
                /// pass on the packet, full buffer including
                _outputSink.add(parserBuffer.viewAsPacket); // data pointer is either from Link, or remainderBuffer
                /// transformed stream handles using same headerView before continuing
                parserBuffer.seekTrailing(); // if excess packets queued, this loops recursively.. todo

              case false:
                parserBuffer.seekTrailing();
                throw ProtocolException.checksum;
            }

          /// in case of [sync][sync], todo check before complete
          case HeaderStatus(isLengthValid: false):
            throw ProtocolException.meta;

          /// no recognizable id, or recognized as incomplete
          case HeaderStatus(isPacketComplete: false):
            assert(parserBuffer.viewLength < parserBuffer.packetClass.lengthMax); // should be caught by isLengthValid
            return;
        }
      }
    } on ProtocolException catch (e) {
      // unparsable error
      switch (e) {
        case ProtocolException.meta:
          parserBuffer.clear(); // ensure remainder buffer is cleared this way
        case ProtocolException.checksum:
      }
      print('PacketTransformer: ${e.message}');
      _outputSink.addError(e);
    } catch (e) {
      parserBuffer.clear();
      print(e);
    } finally {
      //  parserBuffer.seekTrailing(); alternatively, always start with 0 trailing, and seek after packet complete
      // print('- finally');
      // print('parserBuffer bytes ${parserBuffer.bytes}');
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
