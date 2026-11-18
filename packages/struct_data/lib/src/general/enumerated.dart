import 'struct.dart';
export 'enum_map.dart';

// `StructForm<EnumeratedField>(.values)(enumeratedData).toMap();`
typedef Enumerated<K extends EnumeratedField<Object?>> = StructBase<K, Object?>;

// alternatively wrap a transport descriptor instead of implementing it
abstract mixin class EnumeratedField<V>() implements Enum, Field<V> {
  // V call(covariant Enumerated struct);
  @override
  V getIn(covariant Enumerated struct);
  // default implementation
  @override
  void setIn(covariant Enumerated struct, V value) => throw UnimplementedError();
  @override
  bool testAccess(covariant Enumerated struct) => true;

  String get groupName => runtimeType.toString();

  // V? validateType(Enumerated data) => data[this] is V ? data[this] as V : null;
  // bool isTypeOf(Enumerated? value) => value is V;

  Type get type => V;
}

// typedef EnumeratedEntry<V> = ({EnumeratedField<V> key, V value});
