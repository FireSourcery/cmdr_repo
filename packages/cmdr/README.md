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

Commander/Host side utilities for interfacing with embedded devices + other general utilities.

## Features

| Library | Features |
|---|---|
| `cmdr.dart` | Embedded device communication protocols; real-time variable monitoring and caching; rich widget library for data visualization; settings management; file storage utilities. Re-exports `struct_data` (bit/byte structs, codecs) |
| `connection.dart` | Abstract connection interfaces; protocol definitions and packet transformers; serial link implementations; connection management widgets |
| `mot_connection.dart` | Embedded device specific protocols; packet serialization/deserialization; connection management for embedded devices |
| `file_storage.dart` | Multiple file format support (CSV, JSON, binary); reactive file storage with notifications; file management widgets; type-safe file operations |
| `interfaces.dart` | Service interfaces; abstract base classes; key-based interfaces; I/O service abstractions |
| `models.dart` | Motor controller data models; type-safe model definitions; conversion utilities; model view widgets |
| `settings.dart` | Type-safe setting definitions; automatic persistence to storage; reactive setting controllers; Flutter integration with settings views |
| `type_ext.dart` | Extended type functionality; utility methods for common types; enhanced type safety |
| `var_notifier.dart` | Real-time variable monitoring; automatic caching and persistence; context-aware variable management; Flutter integration with inherited widgets |
| `widgets.dart` | Data visualization widgets (charts, gauges, meters); input/output field widgets; dialog and modal components; application-specific UI components; layout and navigation widgets |

## Getting started

 

## Usage

Widgets partially parameterized, defaults/examples, are denoted as _widgets.dart
 
 

## Additional information
 
