import 'dart:ffi';
import 'dart:typed_data';

import 'package:cmdr/binary_data/bitmask.dart';

extension type const Bits(int value) implements int {
  // const Bits.zero() : value = 0;
  // const Bits.one() : value = 1;
  // const Bits.allOnes() : value = _allOnes;
  // const Bits.allZeros() : value = _allZeros;
  // alternatively extension on Iterable<Enum>
  // Bits.ofMap(Map<Enum, bool> map) : value = map.entries.fold<int>(0, (previous, entry) => previous.modifyBool(entry.key.index, entry.value));
  // // return flags.foldIndexed<int>(0, (index, previous, element) => previous.modifyBool(index, element) );
  // Bits.ofBools(Iterable<bool> flags) : value = flags.fold<int>(0, (previous, element) => (previous << 1) | (element ? 1 : 0));

  // width value pairs
  Bits.fromWidth(Map<int, int> map) : value = Bitmasks.fromWidths(map.keys).apply(map.values);

  set value(int newValue) => value = newValue;

  // int bitsAt(int offset, int width) => value.bitsAt(offset, width);
  // int modifyBits(int offset, int width, int value) => this.value.modifyBits(offset, width, value);
  void setBitsAt(int offset, int width, int value) => this.value = modifyBits(offset, width, value);

  // int bitAt(int index) => value.bitAt(index);
  // int modifyBit(int index, int value) => this.value.modifyBit(index, value);
  void setBitAt(int index, int value) => this.value = modifyBit(index, value);

  // bool boolAt(int index) => value.boolAt(index);
  // int modifyBool(int index, bool value) => this.value.modifyBool(index, value);
  void setBoolAt(int index, bool value) => this.value = modifyBool(index, value);

  // int byteAt(int index) => value.byteAt(index);
  // int modifyByte(int index, int value) => this.value.modifyByte(index, value);
  void setByteAt(int index, int value) => this.value = modifyByte(index, value);

  // int bytesAt(int index, int size) => value.bytesAt(index, size);
  // int modifyBytes(int index, int size, int value) => this.value.modifyBytes(index, size, value);
  void setBytesAt(int index, int size, int value) => this.value = modifyBytes(index, size, value);

  // int get byteLength => value.byteLength;
  bool get isSet => (value != 0);

  // static const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;
  // static const int _smiBits = 62;
  // static const int _allZeros = 0;
  // static const int _allOnes = kMaxUnsignedSMI;

  // void reset([bool fill = false]) => value = fill ? _allOnes : _allZeros;
}

// function of a single number, object method over top level math functions
extension BinaryOfInt on int {
  /// Bit operations
  int bitsAt(int offset, int width) => Bitmask.bits(offset, width).read(this);
  int modifyBits(int offset, int width, int value) => Bitmask.bits(offset, width).modify(this, value);

  int bitAt(int index) => Bitmask.bit(index).read(this);
  int modifyBit(int index, int value) => Bitmask.bit(index).modify(this, value);

  /// skip TypedData buffer
  int bytesAt(int index, int size) => Bitmask.bytes(index, size).read(this);
  int modifyBytes(int index, int size, int value) => Bitmask.bytes(index, size).modify(this, value);

  int byteAt(int index) => Bitmask.byte(index).read(this);
  int modifyByte(int index, int value) => Bitmask.byte(index).modify(this, value);

  bool boolAt(int index) => Bitmask.bit(index).read(this) != 0;
  int modifyBool(int index, bool value) => Bitmask.bit(index).modify(this, value ? 1 : 0);

  int get byteLength => (bitLength / 8).ceil();
  // int get byteLength => ((bitLength - 1) ~/ 8) + 1;

  /// String Char operations using Bits
  String charAsCode(int index) => String.fromCharCode(byteAt(index)); // 0x31 => '1'
  int modifyAsCode(int index, String char) => modifyByte(index, char.runes.single); // '1' => 0x31

  String charAsValue(int index, [bool isSigned = false]) => byteAt(index).toString(); // 1 => '1'
  int modifyAsValue(int index, String char) => modifyByte(index, int.parse(char)); // '1' => 1

  // alternatively iterate over bits
  String toStringAsEncoded([Endian endian = Endian.little]) => String.fromCharCodes(toBytes(endian), 0, byteLength);

  /// TypedData Byte List operations
  // fixed size buffer then trim view with length likely better performance than iterative build with flex size BytesBuilder
  // returns as 8 bytes
  // ByteData.get[Word] must use same endian
  ByteData toByteData([Endian endian = Endian.big]) => ByteData(8)..setUint64(0, this, endian);
  Uint8List toBytes([Endian endian = Endian.big]) => toByteData(endian).buffer.asUint8List();
  // trimmed
  Uint8List toBytesAs(Endian endian, [int? byteLength]) => toBytes(endian).trim(byteLength ?? this.byteLength, endian);
}

// move to typed_data_ext.dart if relevant for non int cases
extension TrimBytes on Uint8List {
  // following bytesOfInt
  // trimmed view sublist for copy
  // big endian trim leading. little endian trim trailing
  Uint8List trim(int wordLength, Endian endian) => switch (endian) { Endian.big => trimAsBE(wordLength), Endian.little => trimAsLE(wordLength), Endian() => throw UnsupportedError('Endian') };
  // todo typed data account fo elementsize
  // constructing trimAsBE back to Word will change value, as offset has change, alternatively parameterize with size/type
  Uint8List trimAsBE(int wordLength) => Uint8List.sublistView(this, lengthInBytes - wordLength);
  // constructing trimAsLE back to Word preserves value
  Uint8List trimAsLE(int wordLength) => Uint8List.sublistView(this, 0, wordLength);

  // use sublist for unmodifiable case
  // Uint8List modifyByte(int index, int value) => Uint8List.sublistView(this).sublist(0)..[index] = value;
}
