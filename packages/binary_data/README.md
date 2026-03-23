<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

# binary_data Architecture

## Struct Hierarchy


View (ext type)	Schema (ext type)	Base class	Field mixin
Bit	BitStruct<K>	BitForm<K>	BitStructBase<T,K>	BitField
Byte	ByteStruct<K>	ByteForm<K>	ByteStructBase<S,K>	ByteField<V>
Word	WordStruct<K>	WordForm<K>	WordBase<T,K>	WordField<V>


| Type | Backing Storage | Field Granularity | Use Case |
|------|----------------|-------------------|----------|
| `BitStruct` | Single integer | Bit ranges | Hardware registers, flags |
| `WordStruct` | Single word (extends BitStruct) | Bit ranges within a word | Calibration fields |
| `ByteStruct` | `TypedData` buffer | Byte offsets via `TypedField` | Multi-byte packet payloads |

## Collections

| Type | Key Type | Use Case |
|------|----------|----------|
| `EnumMap<E, V>` | Enum | Compile-time safe enum-keyed maps |
| `IndexMap<V>` | int | Dense integer-indexed collections |
| `BitsMap` | BitField enum | Bit-flag collections |
| `BoolMap` | Enum | Boolean-flag collections |