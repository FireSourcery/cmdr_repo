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
  // as byte chars for now, take first 8 bytes
  Word.chars(Iterable<int> chars, [Endian endian = _stringEndian]) : this(IntArray<Uint8List>.from(chars, 8).toInt(endian));

  // 1 unit width for now
  // Word.runes(Runes runes, [int? unitWidth = 1, Endian endian = _stringEndian]) : this();
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

  // List<int> numList(unitLength) => toBytes(Endian.little);

  // auto trim length
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

/// alternatively, as standard class for constructors to be inherited as const, and sub classes can be used as compile time constants
/// alternatively, defer until instance creation
// abstract class WordBase extends BitsBase {
//   const WordBase.of32s(int ls32, [int ms32 = 0]) : _value = Word.of32s(ls32, ms32);
//   const WordBase.of16s(int ls16, [int upperLs16 = 0, int lowerMs16 = 0, int ms16 = 0]);
//   const WordBase.of8s(int lsb, [int lsb1 = 0, int lsb2 = 0, int lsb3 = 0, int msb3 = 0, int msb2 = 0, int msb1 = 0, int msb = 0]);

//   final Word _value;
// }

////////////////////////////////////////////////////////////////////////////////
/// Word value for intervals not of pow2
////////////////////////////////////////////////////////////////////////////////
extension IntOfBytes on TypedData {
  // valueAt max size is 8, when lengthInBytes >= 8, toInt64 avoids copying buffer
  int toInt([Endian endian = Endian.little]) => (lengthInBytes >= 8) ? ByteData.sublistView(this).getInt64(0, endian) : ByteData.sublistView(this).valueAt(0, lengthInBytes, endian);

  // Word toWord([Endian endian = Endian.little]) => toInt(endian) as Word;
}

// converts singular register into bytes
extension BytesOfInt on int {
  /// TypedData Byte List operations
  // fixed size buffer then trim view with length likely better performance than iterative build with flex size BytesBuilder
  // bytes.length always returns 8 from new buffer
  // ByteData.get[Word] must use same endian
  ByteData toByteData([Endian endian = Endian.little]) => ByteData(8)..setUint64(0, this, endian);
  Uint8List toBytes([Endian endian = Endian.little]) => Uint8List.sublistView(toByteData(endian));

  // todo with mask?
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

  // char size 1 for now
  String toStringAsCode([Endian endian = Endian.little, int charSize = 1]) => String.fromCharCodes(toBytes(endian), 0, byteLength);
}

extension SizedWord on ByteData {
  // allows non pow2 intervals. use case [2][3][3] stored in a int64
  // truncates if size > lengthInBytes, i.e. lengthInBytes the comparable ByteData.get[Int]
  // creates a new buffer
  // does not sign extend
  // move this to constructor? Word
  int valueAt(int byteOffset, int size, [Endian endian = Endian.little]) {
    assert(size <= 8);
    final endianOffset = switch (endian) { Endian.big => 8 - size, Endian.little => 0, Endian() => throw StateError('Endian') };
    return (Uint8List(8)..setAll(endianOffset, Uint8List.sublistView(this, byteOffset, byteOffset + size))).buffer.asByteData().getInt64(0, endian);
    // or iterate bytemask on this
  }

  // on ByteData as it is the designated type for int conversion
  // big endian trim leading. little endian trim trailing
  // asTrimmed, asTrimmedView
  ByteData trimWord(int wordLength, Endian endian) => switch (endian) { Endian.big => trimLeading(wordLength), Endian.little => trimTrailing(wordLength), Endian() => throw StateError('Endian') };

  // trimLeading, trimTrailing
  // constructing trimAsBE back to Word will change value, unless offset is accounted for.
  ByteData trimLeading(int targetLength) => ByteData.sublistView(this, lengthInBytes - targetLength);
  // constructing trimAsLE back to Word preserves value
  ByteData trimTrailing(int targetLength) => ByteData.sublistView(this, 0, targetLength);
}
