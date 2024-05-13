import 'dart:collection';

import 'package:recase/recase.dart';

typedef StructEntry<K, V> = ({K field, V value});
typedef StructPair<K, V> = (K field, V value);

/// assigns key and label to Map-like classes
/// Enum keyed struct. auto gen names
abstract mixin class EnumStruct<T extends EnumField<V>, V> {
  const EnumStruct();

  // dynamic get value;

  String? get varLabel;
  List<T> get fields; // with Enum.values

//  (String, V)  get asLabeledPair ;

  Iterable<V> get values => fields.map((e) => this[e]);
  Iterable<String> get labels => fields.map((e) => e.label);

  V operator [](T field);
  void operator []=(T field, V value);

  // StructEntry<T, V> structEntry(T field) => (this[field] != null) ? (field: field, value: this[field]!) : null;
  StructEntry<T, V> structEntry(T field) => (field: field, value: this[field]);
  Iterable<StructEntry<T, V>> get structEntries => fields.map((e) => structEntry(e));

  StructPair<T, V> structPair(T field) => (field, this[field]);
  Iterable<StructPair<T, V>> get structPairs => fields.map((e) => structPair(e));

  // MapEntry<T, V> entry(T field);
  // Iterable<MapEntry<T, V>> get entries;

  Iterable<StructEntry<String, V>> get labeledValues => fields.map((e) => (field: e.label, value: this[e]));
  Iterable<(String, V)> get labeledValuePairs => fields.map((e) => (e.label, this[e]));
}

/// interface for including [Enum]
abstract mixin class EnumField<V> implements Enum {
  String get label => name.pascalCase;
  // V call(covariant EnumStruct<dynamic, V> host);
  // V get(covariant EnumStruct<dynamic, V> host);
  // void set(covariant EnumStruct<dynamic, V> host, V value);
  // dynamic get interface;
}

// class StructMap<T extends EnumField<V>, V> with MapBase<T, V> {
//   @override
//   V operator [](Object? key) {}

//   @override
//   void operator []=(T key, V value) {}

//   @override
//   void clear() {}

//   @override
//   // TODO: implement keys
//   Iterable<T> get keys => throw UnimplementedError();

//   @override
//   V? remove(Object? key) {}
// }
