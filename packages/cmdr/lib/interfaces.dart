/// Interface definitions library for the CMDR package.
///
/// This library provides abstract interfaces and contracts used throughout
/// the package for consistent API design and extensibility.
///
/// ## Features
///
/// - Service interfaces
/// - Abstract base classes
/// - Key-based interfaces
/// - I/O service abstractions
///
/// ## Usage
///
/// ```dart
/// import 'package:cmdr/interfaces.dart';
///
/// // Implement interfaces
/// class MyService implements ServiceIO {
///   // Implementation
/// }
/// ```
library cmdr.interfaces;

export 'interfaces/service_io.dart';
