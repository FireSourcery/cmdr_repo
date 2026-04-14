import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../general/struct.dart';
import '../word/word.dart';
import 'typed_array.dart';
import 'typed_field.dart';

export 'typed_field.dart';
export 'typed_data_buffer.dart';
export 'typed_array.dart';
export 'typed_data_ext.dart';

// export 'dart:typed_data';

/// [ByteStruct] is a [TypedData] with keyed/named access to fields.
/// [TypedData] + [] Map operators returning [int]
/// keyed view
///   mixin keyed access for serialization map
///
/// Wrapper over extension type. see [StructData]
/// view ByteData or ByteStruct subtypes as base type. sufficent for iterative access.
extension type const ByteStruct<K extends ByteField>(ByteData _this) implements ByteData, StructData<K, int> {
  int get size => _this.lengthInBytes;
}

extension type const ByteForm<K extends ByteField>(List<K> _fields) implements StructForm<K, int> {
  ByteStruct<K> create() => ByteStruct<K>(ByteData(size));
  ByteStruct<K> cast(ByteData data) => ByteStruct<K>(data);
  int get size => _fields.map((e) => e.size).sum;
}

/// [ByteStructBase] — abstract base for user-defined byte struct subtypes.
abstract class ByteStructBase<S extends ByteStructBase<S, K>, K extends ByteField> with StructBase<S, K, int> {
  const ByteStructBase(this.byteData);

  // handle Array access
  // only primitive types are keyed (and included in serialization). array sizes individual define by subclass. e.g. payload
  // handled with extension on bytedata
  final ByteData byteData;

  ByteStruct<K> get data => byteData as ByteStruct<K>; // ByteData as base type of TypedData for immediate keyed access

  List<K> get keys; // a method that is the meta contents, fieldsList

  int get size => byteData.lengthInBytes;

  T arrayAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => byteData.arrayAt<T>(offset, length);
  T? arrayOrNullAt<T extends TypedDataList<int>>([int offset = 0, int? length]) => byteData.arrayOrNullAt<T>(offset, length);
}

/// [ByteField] - a Typed Offset into a ByteStruct and TypedData. Defines a field of a ByteStruct by its offset and type.
abstract mixin class ByteField<V extends NativeType> implements TypedField<V>, Field<int> {
  const factory ByteField(int offset) = _ByteField<V>;

  // handle for offsets > word length
  // call passing T
  // replaceable by ffi.Struct
  @override
  int getIn(ByteStruct<ByteField<V>> byteData) => byteData.wordAt<V>(offset);
  @override
  void setIn(ByteStruct<ByteField<V>> byteData, int value) => byteData.setWordAt<V>(offset, value);

  // not yet replaceable
  @override
  bool testAccess(ByteStruct<ByteField<V>> byteData) => end <= byteData.lengthInBytes;

  // or packet implements bytestruct base
  int? getInOrNull(ByteData byteData) => byteData.wordOrNullAt<V>(offset);
  bool setInOrNot(ByteData byteData, int value) => byteData.setWordOrNotAt<V>(offset, value);
}

class _ByteField<V extends NativeType> with TypedField<V>, ByteField<V> {
  const _ByteField(this.offset);

  @override
  final int offset;
}

// extension ByteFieldExtension on ByteField {
//   Word asWordOf(ByteStructBase struct) => Word(struct[this]);
// }
