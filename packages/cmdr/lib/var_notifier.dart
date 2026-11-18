/// Variable notification and caching library for the CMDR package.
///
/// This library provides a reactive system for managing embedded device variables
/// with real-time updates, caching, and context management.
///
/// ```dart
/// import 'package:cmdr/var_notifier.dart';
///
/// // Use variable context
/// VarKeyContext(
///   contextTypeOfVarKey: (key) => key.contextType,
///   child: MyWidget(),
/// )
/// ```
library;

// Core variable notifier classes
export 'var_notifier/var_notifier.dart';

export 'var_notifier/service_io.dart';

// Context management
export 'var_notifier/var_context.dart';
