# CLAUDE.md — Project Guide for AI Assistants

## Project Overview

This is a **Dart/Flutter monorepo** containing reusable library packages for embedded systems GUI applications. The primary packages are:

- **`packages/cmdr`** — Flutter widgets, controllers, connection interfaces, file storage, settings, and var_notifier state management.
- **`packages/binary_data`** — Pure Dart library for binary data manipulation: bit/byte structs, typed fields, serialization, binary codecs, and word-level operations.

These libraries are **general-purpose, framework-level** packages designed to be consumed by downstream application projects (e.g., `kelly_user_app`).

---

## Repository Structure

```
cmdr_repo/
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
│   └── binary_data/lib/
│       ├── binary_format/     # BinaryCodec, BinaryFormat, QuantityFormat
│       ├── bits/              # BitField, BitStruct, BitsMap, BoolMap
│       ├── bytes/             # ByteStruct, TypedArray, TypedDataBuffer, TypedField
│       ├── data/              # BasicTypes, EnumMap, IndexMap, Serializable, Struct, Slice
│       ├── models/            # Packet, Version
│       └── word/              # Word, WordStruct
```

---

## Build & Run Commands

```bash
# Get dependencies (run from package directory or repo root with melos)
dart pub get
flutter pub get

# Analyze code
dart analyze
flutter analyze

# Run tests
dart test                          # for binary_data (pure Dart)
flutter test                       # for cmdr (Flutter)

# Run tests in a specific file
dart test test/path/to/test.dart
flutter test test/path/to/test.dart

# Format code
dart format .

# Generate code (if using build_runner, e.g., for freezed/json_serializable)
dart run build_runner build --delete-conflicting-outputs
```

---

## Code Style & Conventions

### Language & Framework
- **Dart 3.x** with sound null safety
- **Flutter** for widget packages
- Minimum SDK constraints defined in each package's `pubspec.yaml`

### Naming
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/functions**: `camelCase`
- **Constants**: `camelCase` (Dart convention, not SCREAMING_SNAKE)
- **Private members**: prefix with `_`
- **Enum values**: `camelCase`

### Architecture Patterns
- **VarNotifier pattern**: Reactive state management using `VarNotifier`, `VarKey`, `VarCache`, and `VarController`. This is the primary state management approach — prefer it over raw `ValueNotifier`/`ChangeNotifier` for domain values.
- **Service/Controller/View separation**: Settings module demonstrates this split — `SettingsService` (persistence), `SettingsController` (logic), `SettingsView` (UI).
- **Protocol abstraction**: Connection layer uses `Link` → `PacketTransformer` → `Protocol` layering. Implement new transports by extending `Link`, new wire formats via `PacketTransformer`.
- **Struct-based binary data**: Use `BitStruct`, `ByteStruct`, `WordStruct` for memory-mapped binary layouts. Use `TypedField` for individual typed fields within structs.
- **EnumMap / IndexMap**: Prefer `EnumMap<E, V>` for enum-keyed collections and `IndexMap` for index-keyed collections over raw `Map`.
- **Serializable**: Types that persist or transfer over the wire should implement `Serializable`.

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
- **Extension methods** are preferred for adding functionality to existing types (see `type_ext/`, `data/basic_ext.dart`, `data/num_ext.dart`).
- **Keep packages independent** — `binary_data` has zero Flutter dependencies; `cmdr` may depend on `binary_data` but not vice versa.
- Follow **effective Dart** lint rules. Run `dart analyze` with zero warnings before committing.

### Testing
- Unit tests go in `test/` mirroring the `lib/` structure.
- Pure logic and binary data tests use `package:test`.
- Widget tests use `package:flutter_test`.
- Name test files `*_test.dart`.

---

## Key Abstractions to Know

| Concept | Location | Purpose |
|---|---|---|
| `VarNotifier<T>` | `var_notifier/var_notifier.dart` | Reactive variable with notification |
| `VarKey` | `var_notifier/var_key.dart` | Identifier for a VarNotifier in a VarCache |
| `VarCache` | `var_notifier/var_cache.dart` | Registry/cache of VarNotifiers |
| `VarController` | `var_notifier/var_controller.dart` | Orchestrates VarCache + connection sync |
| `Link` | `connection/base/link.dart` | Abstract bidirectional data link |
| `Protocol` | `connection/base/protocol.dart` | Abstract command/response protocol |
| `PacketTransformer` | `connection/base/packet_transformer.dart` | Stream transformer for packet framing |
| `BitStruct` | `bits/bit_struct.dart` | Struct with bit-level field accessors |
| `ByteStruct` | `bytes/byte_struct.dart` | Struct with byte-level field accessors |
| `TypedField` | `bytes/typed_field.dart` | Single typed field within a byte buffer |
| `BinaryFormat` | `binary_format/binary_format.dart` | Descriptor for binary encoding of a value |
| `Serializable` | `data/serializable.dart` | Interface for serialize/deserialize |
| `EnumMap<E,V>` | `data/enum_map.dart` | Type-safe enum-keyed map |
| `IOField` | `widgets/io_field/io_field.dart` | Base input/output text field widget |
| `FileStorage` | `file_storage/file_storage.dart` | Abstract file read/write |
| `ServiceIO` | `interfaces/service_io.dart` | Abstract service input/output interface |
| `Stringifier` | `interfaces/stringifier.dart` | Interface for value ↔ string conversion |
| `Property` | `type_ext/property.dart` | Descriptor pairing a value with metadata |

---

## Common Pitfalls

- **Don't import Flutter in `binary_data`** — it's a pure Dart package.
- **VarNotifier disposal** — always dispose VarNotifiers when the owning widget/controller is disposed to avoid memory leaks.
- **BitStruct field order** — bit fields are packed LSB-first by default; verify bit offset calculations match your hardware specification.
- **Packet framing** — when implementing a new `PacketTransformer`, handle partial packets and buffer accumulation correctly in the stream transformer.
- **File paths** — use `path` package for cross-platform path handling in file storage implementations.