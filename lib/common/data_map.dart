import 'dart:collection';

import 'package:cmdr/common/fixed_map.dart';

// DataMap , named fields, <Object?> type, immutable

// keys with type effectively define memory layout
abstract mixin class DataField<V> implements Enum {
  const DataField();
  Type get type => V;
  bool compareType(Object? object) => object is V;
  V call(DataMap dataMap) => dataMap[this] as V;
}

/// Data as mixed value type maps
// immutable wrap + mixed values types
abstract mixin class DataMapBase<E extends DataField<Object?>> implements FixedMap<E, Object?> {
  const DataMapBase();

  // fill values from json
  S fromJson<S extends DataMap>(Map<String, Object?> json) {
    // for (final key in keys) {
    //   if (key.compareType(json[key.name])) this[key] = json[key.name];
    // }
    // return this as S;
    for (final key in keys) {
      if (!key.compareType(json[key.name])) throw FormatException('DataMap.fromJson: ${key.name} is not of type ${key.type}');
    }
    return fromMapByName(json);
  }

  Map<String, Object?> toJson() => toMapByName();

  @override
  void clear() => throw UnsupportedError('DataMap does not support clear');

  void operator []=(E key, Object? value);
  Object? operator [](E key);
  List<E> get keys;

  // DataMap copyWithEntry(E key, Object? value) => initWith(DataMapBuilder(keys).fillWithEntry(key, value));
}

abstract class DataMap<E extends DataField<Object?>> with MapBase<E, Object?>, FixedMap<E, Object?>, DataMapBase<E> {
  const DataMap();

  // DataMap<E> Function(DataMap<E> dataMap) get initWith;

  // overridden in builder.
  @override
  void operator []=(E key, Object? value) => UnsupportedError('DataMap does not support assignment');
}

// allow a stand alone DataMap without named accessors.
class _DataMap<E extends DataField<Object?>> extends DataMap<E> {
  const _DataMap._(this._keys, this._map);
  _DataMap(List<E> keys) : this._(keys, {for (final key in keys) key: null});

  final List<E> _keys;
  final Map<E, Object?> _map;
  @override
  Object? operator [](covariant E key) => _map[key];
  @override
  List<E> get keys => _keys;
}

// a builder surrogate for simplifying child class constructors
// allocate a map with keys
class DataMapBuilder<E extends DataField<Object?>> extends _DataMap<E> {
  const DataMapBuilder.cast(super._keys, super._map) : super._();
  DataMapBuilder(super.keys);

  @override
  void operator []=(E key, Object? value) => _map[key] = value;
}

// a key to each field, with an generated string, use as json key; an type parameter, effectively describe the memory allocation requirements
enum PersonField<V> with DataField<V> {
  id<int>(),
  age<int>(),
  name<String>();

  // void set(DataMap<PersonField> dataMap, V value) {
  //   switch (this) {
  //     case PersonField.id:
  //       dataMap.name = value;
  //     case PersonField.age:
  //       dataMap[this] = value;
  //     case PersonField.name:
  //       dataMap[this] = value;
  //   }
  // }
  // void modify(Person dataMap, V value) {
  //   switch (this) {
  //     case PersonField.id:
  //       dataMap.name = value;
  //     case PersonField.age:
  //       dataMap[this] = value;
  //     case PersonField.name:
  //       dataMap[this] = value;
  //   }
  // }
}

class Person extends DataMap<PersonField> {
  final String name;
  final int id;
  final int age;

  const Person(this.id, this.name, this.age);

  // the user side class only needs to provide a function to map the values of a known memory layout/interface to the user's class' memory layout
  Person.initWith(DataMap<PersonField> map)
      : id = PersonField.id(map), // map[PersonField.name] as V
        name = PersonField.name(map),
        age = PersonField.age(map);

  // and a function using a known interface access the fields of the user's class, maps ids to getters
  @override
  Object operator [](PersonField key) {
    return switch (key) { PersonField.id => id, PersonField.name => name, PersonField.age => age };
  }

  // in this case, we must go through a intermediary step of jsonMap -> known memory layout/interface -> user's class, at runtime.
  // where as code gen can directly map jsonMap -> user's class, which is less cost during runtime. although this approach is in principle is the same as [StringBuffer]
  factory Person.fromJson(Map<String, Object?> json) {
    return Person.initWith(DataMapBuilder(PersonField.values).fromJson(json));
  }

  @override
  List<PersonField> get keys => PersonField.values;

  // e.g. inherit copyWith from Base class.
  // Person updateAge(int age) => Person.initWith(DataMapBuilder.cast(keys, this).fillWithEntry(PersonField.age, age));

//   @override
//   DataMap<DataField<Object?>> Function(DataMap<DataField<Object?>> dataMap) get initWith => Person.initWith;
}
