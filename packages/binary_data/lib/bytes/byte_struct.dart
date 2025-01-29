import 'package:type_ext/basic_ext.dart';
import 'package:type_ext/enum_map.dart';
import 'package:type_ext/struct.dart';
import 'package:meta/meta.dart';

import 'typed_array.dart';
import 'typed_field.dart';
import 'typed_data_buffer.dart';
export 'typed_array.dart';
export 'typed_field.dart';
export 'typed_data_buffer.dart';

/// [TypedData] + [] Map operators returning [int]
/// ffi.Struct cannot access with OrNull methods
///   Union with Array functions, combines keyed access with array access
///
/// Exists only as an definition, extend to instantiate
///   alternatively `TypedStruct`
///
// the contents are not directly memory mapped, as this is only possible with ffi.Struct
// included is only the meta contents of ByteData,
/// extension type on ByteData cannot contain abstract methods. subclasses may contain additional abstract methods
///  or implement class interfaces
// cannot directly implement ByteData due to final class
extension type ByteStruct<K extends ByteField<NativeType>>(ByteData byteData) implements StructView<K, int>, ByteData {
  // List<K> get keys

  int get lengthMax => length; // in the immutable case
  int get length => byteData.lengthInBytes;

  int? endOf(int offset, int? length) => (length != null) ? length + offset : null;

  ByteData dataAt(int offset, [int? length]) => ByteData.sublistView(byteData, offset, endOf(offset, length));

  T arrayAt<T extends TypedData>(int offset, [int? length]) => byteData.asTypedArray<T>(offset, endOf(offset, length));
  T? arrayOrNullAt<T extends TypedData>(int offset, [int? length]) => byteData.asTypedArrayOrNull<T>(offset, endOf(offset, length));

  List<int> intArrayAt<T extends TypedData>(int offset, [int? length]) => byteData.asIntList<T>(offset, endOf(offset, length));
  List<int> intArrayOrEmptyAt<T extends TypedData>(int offset, [int? length]) => byteData.asIntListOrEmpty<T>(offset, endOf(offset, length));
}

// abstract mixin class ByteStruct<K extends ByteField> {
// //   const ByteStruct();
//   const ByteConstruct._(this.structData);
//   ByteConstruct.origin(ByteBuffer bytesBuffer, [int offset = 0, int? length]) : structData = ByteStruct(bytesBuffer.asByteData(offset, length));
//   ByteConstruct(TypedData typedData, [int offset = 0, int? length]) : structData = ByteStruct(ByteData.sublistView(typedData, offset, offset + (length ?? 0)));
//   @protected
//   ByteData get byteData; // ByteData as base type of TypedData for immediate keyed access

//   int get lengthMax => length; // in the immutable case
//   int get length => byteData.lengthInBytes;

//   // Unconstrained type keys
//   @protected
//   int get(ByteField key) => key.getIn(byteData);
//   @protected
//   void set(ByteField key, int value) => key.setIn(byteData, value);
//   @protected
//   int? getOrNull(ByteField key) => key.getInOrNull(byteData);
//   @protected
//   bool setOrNot(ByteField key, int value) => key.setInOrNot(byteData, value);

//   // Keyed Field access
//   int operator [](K key) => key.getIn(byteData);
//   void operator []=(K key, int value) => key.setIn(byteData, value);

//   // replaced by ffi.Struct
//   int field(K key) => key.getIn(byteData);
//   void setField(K key, int value) => key.setIn(byteData, value);

//   bool testBounds(K key) => key.end <= length;

//   // not yet replaceable
//   int? fieldOrNull(K key) => key.getInOrNull(byteData);
//   bool setFieldOrNot(K key, int value) => key.setInOrNot(byteData, value);
//   // ByteStruct withField(K key, int value) => ; // if byteData content is unmodifiable, return new instance

//   // Array access
//   // only primitive types are keyed, custom sizes individual define by subclass
//   // return array, alternatively allow key to be of pointer/array type and switch on type

//   ByteData dataAt(int offset, [int? length]) => ByteData.sublistView(byteData, offset, length);

//   T arrayAt<T extends TypedData>(int offset, [int? length]) => byteData.asTypedArray<T>(offset, length);
//   T? arrayOrNullAt<T extends TypedData>(int offset, [int? length]) => byteData.asTypedArrayOrNull<T>(offset, length);

//   List<int> intArrayAt<T extends TypedData>(int byteOffset) => byteData.asIntList<T>(byteOffset);
//   List<int> intArrayOrEmptyAt<T extends TypedData>(int byteOffset) => byteData.asIntListOrEmpty<T>(byteOffset);

//   // dynamic buildAs<V>(V values);
//   // V parseAs<V>(V values);

