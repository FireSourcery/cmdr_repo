import 'package:binary_data/bytes/typed_data_ext.dart';

import '../bits/bits.dart';
import '../bytes/typed_array.dart';

export '../bits/bits.dart';
export '../bytes/typed_array.dart';

/// [Word] - A register width variable.
/// Implementation of [Bits] with byte granularity constructors/accessors.
/// Effectively [ByteData] with a length of 8 bytes.
/// Can be compile time constant, use as enum entry
extension type const Word(int _value) implements Bits, int {
  const Word.of32s(int ls32, [int ms32 = 0]) : this((ms32 << 32) | (ls32 & _mask32));

  const Word.of16s(int ls16, [int upperLs16 = 0, int lowerMs16 = 0, int ms16 = 0]) : this.of32s((upperLs16 << 16) | (ls16 & _mask16), (ms16 << 16) | (lowerMs16 & _mask16));

  const Word.of8s(int lsb, [int lsb1 = 0, int lsb2 = 0, int lsb3 = 0, int msb3 = 0, int msb2 = 0, int msb1 = 0, int msb = 0])
    : this.of16s((lsb1 << 8) | (lsb & _mask8), (lsb3 << 8) | (lsb2 & _mask8), (msb2 << 8) | (msb3 & _mask8), (msb << 8) | (msb1 & _mask8));

  // const Word.value64(int msb, int msb1, int msb2, int msb3, int lsb3, int lsb2, int lsb1, int lsb) : this.of8s(lsb, lsb1, lsb2, lsb3, msb3, msb2, msb1, msb);
  // const Word.value32(int msb, int msb1, int msb2, int msb3) : this.of8s(0, 0, 0, 0, msb3, msb2, msb1, msb);

  // defaults to little endian for an arbitrary list of bytes, assume external
  // big endian will set first item as msb of 64-bits. caller fill missing bytes with 0
  //   e.g. for a value of 1, big endian, user must input <int>[0, 0, 0, 0, 0, 0, 0, 1], <int>[1] would be treated as 0x0100'0000'0000'0000
  Word.bytes(TypedData bytes, [Endian endian = Endian.little]) : this(bytes.toInt(endian));

  // as byte chars for now, take first 8 bytes
  Word.chars(Iterable<int> chars, [Endian endian = _stringEndian]) : this((Uint8List(8)..setAll(0, chars.take(8))).toInt(endian));

  // 1 unit width for now
  // take first length chars may or may not includ null terminator
  Word.string(String string, [int length = 8]) : this.chars(string.runes.take(string.length.clamp(0, 8)), _stringEndian);
  // Word.runes(Runes runes, [int? unitWidth = 1, Endian endian = _stringEndian]) : this();

  static const int sizeMax = 8;
  static const int _mask8 = 0xFF;
  static const int _mask16 = 0xFFFF;
  static const int _mask32 = 0xFFFFFFFF;
  static const Endian _stringEndian = Endian.little; // Must maintain consistency between fromString and toString. Select little endian to simplify discarding remainder

  Bits get bits => this;

  // fast accessors
  int get byte0 => this & _mask8;
  int get byte1 => (this >> 8) & _mask8;
  int get byte2 => (this >> 16) & _mask8;
  int get byte3 => (this >> 24) & _mask8;
  int get byte4 => (this >> 32) & _mask8;
  int get byte5 => (this >> 40) & _mask8;
  int get byte6 => (this >> 48) & _mask8;
  int get byte7 => (this >> 56) & _mask8;

  ////////////////////////////////////////////////////////////////////////////////
  /// Bytes Of Int
  /// cast [int] as [Word] for access
  ////////////////////////////////////////////////////////////////////////////////
  /// TypedData Byte List operations
  // converts singular register into bytes
  // todo with mask?

  // fixed size buffer then trim view with length likely better performance than iterative build with flex size BytesBuilder
  // bytes.length always returns 8 from new buffer
  // ByteData.get[Word] must use same endian
  ByteData toByteData([Endian endian = Endian.little]) => ByteData(8)..setUint64(0, this, endian);
  Uint8List toBytes([Endian endian = Endian.little]) => Uint8List.sublistView(toByteData(endian));

  // ToBytesTrimmed
  ByteData toByteDataAs(Endian endian, [int? byteLength]) => toByteData(endian).trimWord(byteLength ?? this.byteLength, endian);
  Uint8List toBytesAs(Endian endian, [int? byteLength]) => Uint8List.sublistView(toByteDataAs(endian, byteLength));

  // R toList<R extends TypedData>(Endian endian, [int? byteLength]) => toByteData(endian).trim(byteLength ?? this.byteLength, endian).sublistView<R>();

  /// String Char operations using Bits
  String charOfCode(int index) => String.fromCharCode(byteAt(index)); // 0x31 => '1'
  int withCharAsCode(int index, String char) => withByteAt(index, char.runes.single); // '1' => 0x31

