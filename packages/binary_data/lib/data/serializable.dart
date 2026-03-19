import 'package:binary_data/data/enum_map.dart';

import 'struct.dart';

export 'enum_map.dart';

// mixin in 1 step for serialization
// provide toMap or implements MapBase and duplicate code until combine mixin is support

// mixin toMap<K extends Enum, V>
// mixin Serializable<S extends Serializable<S, K>, K extends SerializableKey<Object?>> on Object implements StructureBase<S, K, Object?> {
// does nto subtype
mixin Serializable<K extends SerializableKey<Object?>> on Object implements StructureBase<Serializable<K>, K, Object?> {
  List<K> get keys;

  /// Proxy to allow the same keys
  Structure<K, dynamic> get data => this as Structure<K, dynamic>; // data passed to Keys
  Map<String, Object?> toJson() => toMap().toJson();

  // static Serializable<K extends SerializableKey<Object?>> fromJson<S,K>(Map<K, Object?> values)
  // {
  //  EnumMap.fromJson(keys, values);
  // }
  //
  // static S fromJson<S extends Serializable<S, K>, K extends SerializableKey<Object?>>(Map<String, Object?> json) {
  //  user registry
  // }

  // S copyWith(Map<K, Object?> values) {}

  // duplicate code until combine mixin is support
  dynamic operator [](covariant K key) => key.getIn(data);
  void operator []=(covariant K key, dynamic value) => data[key] = value;
  dynamic? fieldOrNull(K key) => data.fieldOrNull(key);
  bool trySetField(K key, dynamic value) => data.trySetField(key, value); // trySetField
  FieldEntry<K, dynamic> fieldEntry(K key) => (key: key, value: this[key]);
  StructForm<K, dynamic> get _type => StructForm<K, dynamic>(keys);
  Map<K, dynamic> toMap() => _type.map(data);

  Iterable<dynamic> get fields => data.fields(keys); //valuesOf
  Iterable<FieldEntry<K, dynamic>> get fieldEntries => data.fieldEntries(keys); //entriesOf
}

// extension SerializableBase on StructureBase<dynamic, SerializableKey, dynamic> {
//   Map<String, Object?> toJson() => toMap().toJson();
// }

// [NamedField]
abstract interface class SerializableKey<V> implements Enum, Field<V> {}

extension SerializableKeys<K extends SerializableKey<Object?>> on StructForm<K, Object?> {
  Structure<K, Object> fromJson(Map<String, Object?> map) {
    return CoStructure(EnumMapFactory<K>(fields).fromJson(map)); // validat then maep
  }
}

// return an object of type Serializable and StructureBase for caller map to 
// class _Serializable<K extends SerializableKey<Object?>> extends StructMap<K, dynamic> implements Serializable<K> {
//   const _Serializable();

//   @override
//   Serializable<K> copyWith() {
//     // TODO: implement copyWith
//     throw UnimplementedError();
//   }

//   @override
//   // TODO: implement keys
//   List<K> get keys => throw UnimplementedError();
  
//   @override
//   // TODO: implement _type
//   StructureType<K, dynamic> get _type => throw UnimplementedError();
  
//   @override
//   Map<String, Object?> toJson() {
//     // TODO: implement toJson
//     throw UnimplementedError();
//   }
// }
