import 'dart:collection';

import 'fixed_map.dart';



/// as tree?
// // abstract mixin class Field<E extends Field<dynamic, dynamic>, V> implements Map<E, V> {
// //   // factory Field.buffer() = FieldBuilder;

// //   List<E> get keys;
// //   List<E> get fields => keys;
// //   // the child class constructor
// //   // implicitly requires V to be nullable or defined with default value
// //   Field<E, V> initWith(Field<E, V?> map);

// //   // can be overridden to skip buffering for optimization
// //   Field<E, V> copyWithEntry(E key, V value) => initWith(FieldBuffer<E, V>(keys)..[key] = value);
// //   // Field<E, V> copyWithEntries(Iterable<MapEntry<E, V>> entries) => initWith(FieldBuffer<E, V>(keys).fillWithEntries(entries));
// // }
// abstract mixin class Field<V> implements Map<Field, V> {
//   // factory Field.buffer() = FieldBuilder;

//   String get name; // Enum.name

//   @override
//   V operator [](covariant Field key);

//   List<Field> get keys;
//   List<Field> get fields => keys;
//   // the child class constructor
//   // implicitly requires V to be nullable or defined with default value
//   Field<Field> initWith(Field<Field?> map);

//   // can be overridden to skip buffering for optimization
//   Field<Field> copyWithEntry(Field key, V value) => initWith(FieldBuffer<Field, V>(keys)..[key] = value);
//   // Field<E, V> copyWithEntries(Iterable<MapEntry<E, V>> entries) => initWith(FieldBuffer<E, V>(keys).fillWithEntries(entries));
// }

// // abstract mixin class NodeField<V extends Field> implements Field<V> {}

// abstract mixin class LeafField<V> implements Field<V> {
//   const LeafField();
//   Type get type => V;
//   bool compareType(Object? object) => object is V;

//   @override
//   V? operator [](covariant Field key) => throw UnimplementedError();
//   @override
//   void operator []=(Field key, V? value) => throw UnimplementedError();

//   // or should the implementation be here?
//   // V get(covariant Field fieldsMap);
//   // void set(covariant Field fieldsMap, V value);
//   // V modify(Field fieldsMap, V Function(V) modifier) => fieldsMap[this] = modifier(fieldsMap[this]);

//   // Field modify(Field fieldsMap, V value) => fieldsMap.copyWithEntry(this, value);

//   String get name;

//   // @override
//   // void clear() {}

//   // @override
//   // Field<Field> copyWithEntry(Field key, V value) {
//   //   throw UnimplementedError();
//   // }

//   // @override
//   // List<Field> get fields => throw UnimplementedError();

//   // @override
//   // Field<Field> initWith(Field<Field?> map) {}

//   // @override
//   // List<Field> get keys => throw UnimplementedError();

//   // @override
//   // V? remove(Object? key) {} // Enum.name
// }
 

 