  // num literal only
  String charOfLiteral(int index, [bool isSigned = false]) => byteAt(index).toString(); // 1 => '1'
  int withCharAsLiteral(int index, String char) => withByteAt(index, int.parse(char)); // '1' => 1

  String toCharAsCode() => String.fromCharCode(this);

  /// String
  // asString, as encoded, a copy is made but immutable
  // ignores null terminator
  Uint8List get _bytesString => toBytes(_stringEndian);
  String asString() => _bytesString.asString(0, _value.byteLength);
}

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
extension IntOfBytes on TypedData {
  // valueAt max size is 8, when lengthInBytes >= 8, toInt64 avoids copying buffer
  // int toInt([Endian endian = Endian.little]) => (lengthInBytes >= 8) ? ByteData.sublistView(this).getInt64(0, endian) : ByteData.sublistView(this).valueAt(0, lengthInBytes, endian);
  int toInt([Endian endian = Endian.little]) => ByteData.sublistView(this).toInt(endian);
}

extension SizedWord on ByteData {
  /// Word value for intervals not of pow2, e.g. 3 bytes, 5 bytes
  // allows non pow2 intervals. use case [2][3][3] stored in a int64
  // truncates if size > lengthInBytes, i.e. lengthInBytes the comparable ByteData.getInt
  // creates a new buffer
  // does not sign extend
  int valueAt(int byteOffset, int size, [Endian endian = Endian.little]) {
    assert(size <= 8);
    assert(byteOffset + size <= lengthInBytes, 'Read would exceed buffer bounds');

    final endianOffset = switch (endian) {
      Endian.big => 8 - size,
      Endian.little => 0,
      Endian() => throw StateError('Endian'),
    };
    return (Uint8List(8)..setAll(endianOffset, Uint8List.sublistView(this, byteOffset, byteOffset + size))).buffer.asByteData().getInt64(0, endian);
    // or iterate bytemask on this
  }

  // return switch (size) {
  //   1 => getUint8(0),
  //   2 => getUint16(0, endian),
  //   4 => getUint32(0, endian),
  //   8 => getInt64(0, endian),
  // };
  // on ByteData as it is the designated type for int conversion
  int toInt([Endian endian = Endian.little]) => (lengthInBytes >= 8) ? getInt64(0, endian) : valueAt(0, lengthInBytes, endian);

  // big endian trim leading. little endian trim trailing
  // asTrimmed, asTrimmedView
  ByteData trimWord(int wordLength, Endian endian) => switch (endian) {
    Endian.big => trimLeading(wordLength),
    Endian.little => trimTrailing(wordLength),
    Endian() => throw StateError('Endian'),
  };

  // trimLeading, trimTrailing
  // constructing trimAsBE back to Word will change value, unless offset is accounted for.
  ByteData trimLeading(int targetLength) => ByteData.sublistView(this, lengthInBytes - targetLength);
  // constructing trimAsLE back to Word preserves value
  ByteData trimTrailing(int targetLength) => ByteData.sublistView(this, 0, targetLength);
}

////////////////////////////////////////////////////////////////////////////////
// ///
// ////////////////////////////////////////////////////////////////////////////////
// // converts singular register into bytes
// extension BytesOfInt on int {
//   /// TypedData Byte List operations
//   // fixed size buffer then trim view with length likely better performance than iterative build with flex size BytesBuilder
//   // bytes.length always returns 8 from new buffer
//   // ByteData.get[Word] must use same endian
//   ByteData toByteData([Endian endian = Endian.little]) => ByteData(8)..setUint64(0, this, endian);
//   Uint8List toBytes([Endian endian = Endian.little]) => Uint8List.sublistView(toByteData(endian));

//   // todo with mask?
//   // ToBytesTrimmed
//   ByteData toByteDataAs(Endian endian, [int? byteLength]) => toByteData(endian).trimWord(byteLength ?? this.byteLength, endian);
//   Uint8List toBytesAs(Endian endian, [int? byteLength]) => Uint8List.sublistView(toByteDataAs(endian, byteLength));

//   // R toList<R extends TypedData>(Endian endian, [int? byteLength]) => toByteData(endian).trim(byteLength ?? this.byteLength, endian).sublistView<R>();

//   /// String Char operations using Bits
//   String charOfCode(int index) => String.fromCharCode(byteAt(index)); // 0x31 => '1'
//   int withCharAsCode(int index, String char) => withByteAt(index, char.runes.single); // '1' => 0x31

//   // num literal only
//   String charOfLiteral(int index, [bool isSigned = false]) => byteAt(index).toString(); // 1 => '1'
//   int withCharAsLiteral(int index, String char) => withByteAt(index, int.parse(char)); // '1' => 1

//   String toCharAsCode() => String.fromCharCode(this);

//   // char size 1 for now
//   String toStringAsCode([Endian endian = Endian.little, int charSize = 1]) => String.fromCharCodes(toBytes(endian), 0, byteLength);
// }
