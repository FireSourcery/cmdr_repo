import 'dart:typed_data';

import 'bits.dart';
import 'typed_data_ext.dart';

export 'bits.dart';

/// [Word] - A register width variable.
/// Implementation of [Bits] with byte granularity constructors/accessors.
/// Effectively [ByteData] with a length of 8 bytes.
/// can be compile time constant, use as enum entry
extension type const Word(int _value) implements Bits, int {
  /// must be standard class for constructors to be passed to child as const, and derived classes can be used as compile time constants
  /// alternatively defer most distant child class to call Word constructor
  // class Word {
  // const Word(int value) : bits = value as Bits;

  const Word.of32s(int ls32, [int ms32 = 0]) : this((ms32 << 32) | (ls32 & _mask32));

  const Word.of16s(int ls16, [int upperLs16 = 0, int lowerMs16 = 0, int ms16 = 0])
      : this.of32s(
          (upperLs16 << 16) | (ls16 & _mask16),
          (ms16 << 16) | (lowerMs16 & _mask16),
        );

  const Word.of8s(int lsb, [int lsb1 = 0, int lsb2 = 0, int lsb3 = 0, int msb3 = 0, int msb2 = 0, int msb1 = 0, int msb = 0])
      : this.of16s(
          (lsb1 << 8) | (lsb & _mask8),
          (lsb3 << 8) | (lsb2 & _mask8),
          (msb2 << 8) | (msb3 & _mask8),
          (msb << 8) | (msb1 & _mask8),
        );

  // const Word.value64msb(int msb, int msb1, int msb2, int msb3, int lsb3, int lsb2, int lsb1, int lsb) : this.of8s(lsb, lsb1, lsb2, lsb3, msb3, msb2, msb1, msb);
  // const Word.value32msb(int msb, int msb1, int msb2, int msb3) : this.of8s(0, 0, 0, 0, msb3, msb2, msb1, msb);

  // const Word.byteSwap(int value) : this.of8s(value >> 56, value >> 48, value >> 40, value >> 32, value >> 24, value >> 16, value >> 8, value);

  // defaults to little endian for an arbitrary list of bytes, assume external
  // big endian will set first item as msb of 64-bits. caller fill missing bytes with 0
  //   e.g. for a value of 1, big endian, user must input <int>[0, 0, 0, 0, 0, 0, 0, 1], <int>[1] would be treated as 0x0100'0000'0000'0000
  // if byteBuffer is at least 8 bytes, skip copying to buffer, otherwise copies to a new buffer
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

  Bits get bits => this;

  // Uint8List toBytes([Endian endian = Endian.big]) => toByteData(endian).buffer.asUint8List();
  // Uint8List toBytesAs(Endian endian, [int? byteLength]) => toByteData(endian).trim(byteLength ?? this.byteLength, endian).buffer.asUint8List();

  // List<int>   numList(unitLength) => toBytes(Endian.little);

  // // auto trim length
  // Uint8List get bytes => toBytes(Endian.little);
  // Uint8List get bytesLE => value.toBytes(Endian.little).trim(byteLength, Endian.little);
  // Uint8List get bytesBE => value.toBytes(Endian.big).trim(byteLength, Endian.big);

  /// String
  // asString, as encoded, a copy is made but immutable
  Uint8List get _bytesString => _value.toBytes(_stringEndian);
  String asString() => _bytesString.toStringAsCode(0, _value.byteLength);

  // int operator [](int index) => byteAt(index);
  // void operator []=(int index, int value) => setByteAt(index, value);
}

extension BytesOfInt on int {
  /// TypedData Byte List operations
  // fixed size buffer then trim view with length likely better performance than iterative build with flex size BytesBuilder
  // bytes.length always returns 8 from new buffer
  // ByteData.get[Word] must use same endian
  ByteData toByteData([Endian endian = Endian.little]) => ByteData(8)..setUint64(0, this, endian);
  ByteData toByteDataAs(Endian endian, [int? byteLength]) => toByteData(endian).trim(byteLength ?? this.byteLength, endian);

  Uint8List toBytes([Endian endian = Endian.big]) => toByteData(endian).sublistView();
  Uint8List toBytesAs(Endian endian, [int? byteLength]) => Uint8List.sublistView(toByteData(endian).trim(byteLength ?? this.byteLength, endian));

  // R toList<R extends TypedData>(Endian endian, [int? byteLength]) => toByteData(endian).trim(byteLength ?? this.byteLength, endian).sublistView<R>();

  /// String Char operations using Bits
  String charAsCode(int index) => String.fromCharCode(byteAt(index)); // 0x31 => '1'
  int withCharAsCode(int index, String char) => withByteAt(index, char.runes.single); // '1' => 0x31

  // num literal only
  String charAsLiteral(int index, [bool isSigned = false]) => byteAt(index).toString(); // 1 => '1'
  int withCharAsLiteral(int index, String char) => withByteAt(index, int.parse(char)); // '1' => 1

  // toCharAsCode
  String toCharAsCode() => String.fromCharCode(this);
  // alternatively iterate over bits
  // toStringAsCode
  String toStringAsCode([Endian endian = Endian.little, int charSize = 1]) => String.fromCharCodes(Uint8List.sublistView(toByteData(endian)), 0, byteLength);
}

// on ByteData as it is the designated type for int conversion
extension TrimByteData on ByteData {
  // big endian trim leading. little endian trim trailing
  // asTrimmed, asTrimmedView
  ByteData trim(int wordLength, Endian endian) => switch (endian) { Endian.big => trimAsBE(wordLength), Endian.little => trimAsLE(wordLength), Endian() => throw StateError('Endian') };

  // constructing trimAsBE back to Word will change value, unless offset is accounted for.
  ByteData trimAsBE(int wordLength) => ByteData.sublistView(this, lengthInBytes - wordLength);
  // constructing trimAsLE back to Word preserves value
  ByteData trimAsLE(int wordLength) => ByteData.sublistView(this, 0, wordLength);
}

////////////////////////////////////////////////////////////////////////////////
/// Word value for intervals not of pow2
////////////////////////////////////////////////////////////////////////////////
// IntOfBytes
extension SizedWord on TypedData {
  // caller assert(lengthInBytes >= 8)
  int toInt64([Endian endian = Endian.little]) => buffer.asByteData().getInt64(offsetInBytes, endian); // equivalent to ByteData.sublistView(this).getInt64(0, endian)

  // creates a new buffer
  // caller assert(lengthInBytes < 8)
  // when lengthInBytes > 8, toInt64 avoids copying buffer
  // allows non pow2 intervals. use case [2][3][3] stored in a int64
  int valueAt(int byteOffset, int size, [Endian endian = Endian.little]) {
    assert(size <= 8);
    final endianOffset = switch (endian) { Endian.big => 8 - size, Endian.little => 0, Endian() => throw StateError('Endian') };
    return (Uint8List(8)..setAll(endianOffset, Uint8List.sublistView(this, byteOffset, size))).toInt64(endian);
    // return (TypedList(8)..copy(this)).toInt64(endian);
  }

  int toInt([Endian endian = Endian.little]) => (lengthInBytes >= 8) ? toInt64(endian) : valueAt(0, lengthInBytes, endian);
}
