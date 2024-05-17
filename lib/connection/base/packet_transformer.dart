import 'dart:async';

import 'package:meta/meta.dart';

import 'packet.dart';
import 'packet_handlers.dart';
import 'protocol.dart';

/// PacketRxHeaderParser
/// Header as Packet Control Block
/// Packet Meta Parser
/// handled by base module. different format use new class
/// implemented with shared Sync Header by default
///
abstract mixin class HeaderParser implements Packet {
  // PacketId? idOf(int intId); // factory constructor of enum id, returns
  PacketSyncId get nack;
  PacketSyncId get abort;
  PacketSyncId get ack;
  // final Set<PacketId> syncIds = {ack, nack, abort };
  // PacketId? get packetId => (idFieldOrNull != null) ? idOf(idFieldOrNull!) : null;

  // todo note buffer may be larger than configMax
  HeaderParser castBuffer(Uint8List bytes) => (castBytes(bytes) as HeaderParser);

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
}

/// determine complete, error, or wait
// ParseLength
// ParseId
// ParseChecksum
interface class HeaderStatus {
  HeaderStatus(this.view);
  HeaderStatus.of(this.view);
  @protected
  final HeaderParser view;

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

/// combine partial packets
class PacketTransformer extends StreamTransformerBase<Uint8List, Packet> implements EventSink<Uint8List> {
  PacketTransformer({required this.headerHandler}) : remainder = Uint8List(headerHandler.configLengthMax * 4); // may exceed 1 full length packet

  late final EventSink<Packet> _outputSink;
  final HeaderParser headerHandler;
  final Uint8List remainder; // remainder buffer, beginning of next incomplete packet
  int remainderIndex = 0; //previous remainder length

  @override
  void add(Uint8List bytesIn) {
    // assert(() {
    // print('');
    // print('---');
    // print('bytes in: $bytesIn');
    // return true;
    // }());

    if (remainderIndex == 0) {
      headerHandler.cast(bytesIn); // skip copying to buffer if received a complete packet
      // print('dataView from link: ${headerHandler.bytes}');
    } else {
      // print('dataView with remainder: ${remainder.getRange(0, remainderIndex)} $bytesIn');
      remainder.setAll(remainderIndex, bytesIn);
      headerHandler.cast(Uint8List.view(remainder.buffer, 0, remainderIndex + bytesIn.length));
    }

    try {
      // while - potentially 1+ packets queued
      while (headerHandler.bytes.isNotEmpty) {
        // print('- parseHeader Loop Start: ${headerHandler.bytes}');

        switch (headerHandler.parseHeader()) {
          case HeaderStatus(isStartValid: false):
            headerHandler.seekValidStart();
          // print('headerHandler removeUntilValidStart: ${headerHandler.bytes}');
          //set before throw // or ignore without throwing // throw ProtocolException.meta;
          case HeaderStatus(isIdValid: false):
            throw ProtocolException.meta;

          case HeaderStatus(isLengthValid: false):
            throw ProtocolException.meta;

          case HeaderStatus(isCompletePacket: true, :final packetLength):
            remainderIndex = 0; // mark remainder as processed
            // print('headerHandler isPacketComplete ${headerHandler.bytes}');
            final trailing = Uint8List.sublistView(headerHandler.bytes, packetLength!);
            headerHandler.completePacket(); // trim packet before checking checksum
            // print('headerHandler completePacket() ${headerHandler.bytes}');
            // may throw null check if invalid length not identified
            switch (headerHandler.parseHeader().isChecksumValid) {
              case true || null: // null when no checksum implemented
                /// pass on the packet
                _outputSink.add(headerHandler); // data pointer is either from Link, or remainderBuffer
                // transformed stream handles using same headerView before continuing
                headerHandler.castBytes(trailing); // trim packet before checking checksum
              // print('headerHandler trailing ${headerHandler.bytes}');

              case false:
                headerHandler.castBytes(trailing);
                throw ProtocolException.checksum;
            }

          /// no recognizable id, or recognized as incomplete
          case HeaderStatus(isCompletePacket: false || null):
            // over full packet length buffered
            if (remainderIndex >= headerHandler.configLengthMax) throw ProtocolException.meta;
            // remainder set to 0 if a single packet completed
            // do not continue to queue unprocessed remainder. e.g case of consecutive start chars
            // active if add runs once previously wihtout a complete packet
            // limitation: packet arrive in 2+ segments will be lost
            // to do use headerhandler trailing?
            if (remainderIndex != 0) {
              // print('stagnant remainder ${remainder.getRange(0, remainderIndex)}');
              // print('headerHandler: ${headerHandler.bytes}');
              assert(remainderIndex < headerHandler.length);
              headerHandler.castBytes(Uint8List.sublistView(headerHandler.bytes, remainderIndex)); // remove remainder index bytes from the front
              // print('headerHandler removed remainder: ${headerHandler.bytes}');
            }
            return;
        }
      }
      //alternatively set isPacketComplete, including checksum error, to copy buffer only
    } on ProtocolException catch (e) {
      switch (e) {
        // unparsable error
        // throw will flush link
        case ProtocolException.meta:
          headerHandler.clear(); // ensure remainder buffer is cleared this way
        case ProtocolException.checksum:
      }
      // print('Packet transformer: ' + e.message);
      rethrow;
    } catch (e) {
      headerHandler.clear();
      print(e);
    } finally {
      // print('- finally');
      // print('headerHandler ${headerHandler.bytes}');
      // print('remainder start: index $remainderIndex, ${remainder.getRange(0, remainderIndex)}');
      remainder.setAll(0, headerHandler.bytes);
      remainderIndex = headerHandler.length;
      // print('remainder end: index $remainderIndex, ${remainder.getRange(0, remainderIndex)}');
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
