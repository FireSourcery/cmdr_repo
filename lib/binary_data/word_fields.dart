import 'dart:collection';
import 'dart:ffi';

import 'package:recase/recase.dart';

import '../common/enum_map.dart';
import 'typed_field.dart';
import 'word.dart';

/// [Bits] + operators <WordField, int> + [Bytes] up to 8 bytes
///
/// alternatively WordModel
/// [Word] with named fields
abstract class WordFields<T extends WordField> = Word with MapBase<T, int>, EnumMap<T, int>, WordFieldsMixin<T>;

/// interface for including [TypedField<T>], [Enum]
abstract interface class NamedField<T extends NativeType> implements TypedField<T>, Enum {}

/// a field within a Word, unlike BitField
/// interface for including [TypedField<T>], [Enum]
typedef WordField<T extends NativeType> = NamedField<T>;

abstract mixin class WordFieldsMixin<T extends WordField> implements Word, EnumMap<T, int> {
  const WordFieldsMixin();

  String? get name;
  // List<T> get fields; // with Enum.values

  // (String, String) get asLabelPair => (name ?? '', toString()); //split this

  @override
  int operator [](T field) => field.valueOfInt(value);
  @override
  void operator []=(T field, int? value) => throw UnsupportedError('WordFields does not support assignment');
  @override
  void clear() => throw UnsupportedError('WordFields does not support clear');
}