//   // dynamic setAs<T extends ByteStruct, V>(ByteStructCaster<T> caster, V values) => caster(byteData).build(values, this);
//   // V getAs<R extends ByteStruct, V>(ByteStructCaster<R> caster, [dynamic  stateMeta]) => caster(byteData).parse(this, stateMeta);

//   // ByteStruct copyWith(TypedData typedData) => caster(typedData);
// }

abstract mixin class ByteField<V extends NativeType> implements TypedField<V>, Field<int> {
  const factory ByteField(int offset) = _ByteField<V>;

  // replaced by ffi.Struct
  // getThis
  @override
  int getIn(ByteData byteData) => byteData.wordAt<V>(offset);
  @override
  void setIn(ByteData byteData, int value) => byteData.setWordAt<V>(offset, value);
  // not yet replaceable
  @override
  bool testBoundsOf(ByteData byteData) => end <= byteData.lengthInBytes;
  @override
  int? getInOrNull(ByteData byteData) => byteData.wordOrNullAt<V>(offset);
  @override
  bool setInOrNot(ByteData byteData, int value) => byteData.setWordOrNotAt<V>(offset, value);
}

class _ByteField<V extends NativeType> with TypedField<V>, ByteField<V> {
  const _ByteField(this.offset);

  @override
  final int offset;

  @override
  int get index => throw UnimplementedError();
}

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
// typedef ByteStructCreator<T> = T Function([TypedData typedData]);
// typedef ByteStructCaster<T> = T Function(TypedData typedData);

// Factory
// class variables, handler, config
// meta info of(ByteStruct) operators
// T does not directly extend ByteStruct to allow for composed types; with abstract methods, additional properties
//  the only requirement is T is the result of TypedData
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

  // Map<K, int> mapOf(ByteStruct<K> struct) => {for (var key in keys) key: struct[key]};
}

// ignore: missing_override_of_must_be_overridden
abstract class ByteConstruct<T> {
  const ByteConstruct._(this.structData);
  ByteConstruct.origin(ByteBuffer bytesBuffer, [int offset = 0, int? length]) : structData = ByteStruct(bytesBuffer.asByteData(offset, length));
  ByteConstruct(TypedData typedData, [int offset = 0, int? length]) : structData = ByteStruct(ByteData.sublistView(typedData, offset, offset + (length ?? 0)));

  final ByteStruct structData;

  ByteStructClass<T, ByteField<NativeType>> get structClass;

  // @override
  // int operator [](covariant ByteField<NativeType> key) => structData[key];
  // @override
  // void operator []=(covariant ByteField<NativeType> key, int value)  => structData[key] = value;
  // @override
  // void clear()  => structData.clear();
  // @override
  // List<ByteField<NativeType>> get keys => structClass.keys;
  // @override
  // int remove(covariant ByteField<NativeType> key)  => structData.remove(key);

  // @override
  // ByteStruct<K> copyWith() => this;
}

// typedef StructCaster<T> = T Function(TypedData typedData);

/// buffer type
/// for partial view
// T as ffi.Struct caster or ByteStruct caster
// wrapper around ffi.Struct or extend ByteStructBase
class ByteStructBuffer<T> extends TypedDataBuffer {
  ByteStructBuffer._(super._bufferView, this.structCaster)
      : bufferAsStruct = structCaster(_bufferView),
        super.of();

  // caster for persistent view
  ByteStructBuffer.caster(TypedDataCaster<T> structCaster, int size) : this._(Uint8List(size), structCaster);

  // ByteStructBuffer(ByteStructClass<T, ByteField> structClass, [int? size]) : this.caster(structClass.caster, size ?? structClass.lengthMax);

  // final ByteStructClass<T> structClass;
  @protected
  final TypedDataCaster<T> structCaster; // need to retain this?
  /// `full Struct view` using a main struct type, max length buffer, with keyed fields, build functions unconstrained.
  @protected
  final T bufferAsStruct;

  // check bounds with struct class
  T get viewAsStruct => structCaster(viewAsBytes); // try partial view

  /// `view as ByteStruct`
  /// view as `length available` in buffer, maybe a partial or incomplete view
  /// nullable accessors in effect, length is set in contents
  S viewAs<S>(TypedDataCaster<S> caster) {
    return caster(viewAsBytes);
  }

  /// `view as ffi.Struct`
  /// view as `full length`, including invalid data.
  /// a buffer backing larger than all potential calls is expected to be allocated at initialization
  ///
  S? viewBufferAsStruct<S extends Struct>(TypedDataCaster<S> caster) {
    return caster(bufferAsBytes);
  }

  // build(dynamic values) => throw UnimplementedError();
  // parse(dynamic values) => throw UnimplementedError();
}
