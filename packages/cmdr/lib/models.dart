/// Data models library for the CMDR package.
///
/// This library provides data models and type definitions used throughout
/// the embedded device communication system.
///
/// ```dart
/// import 'package:cmdr/models.dart';
///
/// // Use models
/// const divider = VDivider(47000, 4700);
/// const battery = VBattery(42.0, 54.6);
/// const adc = AdcConfig(3.3, 4095);
/// ```
library;

// Core models
export 'models/adc_config.dart';
export 'models/surface_speed.dart';
export 'models/thermistor.dart';
export 'models/voltage.dart';
