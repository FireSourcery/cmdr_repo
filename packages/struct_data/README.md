# struct_data

A pure Dart library for structured data using field descriptors. Lightweight serialization without code generation. Bit-level, byte-level, and word-level typed structs inspired by C-style structs and unions. Enum-keyed maps and binary codecs for embedded protocols and data serialization.

## Features

### Binary Structs

- **`BitStruct`** — Pack and extract arbitrary bit-width fields within a single integer using `Bitmask` descriptors. Ideal for hardware registers, flags, and compact binary protocols.
- **`WordStruct`** — Byte-aligned fields within a single 64-bit integer. Useful for compact multi-field values like version numbers and calibration parameters.
- **`ByteStruct`** — Keyed access to typed fields within `TypedData` buffers via `ByteField` descriptors. Supports `Int8`, `Uint16`, `Int32`, etc. for packet payloads and binary frames.
- **`BinaryFormat` / `BinaryCodec`** — Encode and decode between typed values (`int`, `double`, `bool`, `Enum`) and raw binary integers. Includes fixed-point formats (`Fract16`, `Accum16`, etc.).
- **`BitsMap` / `BoolMap`** — Efficient flag and boolean collections backed by a single integer.

### Structured Data

- **`StructData`** — Zero-cost extension type providing keyed `operator[]` access over any object via `Field` descriptors. No allocation, no wrapper overhead.
- **`Serializable`** — Mixin for declarative JSON serialization using enum field keys. Provides `toMap()`, `toJson()`, value equality, and immutable copy helpers — without code generation.
- **`EnumMap` / `IndexMap`** — Type-safe, fixed-key collections backed by parallel arrays. Built-in JSON serialization via `Enum.name`.
- **Utility extensions** — Numeric conversions, typed data slicing, null-safe helpers, and string operations.

## Getting Started

Add `struct_data` to your `pubspec.yaml`:

```yaml
dependencies:
  struct_data: ^0.1.0
```

Import the full library or only the binary data subset:

```dart
import 'package:struct_data/struct_data.dart';      // Full library
import 'package:struct_data/binary_data.dart';       // Binary structs only
```

> **Note:** This package uses `dart:ffi` native types (`Uint8`, `Int16`, `Int32`, etc.) as compile-time type markers for field sizing. No FFI calls are made at runtime. Packet may selectively implement over ffi.Struct.

## Usage

### Bit-level operations

Use `Bits` for raw bitwise manipulation and `BitStruct` for named field access:

```dart
// Raw bit operations
const flags = Bits(0xFF);
print(flags.boolAt(0));        // true
print(flags.bitsAt(4, 4));     // 15 (upper nibble)

// Named bit fields via enum
enum StatusField with BitField {
  ready(Bitmask(0, 1)),    // bit 0, width 1
  error(Bitmask(1, 1)),    // bit 1, width 1
  mode(Bitmask(2, 3));     // bits 2-4, width 3

  const StatusField(this.bitmask);
  @override
  final Bitmask bitmask;
}

final status = BitStruct<StatusField>.from(0x05);
print(status[StatusField.ready]); // 1
print(status[StatusField.mode]);  // 1

// Immutable field update
final errorStatus = status.withField(StatusField.error, 1);
```

### Word-level structs

Byte-aligned fields packed in a single integer, suitable for version numbers, calibration parameters, and compact identifiers:

```dart
// Built-in Version model — 4 byte-sized fields in a single int
const version = VersionStandard(1, 2, 3, 0, name: 'App');
print(version.toStringAsVersion()); // 1.2.3.0

// Immutable copy with modified field
final patched = version.withField(VersionFieldStandard.fix, 1);
print(patched.toStringAsVersion()); // 1.2.3.1

// Custom WordStruct with mixed field sizes
enum SensorField<V extends NativeType> with WordField<V>, TypedField<V> {
  deviceId<Uint16>(0),
  sensorType<Uint8>(2),
  flags<Uint8>(3),
  reading<Int32>(4);

  const SensorField(this.offset);
  @override
  final int offset;
}

final sensor = const WordStruct<SensorField>(Word.of32s(0x002AA005, 0x00001234));
print(sensor[SensorField.deviceId]);   // 0x1234
print(sensor[SensorField.reading]);    // 42
```

