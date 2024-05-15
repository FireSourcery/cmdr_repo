import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cmdr/byte_struct.dart';

import 'typed_field.dart';

export 'dart:ffi';
export 'dart:typed_data';

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
/// a struct member
/// configuration for get TypedData segment from
class TypedOffset<T extends NativeType> extends TypedField<T> {
  const TypedOffset(this.offset);

  @override
  final int offset;
}

/// ByteStruct
/// Effectively TypedData as an abstract class with user defined fields.
///  implemented as wrapper since TypedData is final
// abstract   class ByteStruct<T extends ByteStruct<dynamic>> {
//   static const TypedOffset<Uint8> start = TypedOffset<Uint8>(0);
//   // List<TypedOffset> get members;

//   // TypedData.new
//   T buffer(int length) => (this..reference = Uint8List(length)) as T;

//   // TypedData.view
//   // Analogous to ByteData.sublistView but without configurable offset, as it is always inherited from the reference.
//   T cast(TypedData data) => (this..reference = data) as T;

//   static Uint8List nullPtr = Uint8List(0);

//   // alternatively this model holder size and offset with pointer to ByteBuffer
//   TypedData reference = nullPtr; // alternatively use late

//   int get size => reference.lengthInBytes; // view size, virtual size, independent of underlying buffer and offset

//   // extended to hold Typed conversion functions
//   ByteData asByteData() => reference.asByteData();
// }

// ByteStructFactory
// abstract class ByteStructFactory {
//   ByteStruct create();
// }
