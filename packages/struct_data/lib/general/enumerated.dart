import 'enum_map.dart';
import 'struct.dart';
export 'enum_map.dart';

// may replace serialable
mixin Enumerated<K extends Enum> on Object implements StructBase<Enumerated<K>, EnumeratedField, Object?> {
  List<EnumeratedField<Object?>> get keys;
  StructData<EnumeratedField, dynamic> get data => this as StructData<EnumeratedField, dynamic>; // data passed to Keys

  // duplicate code until combine mixin is support
  Object? operator [](covariant EnumeratedField key) => data[key];
  void operator []=(covariant EnumeratedField key, Object? value) => data[key] = value;
  Object? fieldOrNull(EnumeratedField key) => data.fieldOrNull(key);
  bool trySetField(EnumeratedField key, Object? value) => data.trySetField(key, value);
  EnumeratedEntry<Object?> field(covariant EnumeratedField key) => data.field(key);
  EnumeratedEntry<R> fieldAs<R>(covariant EnumeratedField<R> key) => data.fieldAs<R>(key) as EnumeratedEntry<R>;
  Iterable<Object?> get values => keys.map((k) => this[k]);
  Iterable<EnumeratedEntry<Object?>> get fields => keys.map((k) => (key: k, value: this[k]));
  StructForm<EnumeratedField, Object?> get _type => StructForm<EnumeratedField, Object?>(keys);

  Map<EnumeratedField, Object?> toMap() => _type.mapWithData(data);

  // Value equality
  @override
  int get hashCode => keys.fold(0, (prev, key) => prev ^ this[key].hashCode);

  /// Value equality: two structures are equal if they share the same keys
  /// reference (same schema) and all corresponding field values are equal.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Enumerated<K>) return false;
    // Keys lists for enum types are const singletons; identity means same schema.
    if (!identical(keys, other.keys)) return false;
    return true;
  }

  @override
  String toString() => '(${keys.map((k) => '$k: ${this[k]}').join(', ')})';
}

// mixin ImmutableEnumerated<S,  K extends Field<Object?>> on Object implements StructBase<S, K, Object?>

// mixin EnumSchema implements Enum, Field<Object?> {
//   // static composible constructor(List<Enum> values)
//   // s
// }
abstract mixin class EnumeratedField<V> implements Enum, Field<V> {
  V getIn(covariant Enumerated struct);
  void setIn(covariant Enumerated struct, V value);
  bool testAccess(covariant Enumerated struct);

  // V? validateType(Enumerated data) => data[this] is V ? data[this] as V : null;

  // bool isTypeOf(Enumerated? value) => value is V;
  // V? validateType(Enumerated? value) => ((value is V) ? value : null);

  Type get type => V;
}

typedef EnumeratedEntry<V> = ({EnumeratedField<V> key, V value});
