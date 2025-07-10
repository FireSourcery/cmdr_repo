/// Data models library for the CMDR package.
///
/// This library provides data models and type definitions used throughout
/// the embedded device communication system.
///
/// ## Features
///
/// - Motor controller data models
/// - Type-safe model definitions
/// - Conversion utilities
/// - Model view widgets
///
/// ## Usage
///
/// ```dart
/// import 'package:cmdr/models.dart';
///
/// // Use models
/// final voltage = Voltage(12.5);
/// final direction = Direction.forward;
/// ```
library cmdr.models;

// Core models
export 'models/adc_config.dart';
export 'models/conversion.dart';
export 'models/direction.dart';
export 'models/linear.dart';
export 'models/surface_speed.dart';
export 'models/thermistor.dart';
export 'models/type_models.dart';
export 'models/voltage.dart';
