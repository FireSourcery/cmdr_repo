# CLAUDE.md — Project Guide for AI Assistants

## Project Overview

This is a **Dart/Flutter monorepo** containing reusable library packages for embedded systems GUI applications. The primary packages are:

- **`packages/cmdr`** — Flutter widgets, controllers, connection interfaces, file storage, settings, and var_notifier state management.
- **`packages/struct_data`** — Pure Dart library for binary data manipulation: bit/byte structs, typed fields, serialization, binary codecs, and word-level operations.

These libraries are **general-purpose, framework-level** packages designed to be consumed by downstream application projects.

---
 
## Core Principles
- **Expression through code**: Use code as the language to express what its doing. Favor code that expresses itself over extensive comments.
- **Declarative functions**. Favor less local variables. e.g. function body should look like the equation in its docstring, not reconstruct it.
  esEssential logic in it's own function. compose error checking.
-  
### Documentation
- Keep comments concise. Comments are reserved for points that the code cannot express, not what the code is doing.
- Use visualizations with mermaid diagrams in a separate markdown file for describing what the code is doing
- Extensive descriptions go in a separate markdown file, such as architecture notes.
- Markdown stays in `.md` files: a doc comment keeps prose, `[Identifier]` links, backtick literals and short code samples, never a diagram or a `##` section, and points to the `.md` that has them. Why: `../kelly_user_app/doc/decisions/0002_markdown_in_md_files.md`. 

---

## Repository Structure

```
./
├── pubspec.yaml               # pub workspace root for both packages
├── analysis_options.yaml      # shared by both packages
├── packages/
│   ├── cmdr/lib/
│   │   ├── connection/        # Serial links, MOT protocol, packet transforms
│   │   │   ├── base/          # Abstract Link, PacketTransformer, Protocol
│   │   │   ├── links/         # SerialLink implementation
│   │   │   ├── mot_connection/ # MOT-specific connection, packet, protocol
│   │   │   └── view/          # SerialLinkView widget
│   │   ├── file_storage/      # File I/O: binary, CSV, JSON, notifier, view
│   │   ├── interfaces/        # NumUnion, ServiceIO, Stringifier abstractions
│   │   ├── models/            # ADC config, surface speed, thermistor, voltage
│   │   ├── settings/          # App settings: model, controller, service, view
│   │   ├── type_ext/          # Property extension utilities
│   │   ├── var_notifier/      # Reactive state: VarNotifier, VarCache, VarKey, VarController
│   │   │   └── widgets/       # VarIOField, VarMenu, VarWidget, VarInputDialog
│   │   └── widgets/           # Reusable Flutter widgets
│   │       ├── app_general/   # BottomSheetButton, DriveShift, Logo
│   │       ├── data_views/    # FlagFieldView, MapFormFields, SelectionChips
│   │       ├── dialog/        # DialogAnchor, Dialog
│   │       ├── flyweight_menu/ # FlyweightMenu system
│   │       ├── io_field/      # IOField, NumTextField, SelectableIOField
│   │       ├── layouts/       # Layout helpers
│   │       ├── main_menu/     # MainMenu + MainMenuController
│   │       └── time_chart/    # Chart controller, data, legend, style, widgets
│   │
│   └── struct_data/lib/
│       ├── binary_format/     # BinaryCodec, BinaryFormat, QuantityFormat
│       ├── bits/              # Bits, BitField, BitStruct, BitsMap, BoolMap
│       ├── bytes/             # ByteStruct, TypedArray, TypedDataBuffer, TypedField
│       ├── general/           # Struct, Enumerated, Serializable, Binarizable, EnumMap, IndexMap
│       ├── models/            # Version
│       ├── packet/            # Packet, PacketCodec, PacketBuffer, PacketParser, PacketId
│       ├── utilities/         # BasicTypes, extensions, Slice
│       └── word/              # Word, WordStruct
```

---

## Build & Run Commands

