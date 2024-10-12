import 'dart:collection';

import 'package:cmdr/common/enum_map.dart';
import 'package:meta/meta.dart';

/// immutable wrap + mixed values types
// abstract mixin class DataMap<T extends DataField<V>, V extends Object?> implements EnumMap<T, V> {
// alternatively allow V to to define restriction Object or Object?
abstract mixin class DataMap<T extends DataField<Object?>> implements EnumMap<T, Object?> {
  const DataMap();

  // casted as  parameter input
  // let V be defined by key
  // V _get<V>(covariant T key) => this[key] as V;
  // R get<R>(covariant T key) => key.callTyped<R>(<G>() => _get<G>(key) as R);

  // V get<V>(covariant T key) {
  //   // assert(key is DataField<V>);
  //   assert(key.type == V);
  //   return this[key] as V;
  // }

  R get<R>(covariant T key) => key.call(this) as R;

  @override
  void operator []=(covariant DataField<Object?> key, Object? value) => throw UnsupportedError("Cannot modify unmodifiable");

  @override
  void clear() => throw UnsupportedError("Cannot modify unmodifiable");

  // @override
  // DataMap<T, > copyWith() => this;
}

// typedef DataField<V> = TypedEnumKey<V>;
// keys with type effectively define memory layout
abstract mixin class DataField<V extends Object?> implements TypedEnumKey<V>, Enum {
  const DataField();
  V call(covariant DataMap<DataField<Object?>> map) {
    // assert(map.keys.contains(this));
    assert(map.keys[index] == this);
    return map[this] as V;
  }
}

// todo use regular class to simplify inheritance?
extension type const DataMapFactory<T extends DataField<Object?>>(List<T> keys) implements EnumMapFactory<DataMap<T>, T, Object?> {
  // EnumMapFactory<T, Object?> get _super => EnumMapFactory(keys);
  DataMap<T> fromBase(DataMap<T> state) => _DataMapDefault.fromBase(state);

  // DataMap<T> fromJson(Map<String, Object?> json) => _DataMapDefault.cast(EnumMapDefault.filled(keys, null));
  // @redeclare
  // DataMap<T> fromJson(Map<String, Object?> json) => _DataMapDefault.fromBase(_super.fromJson(json));
  // DataMap<T> fromJson1(Map<String, Object?> json) => fromJson(json);

  // @redeclare
  // DataMap<T> fromValues(Iterable<Object?> values) => _DataMapDefault.fromBase(_super.fromValues(values));
}

// alternatively with MapBase<K, Object?>, EnumMap<K, Object?>, DataMap<K>
abstract class DataMapBase<K extends DataField<Object?>> = MapBase<K, Object?> with EnumMap<K, Object?>, DataMap<K>;

// allow a stand alone DataMap without named accessors.
// ignore: missing_override_of_must_be_overridden
class _DataMapDefault<K extends DataField<Object?>> = EnumMapDefault<K, Object?> with DataMap<K>;

/// e.g
///

// a key to each field, with an generated string, use as json key; an type parameter, effectively describe the memory allocation requirements
enum PersonField<V extends Object> with TypedEnumKey<V>, DataField<V> {
  id<int>(),
  age<int>(),
  name<String>();
}

class Person extends DataMapBase<PersonField<Object>> {
  // static const DataMapFactory<PersonField<Object>> personFactory = DataMapFactory(PersonField.values);

  const Person(this.id, this.name, this.age);

  final String name;
  final int id;
  final int age;

  // the user side class only needs to provide a function to map the values of a known memory layout/interface to the user's class' memory layout
  // one point of interface to the base class
  // fromBase
  Person.fromBase(DataMap<PersonField> map)
      : id = map.get(PersonField.id),
        name = map.get(PersonField.name),
        age = map.get(PersonField.age);

  // and a function using a known interface access the fields of the user's class, maps ids to getters
  @override
  Object operator [](PersonField key) {
    return switch (key) { PersonField.id => id, PersonField.name => name, PersonField.age => age };
  }

  // in this case, we must go through a intermediary step of jsonMap -> known memory layout/interface -> user's class, at runtime.
  // where as code gen can directly map jsonMap -> user class, which is less cost during runtime. although this approach is in principle is the same as [StringBuffer]
  // however the code for mapping json directly to the user class, unique to each user class, would also require an expense of memory in ROM, arguable more expensive the intermediary buffer in RAM
  factory Person.fromJson(Map<String, Object?> json) {
    return Person.fromBase(const DataMapFactory(PersonField.values).fromJson(json));
    // return Person.fromBase(const DataMap.fromJson(PersonField.values, json));
  }

  @override
  List<PersonField<Object>> get keys => PersonField.values;

  @override
  Person copyWith({String? name, int? id, int? age}) {
    return Person(id ?? this.id, name ?? this.name, age ?? this.age);
  }

  // e.g.
  // without override allocates a small temporary buffer, length keys, or less using iterative search
  //  then either copyWith() allocating a Person,
  //  or a cast/wrap buffer allocating 1 source field, length 1, but this has to be implemented by user class
  // effectively EnumMapProxy<K, V>.field(this, key, value).copyWith()
  // Person updateAge(int age) => withField(PersonField.age, age).asSubtype();

//  Person withField(PersonField key, Object? value) => switch (key) { PersonField.id => copyWith(id: value), PersonField.name => copyWith(age: value), PersonField.age => copyWith(age: value) };

  // overriding default withX
  Person updateAge(int age) => copyWith(age: age);
}
