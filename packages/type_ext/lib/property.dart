import 'basic_types.dart';

/// [PropertyFilter]
// filterable property
// encapsulated for selection
// implements Enum for List
// PropertyOf<T>
abstract mixin class PropertyFilter<T> {
  const PropertyFilter();

  ValueTest<T> get test;

  Iterable<T> call(Iterable<T> input) => input.where(test);
  Iterable<T> Function(Iterable<T> input) get asIterableFilter => call;
}

extension WhereFilter<T> on Iterable<T> {
  Iterable<T> havingProperty(PropertyFilter<T>? property) => property?.call(this) ?? this;

  // Iterable<T> havingTyped<P extends PropertyFilter<T>>(Iterable<List<PropertyFilter<T>>> allProperties, P filter) {
  Iterable<T> havingTyped<P extends PropertyFilter<T>>(Iterable<List<PropertyFilter<T>>> allProperties) {
    return allProperties.whereType<List<P>>().whereType<P>().singleOrNull?.call(this) ?? this;
  }
}

extension MapExt<K, V extends Object> on Map<K, V> {
  Iterable<V> eachOf(Iterable<K> keys) => keys.map<V?>((e) => this[e]).nonNulls;
  Iterable<V> having(PropertyFilter<K>? property) => eachOf(keys.havingProperty(property));
}
