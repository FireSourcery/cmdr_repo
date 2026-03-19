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
extension type const ByteStruct<K extends ByteField>(ByteData _this) implements Structure<K, int> {
  int get length => _this.lengthInBytes;
}

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
  int getIn(ByteData byteData) => byteData.wordAt<V>(offset);
  @override
  void setIn(ByteData byteData, int value) => byteData.setWordAt<V>(offset, value);

  // not yet replaceable
  @override
  bool testAccess(ByteData byteData) => end <= byteData.lengthInBytes;

  // or packet implements bytestruct base
  int? getInOrNull(ByteData byteData) => byteData.wordOrNullAt<V>(offset);
  bool setInOrNot(ByteData byteData, int value) => byteData.setWordOrNotAt<V>(offset, value);
}

class _ByteField<V extends NativeType> with TypedField<V>, ByteField<V> {
  const _ByteField(this.offset);

  @override
  final int offset;
}

///

// optionally move to packet for now

/// T is [ByteStruct] or [ffi.Struct]
typedef TypedDataCaster<T> = T Function(TypedData typedData);
// typedef StructCaster<T> = T Function(TypedData typedData);
// typedef StructCreator<T> = T Function([TypedData typedData]);

/// buffer type
/// for partial view
// T as ffi.Struct caster or ByteStruct caster
// wrapper around ffi.Struct or extend ByteStructBase
class ByteStructBuffer<T> extends TypedDataBuffer {
  ByteStructBuffer._(super._bufferView, this.structCaster) : bufferAsStruct = structCaster(_bufferView), super.of();

  // caster for persistent view
  ByteStructBuffer.caster(TypedDataCaster<T> structCaster, int size) : this._(Uint8List(size), structCaster);

  // ByteStructBuffer(ByteStructClass<T, ByteField> structClass, [int? size]) : this.caster(structClass.caster, size ?? structClass.lengthMax);
  // final ByteStructClass<T> structClass;

  /// `full Struct view` using a main struct type, max length buffer, with keyed fields, build functions unconstrained.
  @protected
  final T bufferAsStruct;
  @protected
  final TypedDataCaster<T> structCaster; // need to retain this?

  // check bounds with struct class
  // try partial view
  T get viewAsStruct => structCaster(viewAsBytes);

  /// `view as ByteStruct`
  /// view as `length available` in buffer, maybe a partial or incomplete view
  /// nullable accessors in effect, length is set in contents
  S viewAs<S>(TypedDataCaster<S> caster) => caster(viewAsBytes);

  /// `view as ffi.Struct` must be on full length or Struct.create will throw
  /// view as `full length`, `including invalid data.`
  /// a buffer backing larger than all potential calls is expected to be allocated at initialization
  S? viewBufferAsStruct<S extends Struct>(TypedDataCaster<S> caster) => caster(bufferAsBytes);

  // build(dynamic values) => throw UnimplementedError();
  // parse(dynamic values) => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////

// Factory
// class variables, handler, config
// with abstract methods, additional properties
// meta info of(ByteStruct) operators
// T does not directly extend ByteStruct to allow for composed types;
// the only requirement is T is the result of TypedData
class ByteStructClass<T, K extends ByteField<NativeType>> {
  const ByteStructClass({required this.lengthMax, required this.endian, required this.keys, required this.caster});

  final int lengthMax;
  final Endian endian;
  final List<K> keys; // todo
  final TypedDataCaster<T> caster;

  T? cast(TypedData typedData) {
    // if (typedData.lengthInBytes < lengthMax) return null;
    return caster(typedData);
  }

  T create() => caster(ByteData(lengthMax));
}
