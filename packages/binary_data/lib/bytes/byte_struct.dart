import 'package:meta/meta.dart';

import 'typed_array.dart';
import 'typed_field.dart';
import 'typed_data_buffer.dart';
import '../data/struct.dart';

export 'typed_array.dart';
export 'typed_field.dart';
export 'typed_data_buffer.dart';

/// [ByteStruct] is a [TypedData] with keyed/named access to fields.
/// [TypedData] + [] Map operators returning [int]
/// keyed view
///   mixin keyed access for serialization map
///
/// Wrapper over extension type. see [Structure]

/// view ByteData or ByteStruct subtypes as base type. sufficent for iterative access.
extension type const ByteStruct<K extends ByteField>(ByteData _this) implements ByteData, Structure<K, int> {
  int get length => _this.lengthInBytes;
}

extension type const ByteForm<K extends ByteField>(List<K> _fields) implements StructForm<K, int> {}

abstract class ByteStructBase<S extends ByteStructBase<S, K>, K extends ByteField> with StructureBase<S, K, int> {
  // const ByteStructBase._(this.data);
  const ByteStructBase(this.byteData);

  // handle Array access
  // only primitive types are keyed (and included in serialization). array sizes individual define by subclass. e.g. payload
  // handled with extension on bytedata
  @override
  final ByteData byteData;

  ByteStruct<K> get data => byteData as ByteStruct<K>; // ByteData as base type of TypedData for immediate keyed access

  List<K> get keys; // a method that is the meta contents, fieldsList

  int get length => byteData.lengthInBytes;
}

/// Typed Offset
abstract mixin class ByteField<V extends NativeType> implements TypedField<V>, Field<int> {
  const factory ByteField(int offset) = _ByteField<V>;

  // handle for offsets > word length
  // call passing T
  // Although handling of keyed access is preferable in the data source class.
  // T must handled in it's local scope. No type inference when passing `Field` to ByteData
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
