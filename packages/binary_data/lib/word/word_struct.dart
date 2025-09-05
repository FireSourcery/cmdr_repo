import '../bits/bit_struct.dart';
import '../bytes/typed_field.dart';
import 'word.dart';

export '../bits/bit_struct.dart';
export '../bytes/typed_field.dart';
export 'word.dart';

/// [Bits]/[Word] + keys
/// [] Map operators returning [int]
///
/// effectively,
/// 8-byte [ByteData] backed by int, via
/// [BitStruct] enforcing byte aligned fields
///
/// Implementation centric Map, up to 8 bytes
/// serializaable as a single [int]
///
/// subclass to passthrough constructors for convienience
/// alternatively extension type WordStruct(BitsStruct _)
/// caller wrap inner constructor for const. WordStruct(Word())
abstract base class WordStruct<T extends WordField> extends ConstBitStruct<T> {
  const WordStruct(super.value) : super();

  // re-implementation of Word constructors for const
  // alternatively caller wrap
  // static const WordStruct a = SubWordStruct(Word(10));
  const WordStruct._of(int bits) : super(bits as Bits);

  const WordStruct.of32s(int ls32, [int ms32 = 0]) : this._of((ms32 << 32) | (ls32 & _mask32));

  const WordStruct.of16s(int ls16, [int upperLs16 = 0, int lowerMs16 = 0, int ms16 = 0]) : this.of32s((upperLs16 << 16) | (ls16 & _mask16), (ms16 << 16) | (lowerMs16 & _mask16));

  // assign with parameters in little endian order for byteLength
  const WordStruct.of8s(int lsb, [int lsb1 = 0, int lsb2 = 0, int lsb3 = 0, int msb3 = 0, int msb2 = 0, int msb1 = 0, int msb = 0])
    : this.of16s((lsb1 << 8) | (lsb & _mask8), (lsb3 << 8) | (lsb2 & _mask8), (msb2 << 8) | (msb3 & _mask8), (msb << 8) | (msb1 & _mask8));

  static const int _mask8 = 0xFF;
  static const int _mask16 = 0xFFFF;
  static const int _mask32 = 0xFFFFFFFF;

  ///
  // WordStruct.castBase(super.state) : super.castBase();

  int get byteLength => bits.byteLength;

  Word get word => Word(bits);

  // WordStruct<T> withBytes(int lsb, [int lsb1 = 0, int lsb2 = 0, int lsb3 = 0, int msb3 = 0, int msb2 = 0, int msb1 = 0, int msb = 0]) {
  //   return  ;
  // }
}

/// a field within a [WordStruct]
/// interface for including [TypedField<T>], [Enum]
/// type ensures bitmask is power of 2
abstract mixin class WordField<V extends NativeType> implements BitField, TypedField<V> {
  /// can be overridden with compile time constant
  @override
  Bitmask get bitmask => Bitmask.bytes(offset, size);
}
