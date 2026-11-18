import 'package:flutter/foundation.dart';

import 'stringifier.dart';

/// [ValueViewer<V>]
/// The read side of a single value: what a widget viewing one value takes as a parameter, never implements, so
/// composites pass one viewer to each child. [IOFieldConfig] adds the write side and the [IOField] options;
/// [VarIOFieldConfig] derives both from a [VarNotifier].
///
/// [valueStringifier] takes a [V], so a `ValueViewer<double>` read as a `ValueViewer<num>` throws on it: a widget
/// for any num either reads only the members that return a value, or is generic in `V extends num`.
abstract interface class ValueViewer<V>() {
  /// Separate from [valueGetter], for a value derived from what notifies.
  Listenable get valueListenable;
  ValueGetter<V> get valueGetter;
  Stringifier<V>? get valueStringifier;
  ValueGetter<bool>? get errorGetter; // true on error
  ({num min, num max})? get valueNumLimits;
  String? get label;
  String? get units;
  String get tip;
}