```bash
# Get dependencies for both packages (the repo root is the pub workspace root)
flutter pub get

# Analyze code (from the root, both packages)
dart analyze
flutter analyze

# Run tests, per package
cd packages/struct_data && dart test     # pure Dart
cd packages/cmdr && flutter test         # Flutter

# Run tests in a specific file, from its package folder
dart test test/path/to/test.dart
flutter test test/path/to/test.dart

# Format only the files you changed: a blanket `dart format .` reflows hand-laid-out code
dart format <files>
```

---

## Code Style & Conventions

### Language & Framework
- **Dart 3.x** with sound null safety
- **Flutter** for widget packages
- Minimum SDK constraints defined in each package's `pubspec.yaml`

### Naming
- Effective Dart, except enums that mirror firmware ids (`MotPacketRequestId`, `MotPacketControlId`, …): they keep the C names and order of `FireSourcery_Library/Motor/MotProtocol/`.

### Architecture Patterns
- **VarNotifier pattern**: Reactive state management using `VarNotifier`, `VarKey`, `VarCache`, and `VarController`. This is the primary state management approach — prefer it over raw `ValueNotifier`/`ChangeNotifier` for domain values.
- **Service/Controller/View separation**: Settings module demonstrates this split — `SettingsService` (persistence), `SettingsController` (logic), `SettingsView` (UI).
- **Protocol abstraction**: `Protocol(link, codec)` puts a `Link` (transport) under a `PacketCodec` (wire format, struct_data `packet/`), whose `transformer` frames the Rx stream. A new transport extends `Link`; a new wire format is a `PacketCodec`.
- **Struct-based binary data**: Use `BitStruct`, `ByteStruct`, `WordStruct` for memory-mapped binary layouts. Use `TypedField` for individual typed fields within structs.
- **EnumMap / IndexMap**: Prefer `EnumMap<E, V>` for enum-keyed collections and `IndexMap` for index-keyed collections over raw `Map`.
- **Serializable**: `typedef Serializable<K> = StructBase<K, Object?>`, keyed by its field enum; JSON through the `toJson` / `fromJson` extensions.

### Widget Conventions
- Reusable widgets live in `cmdr/lib/widgets/` organized by feature subdirectory.
- `IOField` is the base text input/output field — extend or compose with it (see `NumTextField`, `SelectableIOField`, `VarIOField`).
- Use `FlyweightMenu` for context menus with shared menu item definitions.
- `DialogAnchor` pattern for anchored dialogs and popups.

### Binary Data Conventions
- Use `Bits` for raw bit manipulation utilities.
- `BinaryFormat` / `BinaryCodec` for encoding/decoding typed values to/from binary.
- `QuantityFormat` for values with physical units.
- `Slice` for zero-copy sub-views of data.
- `TypedArray` and `TypedDataBuffer` for efficient typed collections.
- Prefer `num_ext.dart` and `basic_ext.dart` extensions over standalone utility functions.

### File Storage
- `FileStorage` is the abstract base; `BinaryFileStorage`, `CsvFileStorage`, `JsonFileStorage` are concrete implementations.
- `FileStorageNotifier` wraps storage with change notification for reactive UI binding.

