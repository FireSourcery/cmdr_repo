# struct_data

A pure Dart library for bitwise operations, binary data manipulation, and structured data serialization. Provides bit-level, byte-level, and word-level typed structs with enum-keyed maps and binary codecs.

## Features

### Binary Data

- **Bit-level structs** (`BitStruct`, `BitField`) — Pack and extract fields within a single integer using bitmasks. Ideal for hardware registers, flags, and compact binary protocols.
- **Byte-level structs** (`ByteStruct`, `ByteField`) — Keyed access to typed fields within `TypedData` buffers. Supports `Int8`, `Uint16`, `Int32`, etc. via `dart:ffi` native types.
- **Word-level structs** (`WordStruct`, `WordField`) — Byte-aligned fields within a single 64-bit word. Useful for compact multi-field values like version numbers.
- **Binary codecs** (`BinaryFormat`, `BinaryCodec`) — Encode/decode between typed views (`int`, `double`, `bool`, `Enum`) and raw binary integers. Includes fixed-point formats.
- **Bits map collections** (`BitsMap`, `BoolMap`) — Efficient flag/boolean collections backed by a single integer.

### General

- **Serializable mixin** — Declarative field schema using enum keys with `getIn`/`setIn` accessors. Provides `toMap()`, `toJson()`, value equality, and immutable copy helpers.
- **Enum-keyed maps** (`EnumMap`, `IndexMap`) — Type-safe, fixed-key maps backed by parallel arrays. Built-in JSON serialization via `Enum.name`.
- **Utility extensions** — Numeric conversions, typed data slicing, null-safe helpers, and string trimming.
 
## Getting Started

Add `struct_data` to your `pubspec.yaml`:

```yaml
dependencies:
  struct_data: ^0.1.0
```

Then import it:

```dart
import 'package:struct_data/struct_data.dart';
```

> **Note:** This package uses `dart:ffi` native types (`Uint8`, `Int16`, etc.) as type markers for field sizing. 

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
  ready(Bitmask(0, 1)),
  error(Bitmask(1, 1)),
  mode(Bitmask(2, 3));

  const StatusField(this.bitmask);
  @override
  final Bitmask bitmask;
}

final status = BitStruct<StatusField>.from(0x05);
print(status[StatusField.ready]); // 1
print(status[StatusField.mode]);  // 1
```

### Word-level structs (e.g., Version)

```dart
// Built-in Version model — 4 byte-sized fields in a single int
final version = VersionStandard(1, 2, 3, 0, name: 'App');
print(version.toStringAsVersion()); // 1.2.3.0
print(version.toJsonVerbose());     // {fix: 0, minor: 3, major: 2, optional: 1}

// Immutable copy
final patched = version.withField(VersionFieldStandard.fix, 1);
print(patched); // 1.2.3.1
```

### Enum-keyed serialization

```dart
// Define fields as an enum implementing SerializableKey
enum PersonField<V extends Object> with SerializableKey<V> {
  id<int>(),
  name<String>(),
  age<int>();

  @override
  V getIn(Person struct) => switch (this) {
    PersonField.id => struct.id as V,
    PersonField.name => struct.name as V,
    PersonField.age => struct.age as V,
  };

  @override
  void setIn(Person struct, V value) => throw UnsupportedError('immutable');

  @override
  bool testAccess(Object struct) => struct is Person;
}

// Use StructForm for JSON round-tripping
final map = StructForm(PersonField.values).fromJson({'id': 1, 'name': 'Alice', 'age': 30});
print(map.toJson()); // {id: 1, name: Alice, age: 30}
```

### Binary format codecs

```dart
const format = Fract16();            // Q1.15 fixed-point
print(format.decode(16384));         // 0.5
print(format.encode(0.5));           // 16384

const boolFmt = BoolFormat();
print(boolFmt.decode(1));            // true
print(boolFmt.encode(false));        // 0
```

### Enum maps

```dart
enum Color { red, green, blue }

// Create a fixed-key map from enum values
final colors = IndexMap.of(Color.values, [0xFF0000, 0x00FF00, 0x0000FF]);
print(colors[Color.red]);            // 16711680
print(colors.toJson());              // {red: 16711680, green: 65280, blue: 255}
```

## Architecture

### Struct Hierarchy

| Type | Backing Storage | Field Granularity | Use Case |
|------|----------------|-------------------|----------|
| `BitStruct` | Single integer | Bit ranges | Hardware registers, flags |
| `WordStruct` | Single integer | Byte-aligned bit ranges | Calibration fields, version numbers |
| `ByteStruct` | `TypedData` buffer | Byte offsets via `TypedField` | Multi-byte packet payloads |

### Collections

| Type | Key Type | Use Case |
|------|----------|----------|
| `EnumMap<E, V>` | Enum | Compile-time safe enum-keyed maps |
| `IndexMap<V>` | int (via `.index`) | Dense integer-indexed collections |
| `BitsMap` | BitField enum | Bit-flag collections |
| `BoolMap` | Enum | Boolean-flag collections |

### Binary Formats

| Format | Storage | View | Description |
|--------|---------|------|-------------|
| `IntFormat<S>` | `NativeType` | `int` | Raw integer pass-through with sign extension |
| `FractFormat<S>` | `NativeType` | `double` | Fixed-point fractional |
| `BoolFormat` | `Bool` | `bool` | Boolean 0/1 |
| `EnumFormat<V>` | `Int` | `Enum` | Enum by index |
| `FixedPoint<S>` | `NativeType` | `double` | Q-format fixed-point |

## Additional Information

- **License:** BSD 3-Clause
- **Repository:** [github.com/FireSourcery/cmdr](https://github.com/FireSourcery/cmdr)
- **Issues:** [github.com/FireSourcery/cmdr/issues](https://github.com/FireSourcery/cmdr/issues)
- **Platform support:** Dart VM and native platforms (uses `dart:ffi` type markers; not web-compatible)
