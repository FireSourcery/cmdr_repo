import 'package:recase/recase.dart';

import '../common/enum_struct.dart';
import 'typed_field.dart';
import 'word.dart';

export 'typed_field.dart';

/// [Word] with named fields
abstract mixin class NamedFields<T extends NamedField> implements Word, EnumStruct<T, int> {
  const NamedFields();

  @override
  int operator [](T field) => field.valueOfInt(value);
}

/// interface for including [TypedField<T>], [Enum]
abstract mixin class NamedField<T extends NativeType> implements TypedField<T>, EnumField<int> {
  @override
  String get label => name.pascalCase;
  @override
  int call(dynamic value) => valueOfInt(value as int);
}
