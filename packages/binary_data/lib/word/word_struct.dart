import 'package:binary_data/binary_data.dart';

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
/// immutable only istead of wrapping BitStruct
///
/// Implementation centric Map, up to 8 bytes
/// serializable as a single [int]
///
/// subclass to passthrough constructors for convenience
/// alternatively extension type WordStruct(BitsStruct _)
/// caller wrap inner constructor for const. WordStruct(Word())
// abstract base class WordStruct<T extends WordField> extends BitStructBase<WordStruct<T>, T> {
// keep an data viewing interface
extension type const WordStruct<K extends WordField>(Word word) implements Word, Bits, Structure<K, int> {
  WordStruct.intializer(Map<WordField, int> map) : this(Bits.ofMap(map.map((key, value) => MapEntry(key.bitmask, value))) as Word);
  // int get byteLength => bits.byteLength;

  WordStruct<K> withField(K key, int value) => word.withBits(key.bitmask, value) as WordStruct<K>;
  WordStruct<K> withFields(Iterable<FieldEntry<K, int>> fields) => word.withEach(fields.map((e) => (e.key.bitmask, e.value))) as WordStruct<K>;
  WordStruct<K> withMap(Map<K, int> map) => word.withEach(map.entries.map((e) => (e.key.bitmask, e.value))) as WordStruct<K>;
}

extension type const WordForm<K extends WordField>(List<K> _fields) implements StructForm<K, int> {}

// extension type const BitInitializer<K extends WordField>(CoStructure<K, int> data) implements CoStructure<K, int>,   WordStruct<K> {}

abstract base class WordBase<T extends WordBase<T, K>, K extends WordField> with MapBase<K, int>, StructureBase<T, K, int> {
  const WordBase(this.word);
  const WordBase.value(int value) : word = value as WordStruct<K>;
  WordBase.intializer(Map<WordField, int> map) : word = WordStruct.intializer(map);

  const WordBase.withData(this.word); // same as default.

  //for now
  static const int sizeMax = 8;
  static const int _mask8 = 0xFF;
  static const int _mask16 = 0xFFFF;
  static const int _mask32 = 0xFFFFFFFF;
  const WordBase.of32s(int ls32, [int ms32 = 0]) : this.value((ms32 << 32) | (ls32 & _mask32));
  const WordBase.of16s(int ls16, [int upperLs16 = 0, int lowerMs16 = 0, int ms16 = 0]) : this.of32s((upperLs16 << 16) | (ls16 & _mask16), (ms16 << 16) | (lowerMs16 & _mask16));
  const WordBase.of8s(int lsb, [int lsb1 = 0, int lsb2 = 0, int lsb3 = 0, int msb3 = 0, int msb2 = 0, int msb1 = 0, int msb = 0])
    : this.of16s((lsb1 << 8) | (lsb & _mask8), (lsb3 << 8) | (lsb2 & _mask8), (msb2 << 8) | (msb3 & _mask8), (msb << 8) | (msb1 & _mask8));

  final WordStruct<K> word;

  @override
  List<K> get keys;

  @override
  Structure<K, int> get data => word as Structure<K, int>;

  @override
  void clear() {}

  @override
  int remove(covariant K key) {
    return 0;
  }

  T copyWithData(WordStruct<K> word);

  T withField(K key, int value) => copyWithData(word.withField(key, value));
  T withFields(Iterable<FieldEntry<K, int>> fields) => copyWithData(word.withFields(fields));
  T withMap(Map<K, int> map) => copyWithData(word.withMap(map));
}

/// a field within a [WordStruct]
/// interface for including [TypedField<T>], [Enum]
/// type ensures bitmask is power of 2
abstract mixin class WordField<V extends NativeType> implements Field<int>, TypedField<V> {
  /// can be overridden with compile time constant
  @override
  Bitmask get bitmask => Bitmask.bytes(offset, size);

  int getIn(Word struct) => struct.getBits(bitmask);
  void setIn(Word struct, int value) => throw UnsupportedError('Cannot modify unmodifiable');
  bool testAccess(Word struct) => bitmask.shift + bitmask.width <= 64;
  // bool testAccess(Word struct) => bitmask.shift + bitmask.width <= struct.bitLength;

  // @override
  // int getIn(BitData struct) => struct.getBits(bitmask);
  // @override
  // void setIn(BitData struct, int value) => struct.setBits(bitmask, value);
  // @override
  // bool testAccess(BitData struct) => bitmask.shift + bitmask.width <= struct.width;
}
