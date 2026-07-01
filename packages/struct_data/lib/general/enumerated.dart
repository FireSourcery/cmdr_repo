import 'enum_map.dart';
import 'struct.dart';
export 'enum_map.dart';

// may replace serialable
mixin Enumerated<K extends EnumeratedField<Object?>> on Object implements StructBase<Enumerated<K>, K, Object?> {
  List<K> get keys;
  StructData<K, dynamic> get data => this as StructData<K, dynamic>; // data passed to Keys

  // duplicate code until combine mixin is support
  Object? operator [](covariant K key) => data[key];
  void operator []=(covariant K key, Object? value) => data[key] = value;
  Object? fieldOrNull(K key) => data.fieldOrNull(key);
  bool trySetField(K key, Object? value) => data.trySetField(key, value);

  field(covariant K key) => data.field(key);

  fieldAs<R>(covariant EnumeratedField<R> key) => data.fieldAs<R>(key);
  Iterable<Object?> get values => keys.map((k) => this[k]);
  get fields => keys.map((k) => (key: k, value: this[k]));
  StructForm<K, Object?> get _type => StructForm<K, Object?>(keys);

  Map<K, Object?> toMap() => _type.mapWithData(data);

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

  String get groupName => runtimeType.toString();

  // V? validateType(Enumerated data) => data[this] is V ? data[this] as V : null;

  // bool isTypeOf(Enumerated? value) => value is V;
  // V? validateType(Enumerated? value) => ((value is V) ? value : null);

  Type get type => V;
}

// typedef EnumeratedEntry<V> = ({EnumeratedField<V> key, V value});