### Byte-level structs

Keyed access to typed fields within `ByteData` buffers for packet payloads and binary protocols:

```dart
enum TelemetryField<V extends NativeType> with ByteField<V>, TypedField<V> {
  timestamp<Uint32>(0),
  deviceId<Uint16>(4),
  status<Uint8>(6),
  value<Int32>(8);

  const TelemetryField(this.offset);
  @override
  final int offset;
}

final buffer = ByteData(12);
final frame = ByteStruct<TelemetryField>(buffer);
frame[TelemetryField.timestamp] = 1700000000;
frame[TelemetryField.deviceId] = 0x1234;
frame[TelemetryField.value] = -42;

print(frame[TelemetryField.value]); // -42
```

### Serializable mixin

Declarative JSON serialization without code generation. Define a field enum with `SerializableField`, then mix `Serializable` into the data class:

```dart
enum PersonField<V extends Object> with SerializableField<V> {
  id<int>(),
  name<String>(),
  age<int>();

  @override
  V getIn(covariant Person struct) => switch (this) {
    PersonField.id => struct.id as V,
    PersonField.name => struct.name as V,
    PersonField.age => struct.age as V,
  };

  @override
  void setIn(covariant Person struct, V value) => throw UnsupportedError('immutable');

  @override
  bool testAccess(Object struct) => struct is Person;
}

class Person with Immutable<Person>, Serializable<Person> {
  const Person(this.id, this.name, this.age);

  Person.fromMap(Map<SerializableField, Object?> map)
    : id = map[PersonField.id] as int,
      name = map[PersonField.name] as String,
      age = map[PersonField.age] as int;

  factory Person.fromJson(Map<String, Object?> json) =>
      Person.fromMap(const StructForm(PersonField.values).fromJson(json));

  final int id;
  final String name;
  final int age;

  @override
  List<PersonField> get keys => PersonField.values;

  @override
  Person copyWithMap(covariant Map<SerializableField, Object?> data) => Person.fromMap(data);
}

final person = Person.fromJson({'id': 1, 'name': 'Alice', 'age': 30});
print(person.toJson());                                 // {id: 1, name: Alice, age: 30}
print(person.withField(PersonField.age, 31).toJson());  // {id: 1, name: Alice, age: 31}
print(person == Person(1, 'Alice', 30));                // true (value equality)
```

### Binary format codecs

Encode and decode between typed values and raw binary integers:

```dart
const fract = Fract16();             // Q1.15 fixed-point
print(fract.decode(16384));          // 0.5
print(fract.encode(0.5));            // 16384

const boolFmt = BoolFormat();
print(boolFmt.decode(1));            // true
print(boolFmt.encode(false));        // 0

const int16 = Int16Int();
print(int16.decode(0xFFFF));         // -1 (sign-extended)
```

### Enum-keyed maps

Type-safe, fixed-key collections with built-in JSON serialization:

```dart
enum Color { red, green, blue }

final colors = IndexMap.of(Color.values, [0xFF0000, 0x00FF00, 0x0000FF]);
print(colors[Color.red]);           // 16711680
print(colors.toJson());             // {red: 16711680, green: 65280, blue: 255}
```

## Architecture

### Design Principles

- **Zero-cost abstractions** — `BitStruct`, `WordStruct`, `ByteStruct`, `StructData`, and `Word` are Dart extension types. They provide typed, keyed access with no runtime allocation or wrapper overhead — the compiler erases them entirely.
- **Field-as-descriptor** — Accessor logic lives on the key (`Field.getIn` / `Field.setIn`), not the struct. This keeps data classes plain and enables the same field schema to work across `StructData` views, `StructBase` subtypes, and serialization.
- **Enum-driven schemas** — Field enums serve as both the schema definition and the serialization key. `Enum.name` provides JSON keys for free via `EnumMapByName`.
- **No code generation** — All serialization, field dispatch, and binary encoding is defined in plain Dart. No `build_runner`, no generated files, no build step.
- **Immutability-first** — Binary structs use functional `withField` / `withMap` copies. `Serializable` classes opt into immutable copies via the `Immutable` mixin.
- **Compile-time const** — `BitStruct`, `WordStruct`, `Word`, and `Bits` values can be `const`, enabling use as enum entries and compile-time constants.