### General Rules
- **No `dynamic`** unless absolutely necessary for interop.
- **Prefer `final`** for local variables and fields that don't change after initialization.
- **Prefer `const` constructors** for widgets and immutable objects.
- **Avoid `as` casts** — use pattern matching or type checks.
- **Extension methods** are preferred for adding functionality to existing types (see cmdr `type_ext/`, struct_data `utilities/basic_ext.dart`, `utilities/num_ext.dart`).
- **Keep packages independent** — `struct_data` has zero Flutter dependencies; `cmdr` may depend on `struct_data` but not vice versa.
- Run `dart analyze`: no new issues over the current baseline (struct_data's are almost all `avoid_print` in `example/`).

### Testing
- Unit tests go in `test/` mirroring the `lib/` structure.
- Pure logic and binary data tests use `package:test`.
- Widget tests use `package:flutter_test`.
- Name test files `*_test.dart`.

---

## Key Abstractions to Know

| Concept | Package | Location (under `lib/`) | Purpose |
|---|---|---|---|
| `VarNotifier<T>` | cmdr | `var_notifier/var_notifier.dart` | Reactive variable with notification |
| `VarKey` | cmdr | `var_notifier/var_key.dart` | Identifier for a VarNotifier in a VarCache |
| `VarCache` | cmdr | `var_notifier/var_cache.dart` | Registry/cache of VarNotifiers |
| `VarController` | cmdr | `var_notifier/var_controller.dart` | Orchestrates VarCache + connection sync |
| `ServiceIO` | cmdr | `var_notifier/service_io.dart` | Abstract service input/output interface |
| `Link` | cmdr | `connection/base/link.dart` | Abstract bidirectional data link |
| `Protocol` | cmdr | `connection/base/protocol.dart` | Command/response over a `Link` and a `PacketCodec` |
| `IOField` | cmdr | `widgets/io_field/io_field.dart` | Base input/output text field widget |
| `FileStorage` | cmdr | `file_storage/file_storage.dart` | Abstract file read/write |
| `Stringifier` | cmdr | `type_ext/stringifier.dart` | Interface for value ↔ string conversion |
| `Property` | cmdr | `type_ext/property.dart` | Descriptor pairing a value with metadata |
| `PacketCodec` | struct_data | `packet/packet_codec.dart` | Wire format: frame shapes, ids, checksum |
| `PacketTransformer` | struct_data | `packet/packet_parser.dart` | Stream transformer framing packets through `HeaderParser` |
| `BitStruct` | struct_data | `bits/bit_struct.dart` | Struct with bit-level field accessors |
| `ByteStruct` | struct_data | `bytes/byte_struct.dart` | Struct with byte-level field accessors |
| `TypedField` | struct_data | `bytes/typed_field.dart` | Single typed field within a byte buffer |
| `BinaryFormat` | struct_data | `binary_format/binary_format.dart` | Descriptor for binary encoding of a value |
| `Serializable` | struct_data | `general/serializable.dart` | `StructBase` keyed by its field enum, JSON via extensions |
| `EnumMap<E,V>` | struct_data | `general/enum_map.dart` | Type-safe enum-keyed map |

---

## Common Pitfalls

- **Don't import Flutter in `struct_data`** — it's a pure Dart package.
- **VarNotifier disposal** — always dispose VarNotifiers when the owning widget/controller is disposed to avoid memory leaks.
- **BitStruct field order** — bit fields are packed LSB-first by default; verify bit offset calculations match your hardware specification.
- **Packet framing** — when implementing a new `PacketTransformer`, handle partial packets and buffer accumulation correctly in the stream transformer.
- **File paths** — use `path` package for cross-platform path handling in file storage implementations.
- **Primary constructors** are the house style: `class const X(final int a) extends Y`, initializers after `this :`. Run `dart fix` one `--code` at a time and read the diff (traps: app README, "Local development").
- **pub.dev names** — pub.dev's `cmdr` is an unrelated package, and pub.dev's `struct_data` 0.1.3 differs from the local copy under the same version. cmdr's pubspec names struct_data in hosted form so it stays publishable; the workspace resolves it locally, consumers override it ([decision 0001](doc/decisions/0001_hosted_sibling_dependency.md)).
- **Commented-out code** is design intent parked mid-implementation, not dead code.

## Changing library code
Why, with instances: [doc/conventions/library_code.md](doc/conventions/library_code.md). Index of the library's docs: [doc/README.md](doc/README.md).
- A fix goes inside the expression or loop the file already has. Needing a new construction to make it fit is the signal to look again.
- A constraint every caller already meets is an `assert`, not runtime checking. Runtime handling is for wire data and user input.
- An anomaly something downstream absorbs (the device wraps `Angle16`'s 65536 to 0) gets a one-line comment and a test pinning it, not a guard.