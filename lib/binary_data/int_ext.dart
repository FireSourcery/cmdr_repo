import 'dart:ffi';
import 'dart:typed_data';

import 'package:cmdr/binary_data/bitmask.dart';

/// Implementation in int primitive, wrapper include
// function of a single number, extend object method over top level math functions
extension BinaryOfInt on int {
  /// Bit operations
  int bitsAt(int offset, int width) => Bitmask(offset, width).read(this);
  int modifyBits(int offset, int width, int value) => Bitmask(offset, width).modify(this, value);
  // void setBitsAt(int offset, int width, int value) => Bitmask(offset, width).modify(this, value);

  int bitAt(int index) => Bitmask.bit(index).read(this);
  int modifyBit(int index, int value) => Bitmask.bit(index).modify(this, value);
  // void setBitAt(int index, int value) => Bitmask.bit(index).modify(this, value);

  /// skip ByteData buffer for a direct segment
  int bytesAt(int index, int size) => Bitmask.bytes(index, size).read(this);
  int modifyBytes(int index, int size, int value) => Bitmask.bytes(index, size).modify(this, value);

  int byteAt(int index) => Bitmask.byte(index).read(this);
  int modifyByte(int index, int value) => Bitmask.byte(index).modify(this, value);

  bool boolAt(int index) => Bitmask.bit(index).read(this) != 0;
  int modifyBool(int index, bool value) => Bitmask.bit(index).modify(this, value ? 1 : 0);

  /// TypedData Byte List operations
  int get byteLength => (bitLength / 8).ceil();
  // int get byteLength => ((bitLength - 1) ~/ 8) + 1;

  // fixed size buffer then trim view with length likely better performance than iterative build with flex size BytesBuilder
  static ByteData _fromInt(int value, [Endian endian = Endian.big]) => ByteData(8)..setUint64(0, value, endian);
  // returns as 8 bytes
  ByteData toByteData([Endian endian = Endian.big]) => _fromInt(this, endian);
  Uint8List toBytes([Endian endian = Endian.big]) => _fromInt(this, endian).buffer.asUint8List();
  // trimmed
  Uint8List toBytesAs(Endian endian, [int? byteLength]) => toBytes(endian).trim(byteLength ?? this.byteLength, endian);

  /// String
  String charAsCode(int index) => String.fromCharCode(byteAt(index)); // 0x31 => '1'
  int modifyAsCode(int index, String char) => modifyByte(index, char.runes.single); // '1' => 0x31

  String charAsValue(int index, [bool isSigned = false]) => byteAt(index).toString(); // 1 => '1'
  int modifyAsValue(int index, String char) => modifyByte(index, int.parse(char)); // '1' => 1
}

// move to typed_data_ext.dart if relevant for non int cases
extension TrimBytes on TypedData {
  // following bytesOfInt
  // trimmed view sublist for copy
  // big endian trim leading. little endian trim trailing
  Uint8List trim(int wordLength, Endian endian) => switch (endian) { Endian.big => trimAsBE(wordLength), Endian.little => trimAsLE(wordLength), Endian() => throw UnsupportedError('Endian') };
  // constructing trimAsBE back to Word will change value, as offset has change, alternatively parameterize with size/type
  Uint8List trimAsBE(int wordLength) => Uint8List.sublistView(this, lengthInBytes - wordLength);
  // constructing trimAsLE back to Word preserves value
  Uint8List trimAsLE(int wordLength) => Uint8List.sublistView(this, 0, wordLength);

  // use sublist for unmodifiable case
  Uint8List modifyByte(int index, int value) => Uint8List.sublistView(this).sublist(0)..[index] = value;
}
