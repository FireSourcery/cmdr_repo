// with UnionValueKey<V>
import 'dart:async';

abstract interface class Setting<V> {
  // String get key;

  List<V>? get valueRange; // non-null for Enum types, or string options
  ({num min, num max})? get numLimits; // null for non-num types
  // T? get defaultValue;

  String get label; // key label
  String get valueString;
  String? get tip;

  Type get type;
  V? get value; //alternatively return default on no load
  set value(V? value);
  Future<bool> update(V value);
  Future<V?> load();

  R callWithType<R>(R Function<G>() callback);
}
