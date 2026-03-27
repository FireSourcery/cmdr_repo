import 'package:struct_data/struct_data.dart';
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

enum PersonField<V extends Object> with SerializableField<V> {
  id<int>(),
  age<int>(),
  name<String>()
  ;

  static const form = StructForm(PersonField.values);

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
  }

  V? get defaultValue => null;

  @override
  bool testAccess(Object struct) => struct is Person;
}

/// Example 2
// short hand with mixin
// person.toMap() instead of StructForm(PersonField.values).mapWithData(person)

enum SerializablePersonField<V extends Object> with SerializableField<V> {
  id<int>(),
  age<int>(),
  name<String>()
  ;

  static const form = StructForm(SerializablePersonField.values);

  @override
  V getIn(SerializablePerson struct) {
    return switch (this) {
      SerializablePersonField.id => struct.id as V,
      SerializablePersonField.age => struct.age as V,
      SerializablePersonField.name => struct.name as V,
    };
  }

  @override
  void setIn(SerializablePerson struct, V value) => throw UnimplementedError('Person is immutable');

  V? get defaultValue => null;

  @override
  bool testAccess(Object struct) => struct is Person;
}

class SerializablePerson with Immutable<SerializablePerson>, Serializable<SerializablePerson> {
  const SerializablePerson(this.id, this.name, this.age);

  final String name;
  final int id;
  final int age;

  SerializablePerson.fromMap(Map<SerializableField, Object?> base)
    : id = base[SerializablePersonField.id] as int,
      name = base[SerializablePersonField.name] as String,
      age = base[SerializablePersonField.age] as int;

  factory SerializablePerson.fromJson(Map<String, Object?> json) => SerializablePerson.fromMap(const StructForm(SerializablePersonField.values).fromJson(json));

  List<SerializablePersonField> get keys => SerializablePersonField.values;

  @override
  SerializablePerson copyWithMap(covariant Map<SerializableField, Object?> data) => SerializablePerson.fromMap(data);
}

void main() {
  const testJson = {'id': 1, 'name': 'Alice', 'age': 30};
  const testJsonError = {'id': 1, 'name': 'Alice', 'age': '30'};
  const personA = Person(1, 'Alice', 30);
  const personAView = StructData<PersonField, Object>(personA);

  group('StructForm', () {
    test('mapWithData creates enum-keyed map from struct', () {
      final map = StructForm(PersonField.values).mapWithData(personAView);
      expect(map[PersonField.id], 1);
      expect(map[PersonField.name], 'Alice');
      expect(map[PersonField.age], 30);
    });

    test('unmapEntriesByName parses string-keyed map to entries', () {
      final entries = StructForm(PersonField.values).unmapEntriesByName(testJson).toList();
      expect(entries.length, 3);
      expect(entries.any((e) => e.key == PersonField.id && e.value == 1), isTrue);
      expect(entries.any((e) => e.key == PersonField.name && e.value == 'Alice'), isTrue);
      expect(entries.any((e) => e.key == PersonField.age && e.value == 30), isTrue);
    });

    test('fromJson creates enum-keyed map from JSON', () {
      final map = StructForm(PersonField.values).fromJson(testJson);
      expect(map[PersonField.id], 1);
      expect(map[PersonField.name], 'Alice');
      expect(map[PersonField.age], 30);
    });
  });

  group('Person', () {
    test('fromJson constructs Person from JSON map', () {
      final person = Person.fromJson(testJson);
      expect(person.id, 1);
      expect(person.name, 'Alice');
      expect(person.age, 30);
    });

    test('toJson round-trips from struct to JSON', () {
      final json = StructForm(PersonField.values).mapWithData(personAView).toJson();
      expect(json, {'id': 1, 'age': 30, 'name': 'Alice'});
    });
  });

  group('PersonB (Serializable + Immutable)', () {
    test('fromJson constructs PersonB', () {
      final person = SerializablePerson.fromJson(testJson);
      expect(person.id, 1);
      expect(person.name, 'Alice');
      expect(person.age, 30);
    });

    test('withField returns new instance with updated field', () {
      final person = SerializablePerson.fromJson(testJson).withField(PersonField.age, 31);
      expect(person.age, 31);
      expect(person.id, 1);
      expect(person.name, 'Alice');
    });

    test('toJson serializes to string-keyed map', () {
      final json = SerializablePerson.fromJson(testJson).toJson();
      expect(json, {'id': 1, 'age': 30, 'name': 'Alice'});
    });

    test('field access via matching key type succeeds', () {
      final person = SerializablePerson.fromJson(testJson);
      expect(person[SerializablePersonField.age], 30);
    });

    test('field access via mismatched key type throws', () {
      final person = SerializablePerson.fromJson(testJson);
      // PersonField.testAccess checks for Person, not PersonB
      expect(() => person[PersonField.age], throwsA(isA<TypeError>()));
    });
  });

  group('error handling', () {
    test('fromJson with mismatched value types throws FormatException', () {
      expect(
        () => SerializablePerson.fromJson(testJsonError).toJson(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
