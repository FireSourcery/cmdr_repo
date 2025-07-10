/// File storage library for the CMDR package.
///
/// This library provides utilities for reading, writing, and managing various
/// file formats including CSV, JSON, and binary data.
///
/// ## Features
///
/// - Multiple file format support (CSV, JSON, binary)
/// - Reactive file storage with notifications
/// - File management widgets
/// - Type-safe file operations
///
/// ## Usage
///
/// ```dart
/// import 'package:cmdr/file_storage.dart';
///
/// // Use file storage
/// final csvStorage = CsvFileStorage();
/// final jsonStorage = JsonFileStorage();
/// ```
library cmdr.file_storage;

// Core file storage classes
export 'file_storage/file_storage.dart';
export 'file_storage/file_storage_notifier.dart';

// Specific file format implementations
export 'file_storage/binary_file_storage.dart';
export 'file_storage/csv_file_storage.dart';
export 'file_storage/json_file_storage.dart';

// File storage widgets
export 'file_storage/file_storage_view.dart';
