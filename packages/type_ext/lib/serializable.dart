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

// abstract mixin class SerializableData<V> implements Map<Enum, V> {
//   const Serializable();
//   List<K> get keys; // Enum.values
//    V operator [](covariant K key);
//   void operator []=(covariant K key, V value);
// }

// abstract mixin class EnumSerializable {
//   // Subclass must provide the enum values (field IDs)
//   List<Enum> get fieldIds;
  
//   // Subclass must implement field setters/getters
//   void setField(Enum id, dynamic value);
//   dynamic getField(Enum id);
  
//   // Inheritable fromJson using enum pairing
//   void fromJson(Map<String, dynamic> json) {
//     for (final id in fieldIds) {
//       final key = id.name;  // Use enum.name as JSON key
//       if (json.containsKey(key)) {
//         setField(id, json[key]);
//       }
//     }
//   }
  
//   // Optional: toJson for completeness
//   Map<String, dynamic> toJson() {
//     return {for (final id in fieldIds) id.name: getField(id)};
//   }
// }
