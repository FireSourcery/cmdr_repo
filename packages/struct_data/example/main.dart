/// binary_data package examples
///
/// Demonstrates bit-level, byte-level, and word-level struct usage,
/// enum-keyed maps, serialization, and binary format codecs.
library;

import 'package:struct_data/struct_data.dart';
import 'package:struct_data/struct_data.dart';

// ---------------------------------------------------------------------------
// Example 1: Bit-level operations with Bits
// ---------------------------------------------------------------------------
void bitsExample() {
  print('=== Bits Example ===');

  // Raw bit manipulation
  const value = Bits(0xA5); // 10100101
  print('Value: ${value.toStringAsBinary()}'); // 0b10100101
  print('Bit at index 0: ${value.boolAt(0)}'); // true
  print('Bit at index 1: ${value.boolAt(1)}'); // false
  print('Bits [4:4]: ${value.bitsAt(4, 4)}'); // 10 (0xA)

  // Immutable modification
  final modified = value.withBoolAt(1, true);
  print('After setting bit 1: ${modified.toStringAsBinary()}');
  print('');
}

// ---------------------------------------------------------------------------
// Example 2: BitStruct — named bit fields within an integer
// ---------------------------------------------------------------------------
enum StatusField with BitField {
  ready(Bitmask(0, 1)), // bit 0, width 1
  error(Bitmask(1, 1)), // bit 1, width 1
  mode(Bitmask(2, 3))
  ; // bits 2-4, width 3

  const StatusField(this.bitmask);
  @override
  final Bitmask bitmask;
}

void bitStructExample() {
  print('=== BitStruct Example ===');

  final status = BitStruct<StatusField>.from(0x05); // ready=1, error=0, mode=1
  print('Ready: ${status[StatusField.ready]}'); // 1
  print('Error: ${status[StatusField.error]}'); // 0
  print('Mode: ${status[StatusField.mode]}'); // 1

  // Immutable copy with modified field
  final errorStatus = status.withField(StatusField.error, 1);
  print('After setting error: 0x${errorStatus.bits.toRadixString(16)}');
  print('');
}

// ---------------------------------------------------------------------------
// Example 3: WordStruct — Version model
// ---------------------------------------------------------------------------
void versionExample() {
  print('=== Version Example ===');

  // 4 byte-sized fields packed in a single int
  const version = VersionStandard(1, 2, 3, 0, name: 'MyApp');
  print('Version: ${version.toStringAsVersion()}'); // 1.2.3.0
  print('JSON verbose: ${version.toJsonVerbose()}');

  // Immutable update
  final patched = version.withField(VersionFieldStandard.fix, 1);
  print('Patched: ${patched.toStringAsVersion()}'); // 1.2.3.1
  print('');
}

// ---------------------------------------------------------------------------
// Example 4: EnumMap — type-safe enum-keyed collections
// ---------------------------------------------------------------------------
enum Color { red, green, blue }

void enumMapExample() {
  print('=== EnumMap Example ===');

  final colors = IndexMap.of(Color.values, [0xFF0000, 0x00FF00, 0x0000FF]);
  print('Red: 0x${colors[Color.red].toRadixString(16)}');
  print('JSON: ${(colors as Map<Enum, int>).toJson()}');
  print('');
}

// ---------------------------------------------------------------------------
// Example 5: BoolMap — boolean flags backed by a single integer
// ---------------------------------------------------------------------------
enum Permission { read, write, execute }

void boolMapExample() {
  print('=== BoolMap Example ===');

  final perms = BoolMap.of(Permission.values, const Bits(0x05)); // read + execute
  print('Read: ${perms[Permission.read]}'); // true
  print('Write: ${perms[Permission.write]}'); // false
  print('Execute: ${perms[Permission.execute]}'); // true

  perms[Permission.write] = true;
  print('After granting write: ${perms.bits.toStringAsBinary()}');
  print('');
}

// ---------------------------------------------------------------------------
// Example 6: BinaryFormat codecs
// ---------------------------------------------------------------------------
void binaryFormatExample() {
  print('=== BinaryFormat Example ===');

  // Fixed-point Q1.15
  const fract = Fract16();
  print('Fract16 decode 16384: ${fract.decode(16384)}'); // 0.5
  print('Fract16 encode 0.25: ${fract.encode(0.25)}'); // 8192

  // Boolean
  const boolFmt = BoolFormat();
  print('Bool decode 1: ${boolFmt.decode(1)}'); // true
  print('Bool encode false: ${boolFmt.encode(false)}'); // 0

  // Integer with sign extension
  const int16 = Int16Int();
  print('Int16 decode 0xFFFF: ${int16.decode(0xFFFF)}'); // -1
  print('');
}

// ---------------------------------------------------------------------------
// Example 7: Serializable — enum-keyed struct with JSON
// ---------------------------------------------------------------------------
class PersonData {
  const PersonData(this.id, this.name, this.age);
  final int id;
  final String name;
  final int age;
}

enum PersonField<V extends Object> with SerializableField<V> {
  id<int>(),
  name<String>(),
  age<int>()
  ;

  @override
  V getIn(PersonData struct) => switch (this) {
    PersonField.id => struct.id as V,
    PersonField.name => struct.name as V,
    PersonField.age => struct.age as V,
  };

  @override
  void setIn(PersonData struct, V value) => throw UnsupportedError('immutable');

  @override
  bool testAccess(Object struct) => struct is PersonData;
}

void serializableExample() {
  print('=== Serializable Example ===');

  const person = PersonData(1, 'Alice', 30);
  const view = StructData<PersonField, Object>(person);

  // Convert to enum-keyed map
  final map = StructForm(PersonField.values).mapWithData(view);
  print('Map: $map');

  // JSON serialization via EnumMapByName
  print('JSON: ${(map as Map<Enum, Object>).toJson()}');

  // Parse from JSON using EnumMapFactory
  final json = <String, Object>{'id': 2, 'name': 'Bob', 'age': 25};
  final parsed = EnumMapFactory(PersonField.values).fromMapByName(json);
  print('Parsed: $parsed');
  print('');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
void main() {
  bitsExample();
  bitStructExample();
  versionExample();
  enumMapExample();
  boolMapExample();
  binaryFormatExample();
  serializableExample();
}
