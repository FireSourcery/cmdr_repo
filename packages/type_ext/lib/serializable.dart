import 'dart:collection';

import 'basic_types.dart';

// available as mixin
// homogeneous fields
typedef Serializable<K extends Enum, V> = MapBase<K, V>;

// only necessary for mixed V type keys
abstract interface class SerializableKey<V> implements Enum, TypeKey<V> {}

// typedef SerializableData = Map<SerializableKey<dynamic>, Object?>;
// typedef SerializableData = Serializable<SerializableKey<dynamic>, Object?>;
typedef SerializableData<K extends SerializableKey<Object?>> = Serializable<K, Object?>;
