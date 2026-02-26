import 'dart:collection';

import 'package:type_ext/struct.dart';

import 'basic_types.dart';

// available as mixin
// homogeneous fields struc + keys
mixin Serializable<K extends Enum, V> implements MapBase<K, V> {}

// abstract class EnumData<K extends Enum, V> with MapBase<K, V>, Structure<K, V> {}

// only necessary for mixed V type keys
abstract interface class SerializableKey<V> implements Enum, TypeKey<V> {}

// typedef SerializableData = Map<SerializableKey<dynamic>, Object?>;
// typedef SerializableData = Serializable<SerializableKey<dynamic>, Object?>;
typedef SerializableData<K extends SerializableKey<Object?>> = Serializable<K, Object?>;
// General mixin for keyed data structures
//  K extends Enum for serialization
// typedef DataStruct<K extends Field, V extends Object?> = Structure<K, V>;
// abstract class EnumData<K extends Enum, V> with MapBase<K, V>, Structure<K, V> {}
