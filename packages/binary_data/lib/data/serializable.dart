import 'dart:collection';

import 'struct.dart';

// available as mixin
// homogeneous fields struct + keys
mixin Serializable<K extends Enum, V> implements MapBase<K, V> {
  List<K> get keys;
}

// abstract class EnumData<K extends Enum, V> with MapBase<K, V>, Structure<K, V> {}

// only necessary for mixed V type keys
abstract interface class SerializableKey<V> implements Enum {
  // Type get type => T;

  // bool isSubtype<S>() => this is TypeKey<S>; // if (TypeKey<T> is TypeKey<S>)
  // bool isSupertype<S>() => TypeKey<S>() is TypeKey<T>;
  // bool isExactType<S>() => S == T;
  // bool get isNullable => null is T;

  // bool compareType(Object? object) => object is T;
  // bool isTypeOf(Object? object) => object is T;
}

typedef SerializableData<K extends SerializableKey> = Serializable<K, Object?>;
// General mixin for keyed data structures
//  K extends Enum for serialization
// typedef DataStruct<K extends Field, V extends Object?> = Structure<K, V>;
// abstract class EnumData<K extends Enum, V> with MapBase<K, V>, Structure<K, V> {}
