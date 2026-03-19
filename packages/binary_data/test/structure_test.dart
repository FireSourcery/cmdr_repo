// import 'package:binary_data/binary_data.dart';
// import 'package:binary_data/data/serializable.dart';
// import 'package:binary_data/data/struct.dart';

// /// Example 1
// class Person {
//   const Person(this.id, this.name, this.age);

//   final String name;
//   final int id;
//   final int age;
// }

// // a key to each field, with an generated string, use as json key; an type parameter, effectively describe the memory allocation requirements
// enum PersonField<V> implements SerializableKey<V> {
//   id<int>(),
//   age<int>(),
//   name<String>();

//   //key maps entirety of the struct
//   //   a function using a known interface access the fields of the user's class, maps ids to getters
//   @override
//   V getIn(Person struct) {
//     return switch (this) {
//       PersonField.id => struct.id as V,
//       PersonField.age => struct.age as V,
//       PersonField.name => struct.name as V,
//     };
//   }

//   @override
//   void setIn(Person struct, V value) {
//     throw UnimplementedError('Person is immutable');
//     //   case PersonField.id:
//     //     struct.id = value as int;
//     //   case PersonField.age:
//     //     struct.age = value as int;
//     //   case PersonField.name:
//     //     struct.name = value as String;
//     // }
//   }

//   @override
//   V? get defaultValue => null;

//   @override
//   bool testAccess(Object struct) => struct is Person; // all fields are bounded by the same condition in this case
// }

// const personA = Person(1, 'Alice', 30);
// const personView = Structure<PersonField, Object>(personA);
// final fields = personView.fields(PersonField.values).toList(); // [1, 'Alice', 30]
// // final Iterable<MapEntry> premap = personView. (PersonField.values);
// const personType = StructForm(PersonField.values);
// final testMap2 = StructForm(PersonField.values).map(personView); // {PersonField.id: 1, PersonField.age: 30, PersonField.name: 'Alice'}

// /// Example 2
// // short hand with mixin

// class PersonB with Serializable<PersonField> {
//   const PersonB(this.id, this.name, this.age);

//   final String name;
//   final int id;
//   final int age;

//   // the user side class  provide a function to map the values of a known memory layout/interface to the user's class' memory layout
//   // one point of interface to the base class
//   // PersonB.castBase(PersonB map) : id = map[PersonField.id], name = map[(PersonField.name)], age = map[(PersonField.age)];
//   PersonB.cast(Structure<PersonField, Object> map) : id = map[PersonField.id] as int, name = map[PersonField.name] as String, age = map[PersonField.age] as int;

//   // function composition, go through a intermediary step of jsonMap -> known memory layout/interface -> user's class, at runtime.
//   // Form.fromJson(json) -> Structure -> PersonB.cast(Structure) -> PersonB, at runtime.
//   // where as code gen can directly map jsonMap -> user class, which is most direct during runtime.
//   // however the code for mapping json directly to the user class, unique to each user class, would also require additional code size
//   factory PersonB.fromJson(Map<String, Object?> json) => PersonB.cast(StructForm(PersonField.values).fromJson(json));

//   @override
//   Structure<PersonField, Object> get data => this as Structure<PersonField, Object>; // point at itself

//   List<PersonField> get keys => PersonField.values;

//   Map get test => this.toJson();

//   @override
//   Serializable<PersonField<dynamic>> copyWithData(Structure<PersonField, Object> data) {
//     return PersonB.cast(data);
//   }

//   // inherit toJson from extension on Map<Enum, Object?>
// }
