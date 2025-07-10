/// A comprehensive Flutter package for embedded device communication and data visualization.
///
/// This library provides widgets, utilities, and interfaces for communicating with
/// embedded devices, managing variable data, and creating rich user interfaces.
///
/// ## Features
///
/// - embedded device communication protocols
/// - Real-time variable monitoring and caching
/// - Rich widget library for data visualization
/// - Settings management
/// - File storage utilities
///
/// ## Usage
///
/// ```dart
/// import 'package:cmdr/cmdr.dart';
/// ```
library cmdr;

// External package exports
export 'package:binary_data/binary_data.dart';
export 'package:type_ext/basic_types.dart';

// Core module exports
export 'connection.dart';
export 'file_storage.dart';
export 'interfaces.dart';
export 'models.dart';
export 'settings.dart';
export 'types.dart';
export 'var_notifier.dart';
export 'widgets.dart';

// Specialized exports (use specific imports for these)
// export 'binary_data.dart';     // Use: import 'package:cmdr/binary_data.dart';
// export 'mot_connection.dart';  // Use: import 'package:cmdr/mot_connection.dart';
// export 'type_ext.dart';        // Use: import 'package:cmdr/type_ext.dart';
