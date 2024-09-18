import 'dart:typed_data';

import 'bits.dart';
import 'typed_data_ext.dart';

export 'bits.dart';

/// Effectively ByteData with a length of 8 bytes.
/// can be compile time constant, use as enum entry,
///  bits with byte constructors and byte granularity accessors
// extension type const Word(int bits) implements Bits, int {
/// must be standard class, so constructors can be inherited, and derived classes can be used as compile time constants
class Word {
  const Word(int value) : bits = value as Bits;

  // assign with parameters in little endian order for byteLength
  const Word.of8s(int lsb, [int lsb1 = 0, int lsb2 = 0, int lsb3 = 0, int msb3 = 0, int msb2 = 0, int msb1 = 0, int msb = 0])
      : this.of16s((lsb1 << 8) | (lsb & _mask8), (lsb3 << 8) | (lsb2 & _mask8), (msb2 << 8) | (msb3 & _mask8), (msb << 8) | (msb1 & _mask8));

  const Word.of16s(int ls16, [int upperLs16 = 0, int lowerMs16 = 0, int ms16 = 0]) : this.of32s((upperLs16 << 16) | (ls16 & _mask16), (ms16 << 16) | (lowerMs16 & _mask16));
  const Word.of32s(int ls32, [int ms32 = 0]) : this((ms32 << 32) | (ls32 & _mask32));

  // const Word.msb(int msb, int msb1, int msb2, int msb3, int lsb3, int lsb2, int lsb1, int lsb) : this.of8s(lsb, lsb1, lsb2, lsb3, msb3, msb2, msb1, msb);
  // const Word.msb16(int msb, int msb,  int lsb, int lsb)
  // const Word.msb32(int msb, int lmsb, int mlsb, int lsb)
  //     : assert(msb < 256 && lmsb < 256 && mlsb < 256 && lsb < 256),
  //       bits = (msb << 24 | lmsb << 16 | mlsb << 8 | lsb) as Bits;

  // const Word.byteSwap(int value) : this.of8s(value >> 56, value >> 48, value >> 40, value >> 32, value >> 24, value >> 16, value >> 8, value);

  // defaults to little endian for an arbitrary list of bytes, assume external
  // big endian will set first item as msb of 64-bits, fill missing bytes with 0
  //   e.g. for a value of 1, big endian, user must input <int>[0, 0, 0, 0, 0, 0, 0, 1], <int>[1] would be treated as 0x0100'0000'0000'0000
  // ByteBuffer, at least 8 bytes, in typed data format can skip copying to buffer
  Word.bytes(TypedData bytes, [Endian endian = Endian.little]) : this(bytes.toInt(endian));
  // Runes, take first 8 bytes
  Word.chars(Iterable<int> chars, [Endian endian = _stringEndian]) : this(chars.toBytes(8).toInt(endian));
  Word.string(String string) : this.chars(string.runes, _stringEndian);
  // Word.origin(ByteBuffer bytes, [int offset = 0, Endian endian = Endian.little]) : value = bytes.toInt(offset, endian);

  static const int sizeMax = 8;
  static const int _mask8 = 0xFF;
  static const int _mask16 = 0xFFFF;
  static const int _mask32 = 0xFFFFFFFF;
  static const Endian _stringEndian = Endian.little; // Must maintain consistency between fromString and toString. Select little endian to simplify discarding remainder

  final Bits bits;

// // auto trim length
// // Uint8List get bytes => toBytes(Endian.little);
// Uint8List get bytesLE => toBytes(Endian.little).trim(byteLength, Endian.little);
// Uint8List get bytesBE => toBytes(Endian.big).trim(byteLength, Endian.big);

  bool get isSet => (bits != 0);

  /// String
  // asString, as encoded, a copy is made but immutable
  Uint8List get _bytesString => bits.toBytes(_stringEndian);
  String get asString => _bytesString.toStringAsEncoded(0, bits.byteLength);

  // int operator [](int index) => byteAt(index);
  // void operator []=(int index, int value) => setByteAt(index, value);
}

extension BytesOfInt on int {
  /// TypedData Byte List operations
  // fixed size buffer then trim view with length likely better performance than iterative build with flex size BytesBuilder
  // bytes.length always returns 8 from new buffer
  // ByteData.get[Word] must use same endian
  ByteData toByteData([Endian endian = Endian.big]) => ByteData(8)..setUint64(0, this, endian);
  Uint8List toBytes([Endian endian = Endian.big]) => toByteData(endian).buffer.asUint8List();
  // trimmed
  Uint8List toBytesAs(Endian endian, [int? byteLength]) => toBytes(endian).trim(byteLength ?? this.byteLength, endian);

  /// String Char operations using Bits
  String charAsCode(int index) => String.fromCharCode(byteAt(index)); // 0x31 => '1'
  int modifyAsCode(int index, String char) => modifyByte(index, char.runes.single); // '1' => 0x31

  String charAsLiteral(int index, [bool isSigned = false]) => byteAt(index).toString(); // 1 => '1'
  int modifyAsLiteral(int index, String char) => modifyByte(index, int.parse(char)); // '1' => 1

  // alternatively iterate over bits
  String toStringAsEncoded([Endian endian = Endian.little]) => String.fromCharCodes(toBytes(endian), 0, byteLength);
}

extension TrimBytes on Uint8List {
  // following bytesOfInt
  // trimmed view sublist for copy
  // big endian trim leading. little endian trim trailing
  Uint8List trim(int wordLength, Endian endian) => switch (endian) { Endian.big => trimAsBE(wordLength), Endian.little => trimAsLE(wordLength), Endian() => throw StateError('Endian') };
  // todo typed data account fo element size
  // constructing trimAsBE back to Word will change value, as offset has change, alternatively parameterize with size/type
  Uint8List trimAsBE(int wordLength) => Uint8List.sublistView(this, lengthInBytes - wordLength);
  // constructing trimAsLE back to Word preserves value
  Uint8List trimAsLE(int wordLength) => Uint8List.sublistView(this, 0, wordLength);
}

// class MutableWord extends Word {
//   MutableWord(super.value);

//   // @override
//   // int value;
//   set value(int newValue) => value = newValue;
// }