### Struct Hierarchy

Three tiers of structured binary data, each backed by progressively larger storage:

| Type | Backing Storage | Granularity | Typical Size | Use Case |
|------|----------------|-------------|--------------|----------|
| `BitStruct<K>` | `int` | Individual bit ranges | 1–64 bits | Hardware registers, flags, compact protocols |
| `WordStruct<K>` | `int` (via `Word`) | Byte-aligned ranges | 1–8 bytes | Version numbers, calibration, identifiers |
| `ByteStruct<K>` | `ByteData` | Typed byte offsets | Arbitrary | Packet payloads, telemetry frames |

All three are extension types wrapping their backing storage. Field access is dispatched through enum keys implementing `BitField`, `WordField`, or `ByteField` respectively.

### Core Abstractions

| Type | Role |
|------|------|
| `StructData<K, V>` | Zero-cost keyed view over any object via `Field` keys |
| `Field<V>` | Interface for field descriptors: `getIn`, `setIn`, `testAccess` |
| `StructForm<K, V>` | Schema definition (wraps `List<K>`); bridges to `Map` and serialization |
| `StructBase<S, K, V>` | Mixin for user-defined struct classes holding data in their own fields |
| `Serializable<S>` | Mixin providing `toMap()`, `toJson()`, value equality via `SerializableField` keys |
| `Immutable<S>` | Mixin providing `withField`, `withFields`, `withMap` for functional copies |

### Collections

| Type | Key Type | Use Case |
|------|----------|----------|
| `EnumMap<E, V>` | `Enum` | Type-safe enum-keyed map with JSON via `Enum.name` |
| `IndexMap<K, V>` | `Enum` (by `.index`) | Dense, fixed-size collection backed by parallel arrays |
| `BitsMap<K>` / `BoolMap<K>` | `BitField` enum | Bit-flag and boolean collections backed by a single integer |

### Binary Formats

Codecs for encoding typed values to and from integer storage:

| Format | Dart Type | Description |
|--------|-----------|-------------|
| `IntFormat<S>` | `int` | Raw integer with optional sign extension |
| `FractFormat<S>` | `double` | Fixed-point fractional (Q-format) |
| `FixedPoint<S>` | `double` | Configurable Q-format fixed-point |
| `BoolFormat` | `bool` | Boolean as 0/1 |
| `EnumFormat<V>` | `Enum` | Enum by index |
| `BinaryQuantityCodec<V>` | `num` | Value with scaling and unit conversion |

## Benchmarks

The `example/benchmark.dart` file provides local benchmarks for `BitStruct`, `WordStruct`, `ByteStruct`, and `Serializable`, with comparisons against published metrics for Protocol Buffers, json_serializable, freezed, and PackMe.

| Approach | Encode | Decode | Wire Size | Codegen |
|----------|--------|--------|-----------|---------|
| `BitStruct` (8 fields)   | 0.013 µs    | 0.022 µs | Minimal (bit-packed) | None |
| `WordStruct` (8 bytes)   | 0.039 µs    | 0.038 µs | Minimal (byte-packed) | None |
| `ByteStruct` (16 bytes)  | 0.073 µs    | 0.079 µs | Exact (fixed layout) | None |
| `Serializable mixin`     | 0.197 µs    | 0.150 µs | JSON | None |
| json_serializable | ~0.3–0.5 µs | ~0.4–0.6 µs | JSON | build_runner |
| freezed | ~0.3–0.5 µs | ~0.4–0.6 µs | JSON | build_runner |
| Protocol Buffers | ~0.5–2.0 µs | ~0.5–2.0 µs | Compact (varint) | protoc |
| PackMe | ~1.0–3.0 µs | ~1.0–3.0 µs | Compact (tagged) | packme CLI |

Run with `dart run example/benchmark.dart`.

 
## Additional Information

- **Minimum SDK:** Dart 3.10.0
- **Dependencies:** `collection`, `meta`
- **License:** MIT
- **Repository:** [github.com/FireSourcery/cmdr](https://github.com/FireSourcery/cmdr)
- **Issues:** [github.com/FireSourcery/cmdr/issues](https://github.com/FireSourcery/cmdr/issues)
