import 'package:binary_data/binary_data.dart';
import 'package:binary_data/data/serializable.dart';
import 'package:binary_data/data/struct.dart';
import 'package:test/test.dart';

/// Example 1
class Person {
  const Person(this.id, this.name, this.age);

  final String name;
  final int id;
  final int age;

  Person.fromMap(Map<PersonField, Object> base) : id = base[PersonField.id] as int, name = base[PersonField.name] as String, age = base[PersonField.age] as int;
  factory Person.fromJson(Map<String, Object?> json) => Person.fromMap(StructForm(PersonField.values).fromJson(json));
}

// a key to each field, with an generated string, use as json key; an type parameter, effectively describe the memory allocation requirements
enum PersonField<V extends Object> with SerializableKey<V> {
  id<int>(),
  age<int>(),
  name<String>();

  static const form = StructForm(PersonField.values);

  // key maps entirety of the struct
  //   a function using a known interface access the fields of the user's class, maps ids to getters
  @override
  V getIn(Person struct) {
    return switch (this) {
      PersonField.id => struct.id as V,
      PersonField.age => struct.age as V,
      PersonField.name => struct.name as V,
    };
  }

  @override
  void setIn(Person struct, V value) {
    throw UnimplementedError('Person is immutable');
    //   case PersonField.id:
    //     struct.id = value as int;
    //   case PersonField.age:
    //     struct.age = value as int;
    //   case PersonField.name:
    //     struct.name = value as String;
    // }
  }

  @override
  V? get defaultValue => null;

  @override
  bool testAccess(Object struct) => struct is Person; // all fields are bounded by the same condition in this case
}

/// Example 2
// short hand with mixin
// person.toMap() instead of StructForm(PersonField.values).mapWithData(person)

enum PersonBField<V extends Object> with SerializableKey<V> {
  id<int>(),
  age<int>(),
  name<String>();

  static const form = StructForm(PersonBField.values);

  // key maps entirety of the struct
  //   a function using a known interface access the fields of the user's class, maps ids to getters
  @override
  V getIn(PersonB struct) {
    return switch (this) {
      PersonBField.id => struct.id as V,
      PersonBField.age => struct.age as V,
      PersonBField.name => struct.name as V,
    };
  }

  @override
  void setIn(PersonB struct, V value) => throw UnimplementedError('Person is immutable');

  @override
  V? get defaultValue => null;

  @override
  bool testAccess(Object struct) => struct is Person; // all fields are bounded by the same condition in this case
}

class PersonB with Immutable<PersonB>, Serializable<PersonB> {
  const PersonB(this.id, this.name, this.age);

  final String name;
  final int id;
  final int age;

  // the user side class  provide a function to map the values of a known memory layout/interface to the user's class' memory layout
  // one point of interface to the base class
  PersonB.fromMap(Map<SerializableKey, Object?> base) : id = base[PersonBField.id] as int, name = base[PersonBField.name] as String, age = base[PersonBField.age] as int;

  // function composition, go through a intermediary step of jsonMap -> known memory layout/interface -> user's class, at runtime.
  // Form.fromJson(json) -> Structure -> PersonB.cast(Structure) -> PersonB, at runtime.
  // code gen can directly map jsonMap -> user class, which is most direct during runtime.
  // however the code for mapping json directly to the user class, unique to each user class, would also require additional code size
  factory PersonB.fromJson(Map<String, Object?> json) => PersonB.fromMap(const StructForm(PersonBField.values).fromJson(json));

  List<PersonBField> get keys => PersonBField.values;

  @override
  PersonB copyWithMap(covariant Map<SerializableKey, Object?> data) => PersonB.fromMap(data);

  // inherit toJson from extension on Map<Enum, Object?>
}

void main() {
  const testJson = {'id': 1, 'name': 'Alice', 'age': 30};
  const testJsonError = {'id': 1, 'name': 'Alice', 'age': '30'};
  const personA = Person(1, 'Alice', 30);
  const personAView = Structure<PersonField, Object>(personA); //
  final personAMap = PersonField.form.mapWithData(personAView); // {PersonField.id: 1, PersonField.name: 'Alice', PersonField.age: 30}

  test('structure_test', () {
    print(StructForm(PersonField.values).mapWithData(personAView));
    print(StructForm(PersonField.values).unmapEntriesByName(testJson));
    print(StructForm(PersonField.values).fromJson(testJson));
    print(StructForm(PersonField.values).fromJson(testJson));
    print(Person.fromJson(testJson));
    print(StructForm(PersonField.values).mapWithData(personAView).toJson());
    print(PersonB.fromJson(testJson));
    print(PersonB.fromJson(testJson).withField(PersonField.age, 31));
    print(PersonB.fromJson(testJson).toJson());

    try {
      print(PersonB.fromJson(testJson)[PersonBField.age]);
      print(PersonB.fromJson(testJson)[PersonField.age]);
    } catch (e) {
      print('Error accessing PersonB field: $e');
    }

    try {
      print(PersonB.fromJson(testJsonError).toJson());
    } catch (e) {
      print('Error parsing Person from JSON: $e');
    }
  });
}
