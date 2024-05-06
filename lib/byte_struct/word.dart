// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:collection';
import 'dart:typed_data';

import 'package:cmdr/byte_struct/byte_struct.dart';

/// Effectively ByteData with a length of 8 bytes.
/// can be compile time constant
class Word {
  const Word(this.value);
  const Word.byteSwap(int value) : this.value32(value, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF);

  const Word.value32(int msb, int lmsb, int mlsb, int lsb)
      : assert(msb < 256 && lmsb < 256 && mlsb < 256 && lsb < 256),
        value = msb << 24 | lmsb << 16 | mlsb << 8 | lsb;
  // const Word.value64(int msb, int lmsb, int mlsb, int lsb) : value = msb << 24 | lmsb << 16 | mlsb << 8 | lsb;

  // Runes or Uint8List
  Word.bytes(Iterable<int> bytes, [Endian endian = Endian.little])
      : assert(bytes.length <= 8, 'length <= 8'),
        value = bytes.toInt(endian);

  Word.string(String string) : this.bytes(string.runes.take(8), _defaultStringEndian);
  Word.cast(Word word) : value = word.value;

  final int value; // Using int as base. this is the only way to allow a const constructor. e.g. use in Enums. not possible with TypedData

  int get size => (value.bitLength / 8).ceil();

  static const Endian _defaultStringEndian = Endian.little; // just needs to be consistent

  Uint8List toBytes([Endian endian = Endian.big]) => value.toBytes(endian);

  // bytes.length always returns 8 from new buffer
  Uint8List get bytes => toBytes(Endian.big);
  Uint8List get bytesLE => toBytes(Endian.little);
  Uint8List get bytesBE => toBytes(Endian.big);
  Uint8List get bytesString => toBytes(_defaultStringEndian);

  // asString, as literally, a copy is made but immutable
  String get asString => bytesString.toStringAsEncoded(0, size);
  String get asStringTrimNulls => bytesString.toStringAsEncodedTrimNulls(0, size);

  // String inputs
  String charAsPrint(int index) => bytesString.charAsPrint(index); // 1 => '1'
  String charAsCode(int index) => bytesString.charAsCode(index); // 0x31 => '1'

  // copyWith
  Word modifyIndex(int index, int value) => Word.bytes(bytesString..[index] = value, _defaultStringEndian); // double buffers

  Word modifyAsPrint(int index, String value) => modifyIndex(index, int.parse(value)); // '1' => 1
  Word modifyAsCode(int index, String value) => modifyIndex(index, value.runes.single); // '1' => 0x31

  // toString as description
  @override
  String toString() => bytesString.toString();

  @override
  bool operator ==(covariant Word other) {
    if (identical(this, other)) return true;
    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  // Word copyWith({
  //   Iterable<int?> bytes,
  // }) {
  //   return Word.bytes(
  //     bytes ?? this.value,
  //   );
  // }
}

extension BytesOfInt on int {
  static ByteData byteDataOf(int value, [Endian endian = Endian.big]) => ByteData(8)..setInt64(0, value, endian);
  static Uint8List bytesOf(int value, [Endian endian = Endian.big]) => byteDataOf(value, endian).buffer.asUint8List();

  int get byteLength => (bitLength / 8).ceil();

  Uint8List toBytes([Endian endian = Endian.big]) => bytesOf(this, endian);
  Uint8List toBytesTrim([Endian endian = Endian.big]) => Uint8List.sublistView(toBytes(endian), 0, byteLength);
}

extension IntOfBytes on Iterable<int> {
  // defaults to little endian for an arbitrary list of bytes, assume external
  static int valueOf(Iterable<int> bytes, [Endian endian = Endian.little]) => (Uint8List(8)..setAll(0, bytes.take(8))).buffer.asByteData().getInt64(0, endian);

  int toInt([Endian endian = Endian.little]) => valueOf(this, endian);
}

// extension TypedDataViews on TypedData {
// }

extension ByteString on Uint8List {
  String toStringAsEncoded([int start = 0, int? end]) => String.fromCharCodes(this, start, end);
  String toStringAsEncodedTrimNulls([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  // String asStringAlphaNumeric([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  // String asStringNonNulls([int start = 0, int? end]) => toStringAsEncoded(start, end).replaceAll(String.fromCharCode(0), '');

  // Chars use array index
  String charAsPrint(int index) => this[index].toString(); // 1 => '1'
  String charAsCode(int index) => String.fromCharCode(this[index]); // 0x31 => '1'

  void modifyAsPrint(int index, String value) => this[index] = int.parse(value); // '1' => 1
  void modifyAsCode(int index, String value) => this[index] = value.runes.single; // '1' => 0x31
}
