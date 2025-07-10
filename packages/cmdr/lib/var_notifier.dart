/// Variable notification and caching library for the CMDR package.
///
/// This library provides a reactive system for managing embedded device variables
/// with real-time updates, caching, and context management.
///
/// ## Features
///
/// - Real-time variable monitoring
/// - Automatic caching and persistence
/// - Context-aware variable management
/// - Flutter integration with inherited widgets
///
/// ## Usage
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
library cmdr.var_notifier;

// Core variable notifier classes
export 'var_notifier/var_notifier.dart';

// Context management
export 'var_notifier/var_context.dart';
