import 'dart:collection';

import 'package:cmdr/common/enum_map.dart';
import 'package:meta/meta.dart';

import 'basic_types.dart';

/// EnumMap + mixed values types + immutable
@immutable
abstract mixin class DataMap<T extends DataField<Object?>> implements EnumMap<T, Object?> {
  const DataMap();

  dynamic get(covariant T key) => key.callWithType<dynamic>(<G>() => (this[key] as G));

  @override
  void operator []=(covariant DataField<Object?> key, Object? value) => throw UnsupportedError("Cannot modify unmodifiable");

  @override
  void clear() => throw UnsupportedError("Cannot modify unmodifiable");
}

// keys with type effectively define memory layout
abstract mixin class DataField<V extends Object?> implements TypedEnumKey<V> {
  const DataField();

  V valueFrom(covariant DataMap<DataField<Object?>> map) {
    assert(map.keys.contains(this));
    assert(map.keys[index] == this);
    return map[this] as V;
  }
}

// combine mixins 'with MapBase<K, Object?>, EnumMap<K, Object?>, DataMap<K>'
@immutable
abstract class DataMapBase<K extends DataField<Object?>> = MapBase<K, Object?> with EnumMap<K, Object?>, DataMap<K>;

// default DataMap without named accessors.
// ignore: missing_override_of_must_be_overridden
class _DataMapDefault<K extends DataField<Object?>> = EnumMapDefault<K, Object?> with DataMap<K>;

// DataMapFactory
extension type const DataClass<T extends DataField<Object?>>(List<T> keys) implements EnumMapFactory<DataMap<T>, T, Object?> {
  DataMap<T> castBase(DataMap<T> state) => _DataMapDefault.castBase(state);
}

/// e.g
///
// a key to each field, with an generated string, use as json key; an type parameter, effectively describe the memory allocation requirements
enum PersonField<V extends Object> with TypeKey<V>, TypedEnumKey<V>, DataField<V> {
  id<int>(),
  age<int>(),
  name<String>();
}

typedef Person1 = ({String name, int id, int age});

class Person extends DataMapBase<PersonField> {
  // static const DataClass<PersonField<Object>> personFactory = DataClass(PersonField.values);

  const Person(this.id, this.name, this.age);

  final String name;
  final int id;
  final int age;

  // the user side class only needs to provide a function to map the values of a known memory layout/interface to the user's class' memory layout
  Person.castBase(DataMap<PersonField> map)
      : id = map.get(PersonField.id),
        name = map.get(PersonField.name),
        age = map.get(PersonField.age);

  // and a function using a known interface access the fields of the user's class, maps ids to getters
  @override
  Object operator [](PersonField key) {
    return switch (key) {
      PersonField.id => id,
      PersonField.name => name,
      PersonField.age => age,
    };
  }

  Person.fromMap(Map<PersonField, Object?> map) : this.castBase(const DataClass(PersonField.values).fromMap(map));

  // in this case, as a provided default, we must go through a intermediary step of jsonMap -> known memory layout/interface -> user's class, at runtime.
  // where as code gen can directly map jsonMap -> user class, which is technically faster during runtime.
  // however the unique to each user class, would also incur larger code size as a trade off
  // in this case the additional buffer is a List of 3 references..
  factory Person.fromJson(Map<String, Object?> json) {
    return Person.castBase(const DataClass(PersonField.values).fromJson(json));
  }

  @override
  List<PersonField<Object>> get keys => PersonField.values;

  @override
  Person copyWith({String? name, int? id, int? age}) {
    return Person(id ?? this.id, name ?? this.name, age ?? this.age);
  }

  // inherited with buffering
  // Person withField(PersonField key, Object? value);
  // Person withEntries(Iterable<MapEntry<K, V>> newEntries);
  // Person withAll(Map<K, V> map);

  // optionally override
  Person withField(PersonField key, Object? value) {
    return switch (key) {
      PersonField.id => copyWith(id: value as int?),
      PersonField.name => copyWith(name: value as String?),
      PersonField.age => copyWith(age: value as int?),
    };
  }
}
