import 'package:cmdr_common/basic_types.dart';

import 'typed_array.dart';
import 'typed_field.dart';
export 'typed_array.dart';
export 'typed_field.dart';

// todo merge packet, keyed typed data

/// [TypedData] + [] Map operators returning [int]
/// combines keyed access with array-like access
/// need for fieldValueOrNull
/// effectively packet without header/payload context
/// alternatively ArrayStruct
abstract mixin class ByteStruct<K extends TypedField<NativeType>> /* implements EnumMap<K , V> */ {
  const ByteStruct();
  ByteData get byteData;

  int get length => byteData.lengthInBytes;

  // int wordAt<V extends NativeType>(int offset) => byteData.wordAt<V>(offset);
  // void setWordAt<V extends NativeType>(int offset, int value) => byteData.setWordAt<V>(offset, value);
  // int? wordAtOrNull<V extends NativeType>(int offset) => byteData.wordAtOrNull<V>(offset);

  // Unconstrained type keys
  int field(TypedField key) => key.valueOf(byteData);
  void setField(TypedField key, int value) => key.setValueOf(byteData, value);
  int? fieldOrNull(TypedField key) => key.valueOrNullOf(byteData);

  // Constrained type keys
  int? operator [](K key) => fieldOrNull(key);
  // void operator []=(K key, int value) => key.setValueOf(byteData, value);

  // only primitive types are keyed, custom sizes individual define by subclass
  // todo determine use null or empty
  // return array, alternatively allow key to be of pointer/array type and switch on type
  ByteData dataAt(int offset, [int? length]) => ByteData.sublistView(byteData, offset, length);
  T arrayAt<T extends TypedData>(int offset, [int? length]) => byteData.asTypedArray<T>(offset, length);
  List<int> intArrayAt<T extends TypedData>(int byteOffset) => byteData.asIntList<T>(byteOffset);

  // dynamic setAs<T extends ByteStruct, V>(ByteStructCaster<T> caster, V values) => caster(bytes).build(values, this);
  // V getAs<R extends ByteStruct, V>(ByteStructCaster<R> caster, [dynamic  stateMeta]) => caster(bytes).parse(this, stateMeta);
}

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
// typedef ByteStructCreator<T> = T Function([TypedData typedData]);
typedef ByteStructCaster<T> = T Function(TypedData typedData);

// Abstract Factory
// abstract mixin class ByteStructClass {
//  List<T> keys
//   int get lengthMax;
//   // Endian get endian;
//   ByteStructBase cast(TypedData typedData);
// }

// extension type const ByteStructClass<T>(List<T> keys) /* implements EnumMapFactory<BitField<T>, T, int>  */ {
// BitStruct castBase(BitsMap<T, int> base) {
//   return switch (base) {
//     MutableBitsMapBase() => MutableBitStructWithKeys(keys, base.bits),
//     ConstBitsMapBase() => ConstBitStructWithKeys(keys, base.bits),
//     BitsMap() => throw StateError(''),
//   };
// }

// // alternatively default constructors can return partial implementation without Keys/MapOperator
// BitStruct<T> create([int value = 0, bool mutable = true]) {
//   return switch (mutable) {
//     true => MutableBitStructWithKeys(keys, Bits(value)),
//     false => ConstBitStructWithKeys(keys, Bits(value)),
//   };
// }

// // enum map by default copies into an array
// BitStruct<T> fromValues(Iterable<int> values, [bool mutable = true]) {
//   return create(Bits.ofIterables(keys.bitmasks, values), mutable);
// }

// BitStruct<T> fromMap(List<T> keys, Map<T, int> map, [bool mutable = true]) {
//   return create(Bits.ofEntries(map.bitmaskEntries), mutable);
// }
// }

// effectively TypedData, with a constructor
// cannot extended TypedData, need to add constructor to extension on TypedData
// not a mixin to pass parent constructors, on non ffi.Struct type
class ByteStructBase extends ByteStruct {
  const ByteStructBase._(this.byteData);
  ByteStructBase(TypedData bytes, [int offset = 0, int? length]) : byteData = ByteData.sublistView(bytes, offset, offset + (length ?? 0));
  // ByteStructBase.origin(ByteBuffer bytesBuffer, [int offset = 0, int? length]) : bytes = Uint8List.view(bytesBuffer, offset, length ?? bytesBuffer.lengthInBytes - offset);

  @override
  final ByteData byteData;
}

////////////////////////////////////////////////////////////////////////////////
/// List values
/// TypedData Cat Conversion
////////////////////////////////////////////////////////////////////////////////
/// Effectively moving up ByteBuffer layer, to TypedData view segment accounting for offset
extension GenericSublistView on TypedData {
  int get end => offsetInBytes + lengthInBytes; // index of last byte + 1

  // for case of ByteData
  // int get length => lengthInBytes ~/ elementSizeInBytes;

