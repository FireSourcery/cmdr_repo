import 'dart:collection';

import 'package:recase/recase.dart';

import '../common/enum_map.dart';
import 'typed_field.dart';
import 'word.dart';

export 'typed_field.dart';

/// [Word] with named fields
abstract class WordFields<T extends WordField> = Word with MapBase<T, int>, EnumMap<T, int>, WordFieldsMixin<T>;

/// interface for including [TypedField<T>], [Enum]
typedef WordField<T extends NativeType> = NamedField<T>;

abstract mixin class WordFieldsMixin<T extends WordField> implements Word, EnumMap<T, int> {
  const WordFieldsMixin();

  String? get name;
  // List<T> get fields; // with Enum.values

  (String, String) get asLabelPair => (name ?? '', toString());

  @override
  int operator [](T field) => field.valueOfInt(value);
  @override
  void operator []=(T field, int? value) => throw UnsupportedError('WordFields does not support assignment');
  @override
  void clear() => throw UnsupportedError('WordFields does not support clear');
}
 
/// e.g
// enum VersionFieldStandard<T extends NativeType> with TypedField<T> implements WordField<T> {
//   fix<Uint8>(0),
//   minor<Uint8>(1),
//   major<Uint8>(2),
//   optional<Uint8>(3),
//   ;

//   const VersionFieldStandard(this.offset);
//   @override
//   final int offset;
// }
