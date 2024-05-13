import 'package:recase/recase.dart';

import '../common/enum_struct.dart';
import 'typed_field.dart';
import 'word.dart';

export 'typed_field.dart';

/// [Word] with named fields
///  as mixin to pass Word constructors
abstract mixin class WordFields<T extends WordField> implements Word, EnumStruct<T, int> {
  const WordFields();

  // String? get varLabel;
  // List<T> get fields; // with Enum.values

  @override
  int operator [](T field) => field.valueOfInt(value);
  @override
  void operator []=(T field, int value) => throw UnsupportedError('NamedFields does not support assignment');
}

// abstract class WordFieldsBase<T extends WordField> = Word with WordFields<T>, EnumStruct<T, int>;

/// interface for including [TypedField<T>], [Enum]
abstract mixin class WordField<T extends NativeType> implements TypedField<T>, EnumField<int> {
  @override
  String get label => name.pascalCase;
  // @override
  // int call(WordFields host) => valueOfInt(host.value);
}
