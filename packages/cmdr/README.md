Commander/Host side utilities for interfacing with embedded devices + other general utilities.

A Flutter package: a serial link and a request/response protocol over it, a reactive cache of device variables kept in
step with the device, and the widgets, settings and file storage a host application builds on. Binary structs and the
packet framework come from its sibling, `struct_data`.

## Features

| Library | Features |
|---|---|
| `cmdr.dart` | Every library below except `mot_connection.dart` and `type_ext.dart`. Re-exports `struct_data` (bit/byte structs, codecs) |
| `connection.dart` | `Link` (a transport) and `Protocol` (request/response over a `Link` and a `PacketCodec`); `SerialLink` over libserialport; `SerialLinkView` |
| `mot_connection.dart` | MotProtocol: `MotConnection`, the `MotPacketCodec` wire format and its payload table, `MotProtocolSocket` |
| `file_storage.dart` | Multiple file format support (CSV, JSON, Intel HEX); reactive file storage with notifications; file open/save buttons and dialogs |
| `interfaces.dart` | `ServiceIO`, the get/set/poll/push service the var controllers run over |
| `models.dart` | ADC config, surface speed, thermistor and voltage divider models |
| `settings.dart` | Type-safe setting definitions; persistence through shared preferences; a reactive settings controller; setting views |
| `type_ext.dart` | Parked: exports nothing today. Import `type_ext/property.dart` (`PropertyFilter`) or `type_ext/stringifier.dart` directly |
| `types.dart` | Parked: exports nothing today (its body is commented out) |
| `var_notifier.dart` | `VarNotifier`, `VarKey`, `VarCache`; `VarCacheController`, `VarStreamController` (poll and push streams) and `VarSingleController`; `VarContext` inherited widgets |
| `widgets.dart` | Time chart (controller, data, legend, file); `IOField` input/output fields; dialogs and `DialogAnchor`; `DriveShift`, `BottomSheetButton`, logo; selection chips and map form fields; layouts; `VarIOField` and the var widgets |

## Getting started

The package lives in the `FireSourcery/cmdr` repository, cloned as `cmdr_repo`: a pub workspace whose root holds both
packages. Working on it needs no other checkout:

```powershell
git clone https://github.com/FireSourcery/cmdr.git cmdr_repo
cd cmdr_repo
flutter pub get
```

`pubspec.yaml` names `struct_data` in hosted form (`struct_data: ^0.1.3`). Inside the workspace it resolves to
`packages/struct_data`; a consumer outside it overrides `struct_data` with this repository's copy, because pub.dev's
`struct_data` 0.1.3 differs from it under the same version.

### Layout

| Folder | Holds |
|---|---|
| `lib/connection/` | `base/`: `Link`, `Protocol`, `ProtocolSocket`; `links/`: `SerialLink`; `mot_connection/`: `MotConnection`, `MotPacketCodec` and payloads, `MotProtocolSocket`; `view/`: `SerialLinkView` |
| `lib/file_storage/` | `FileStorage`, `FileStorageNotifier`, `HexFileStorage`, `CsvFileStorage`, `JsonFileStorage`, file views |
| `lib/interfaces/` | Parked, commented out: `NumUnion`, `ValueViewer` |
| `lib/models/` | `adc_config`, `surface_speed`, `thermistor`, `voltage` |
| `lib/settings/` | `Setting`, `SettingsController`, `SharedPrefService`, setting views |
| `lib/type_ext/` | `PropertyFilter`, `Stringifier` |
| `lib/var_notifier/` | `VarNotifier`, `VarKey`, `VarCache`, the controllers, `ServiceIO`, `VarContext`; `widgets/`: `VarIOField`, the var menu, `VarInputDialog`, var widgets |
| `lib/widgets/` | `app_general/`, `data_views/`, `dialog/`, `flyweight_menu/`, `io_field/`, `layouts/`, `main_menu/`, `time_chart/`, `num_input_formatters.dart` |
| `test/` | Unit and widget tests; `fakes/` holds `FakeLink` and `FakeServiceIO` |
| `example/main.dart` | A placeholder app |

## Usage

Import `package:cmdr/cmdr.dart`, or one library from the table above. MotProtocol is its own import,
`package:cmdr/mot_connection.dart`.

Widgets partially parameterized, defaults/examples, are denoted as _widgets.dart

From `packages/cmdr`:

```powershell
flutter analyze
flutter test
```

- The tests that open a serial port skip unless `LIBSERIALPORT_PATH` points at a built `serialport.dll`.
- Lints: `flutter_lints`, then the shared rules in the repository root's `analysis_options.yaml`.
- Format only the files you change (`dart format <files>`): page width 200, trailing commas preserved.

## Additional information

- Changes: [CHANGELOG.md](CHANGELOG.md).
- The guide for agents is the root [CLAUDE.md](../../CLAUDE.md).
- Not published (`publish_to: none`): pub.dev's `cmdr` is an unrelated package, so a rename comes first.