  TypeKey<TypedData> get typeKey {
    return switch (this) {
      Uint8List() => const TypeKey<Uint8List>(),
      Uint16List() => const TypeKey<Uint16List>(),
      Uint32List() => const TypeKey<Uint32List>(),
      Int8List() => const TypeKey<Int8List>(),
      Int16List() => const TypeKey<Int16List>(),
      Int32List() => const TypeKey<Int32List>(),
      ByteData() => const TypeKey<ByteData>(),
      _ => throw UnimplementedError(),
    };
  }

  TypeRestrictedKey<TypedData, TypedData> get typeRestrictedKey {
    return switch (this) {
      Uint8List() => const TypeRestrictedKey<Uint8List, TypedData>(),
      Uint16List() => const TypeRestrictedKey<Uint16List, TypedData>(),
      Uint32List() => const TypeRestrictedKey<Uint32List, TypedData>(),
      Int8List() => const TypeRestrictedKey<Int8List, TypedData>(),
      Int16List() => const TypeRestrictedKey<Int16List, TypedData>(),
      Int32List() => const TypeRestrictedKey<Int32List, TypedData>(),
      ByteData() => const TypeRestrictedKey<ByteData, TypedData>(),
      _ => throw UnimplementedError(),
    };
  }

  // R callAsThis<R>(R Function<G extends TypedData>() callback) => typeKey.callWithRestrictedType(callback);

  // offset uses type of 'this', not R type.
  R asTypedArray<R extends TypedData>([int typedOffset = 0, int? end]) => TypedArray<R>.cast(this, typedOffset, end).asThis; // return empty list if offset > length by default?
  R? asTypedArrayOrNull<R extends TypedData>([int typedOffset = 0, int? end]) => (typedOffset * elementSizeInBytes < lengthInBytes) ? asTypedArray<R>(typedOffset, end) : null;

  // orEmpty by default?
  /// [TypedIntList]/[IntArray]
  List<int> asIntList<R extends TypedData>([int typedOffset = 0, int? end]) => IntArray<R>.cast(this, typedOffset, end).asThis;
  List<int> asIntListOrEmpty<R extends TypedData>([int typedOffset = 0, int? end]) => (typedOffset * elementSizeInBytes < lengthInBytes) ? asIntList<R>(typedOffset, end) : const <int>[];

  TypedData? _local<G extends TypedData>() => asTypedArrayOrNull<G>();

  // sublistView as 'this' type
  TypedData? seek(int index) => typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => asTypedArrayOrNull<G>(index));
  // TypedData? seek1(int index) => TypedArray.cast(this, index);

  // IntList only
  String asString() => typeRestrictedKey.callWithRestrictedType(<G extends TypedData>() => asIntListOrEmpty<G>()).asString();
}

/// buffer types
///
/// update with packet
// abstract mixin class ByteStructMutable<T> {
//   late Uint8List _bytes;
//   late T _struct;

//   Uint8List get bytes => _bytes;
//   @protected
//   set bytes(Uint8List value) => _bytes = value;

//   // Uint8List get _byteBuffer; //alternatively use length value
//   set length(int value) => bytes = Uint8List.view(bytes.buffer, bytes.offsetInBytes, value);
// }

// // wrapper around ffi.Struct or  extend ByteStructBase
// class ByteStructBuffer<T> with ByteStructMutable {
//   // ByteStruct._(this._struct, this.bytes) : bytes = _struct.asTypedList;
//   // ByteStruct(StructConstructor<T> structConstructor) : this._(structConstructor());
//   ByteStructBuffer._(this._struct, this._byteBuffer) : _bytes = _byteBuffer;
//   ByteStructBuffer(StructConstructor<T> structConstructor, Uint8List buffer) : this._(structConstructor(buffer), buffer);
//   ByteStructBuffer.size(StructConstructor<T> structConstructor, int size) : this(structConstructor, Uint8List(size));

//   final Uint8List _byteBuffer; // internal buffer of known struct size
//   final T _struct; // holds full view, max length buffer, with named fields
//   Uint8List _bytes; // holds truncated view, mutable length

//   // @override
//   // Uint8List get bytes => _bytes;

//   // @override
//   // @protected
//   // set bytes(Uint8List value) => _bytes = value;
//   T get struct => _struct; // struct view is always full length, including out of set view range

//   // update view length via new view
//   // Uint8List.`view` on buffer to exceed struct view length. sublistView will not exceed current length
//   int get length => bytes.length;
//   set length(int totalLength) => _bytes = Uint8List.view(bytes.buffer, bytes.offsetInBytes, totalLength);

//   void clear() => length = 0;

//   void copyBytes(Uint8List dataIn) {
//     assert(dataIn.length <= bytes.buffer.lengthInBytes - bytes.offsetInBytes); // minus offset if view does not start at buffer 0, in inheritance case
//     length = dataIn.length;
//     bytes.setAll(0, dataIn);
//   }

//   void addBytes(Uint8List dataIn) {
//     // assert(dataIn.length <= bytes.buffer.lengthInBytes - bytes.offsetInBytes); // minus offset if view does not start at buffer 0, in inheritance case
//     final currentLength = bytes.length;
//     length = currentLength + dataIn.length;
//     bytes.setAll(currentLength, dataIn);
//   }
// }
