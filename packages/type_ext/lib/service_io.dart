import 'dart:async';

import 'package:collection/collection.dart';

import 'basic_types.dart';

typedef ServiceGetSlice<K, V> = ({Iterable<K> keys, Iterable<V>? values});
typedef ServiceSetSlice<K, V, S> = ({Iterable<(K, V)> pairs, Iterable<S>? statuses});

///
/// Common interface for mapping key-value paradigm services
/// `<Key, Value, Status>`
///
// implements IOSink
// MappedService
abstract mixin class ServiceIO<K, V, S> {
  const ServiceIO();

  bool get isConnected;
  // FutureOr<S?> connect();
  // FutureOr<S?> disconnect();

  FutureOr<V?> get(K key);
  Future<S?> set(K key, V value);

  FutureOr<Iterable<V>?> getBatch(Iterable<K> keys);
  Future<Iterable<S>?> setBatch(Iterable<(K, V)> pairs);

  int? get maxGetBatchSize;
  int? get maxSetBatchSize;

  // for single status response
  // FutureOr<(S?, Iterable<V>?)> getBatchWithMeta(Iterable<K> keys);
  // Future<(S?, Iterable<S>?)> setBatchWithMeta(Iterable<(K, V)> pairs);

  /// Slices maps `Batch` return with `Batch` input
  Future<ServiceGetSlice<K, V>> _getSlice(List<K> keysSlice) async => (keys: keysSlice, values: await getBatch(keysSlice));
  Future<ServiceSetSlice<K, V, S>> _setSlice(List<(K, V)> pairsSlice) async => (pairs: pairsSlice, statuses: await setBatch(pairsSlice));

  // loop each slice with delay between each Batch
  Stream<ServiceGetSlice<K, V>> _getSlices(Iterable<List<K>> keysSlices, {Duration delay = const Duration(milliseconds: 1)}) async* {
    for (final slice in keysSlices) {
      yield await _getSlice(slice);
      await Future.delayed(delay);
    }
  }

  Stream<ServiceSetSlice<K, V, S>> _setSlices(Iterable<List<(K, V)>> pairsSlices, {Duration delay = const Duration(milliseconds: 1)}) async* {
    for (final slice in pairsSlices) {
      yield await _setSlice(slice);
      await Future.delayed(delay);
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// One-Shot Stream
  /// Splits input/output into slices of [maxBatchSize]
  /// Caller locks [keys] from modifications before building slices
  ////////////////////////////////////////////////////////////////////////////////
  Stream<ServiceGetSlice<K, V>> getAll(Iterable<K> keys, {Duration delay = const Duration(milliseconds: 1)}) {
    if (keys.isEmpty) return const Stream.empty();
    return _getSlices(keys.slices(maxGetBatchSize ?? keys.length), delay: delay);
  }

  Stream<ServiceSetSlice<K, V, S>> setAll(Iterable<(K, V)> pairs, {Duration delay = const Duration(milliseconds: 1)}) {
    if (pairs.isEmpty) return const Stream.empty();
    return _setSlices(pairs.slices(maxSetBatchSize ?? pairs.length), delay: delay);
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Periodic Stream
  // getters resolve each full iteration of all keys, creates new slices
  // while the getter iterates, the caller must not add/remove from the source
  ////////////////////////////////////////////////////////////////////////////////
  Stream<ServiceGetSlice<K, V>> pollFixed(Iterable<K> keys, {Duration delay = const Duration(milliseconds: 1)}) async* {
    if (keys.isEmpty) return; // input does not change
    while (true) {
      yield* getAll(keys, delay: delay);
      // await Future.delayed(); // an additional delay after each round
    }
  }

  Stream<ServiceGetSlice<K, V>> pollFlex(Iterable<K> Function() keysGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    while (true) {
      yield* getAll(keysGetter(), delay: delay);
    }
    // can this reuse the same allocated memory buffer for the new slices?
    // while (true) {
    // var keys = keysGetter();
    // var slices = keys.slices(maxGetBatchSize ?? keys.length);
    // yield* _getSlices(slices, delay: delay);
    // }
  }

  Stream<ServiceSetSlice<K, V, S>> push(Iterable<(K, V)> Function() pairsGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    while (true) {
      yield* setAll(pairsGetter(), delay: delay);
    }
  }

  // Stream<ServiceSetSlice<K, V, S>> pushFixed(Iterable<K> keys, Iterable<V> Function() valuesGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
  //   if (keys.isEmpty) return;
  //   while (true) {
  //     yield* setAll(Iterable.generate(keys.length, (index) => (keys.elementAt(index), valuesGetter().elementAt(index))), delay: delay);
  //   }
  // }
}

class ServicePollStreamHandler<K, V, S> extends ServiceStreamHandler<ServiceGetSlice<K, V>> {
  ServicePollStreamHandler(
    this.protocolService,
    this.inputGetter,
    void Function(ServiceGetSlice<K, V> data) onDataSlice,
  ) : super(protocolService.pollFlex(inputGetter, delay: const Duration(milliseconds: 5)), onDataSlice);

  final ServiceIO<K, V, S> protocolService;
  final Iterable<K> Function() inputGetter;
  // Stream<ServiceSetSlice> get _asPushStream => protocolService.push(inputGetter, delay: const Duration(milliseconds: 5));
  // Stream<ServiceGetSlice> get _asPollStream => protocolService.pollFlex(inputGetter, delay: const Duration(milliseconds: 5));
}

class ServicePushStreamHandler<K, V, S> extends ServiceStreamHandler<ServiceSetSlice<K, V, S>> {
  ServicePushStreamHandler(
    this.protocolService,
    this.inputGetter,
    void Function(ServiceSetSlice<K, V, S> data) onDataSlice,
  ) : super(protocolService.push(inputGetter, delay: const Duration(milliseconds: 5)), onDataSlice);

  final ServiceIO<K, V, S> protocolService;
  final Iterable<(K, V)> Function() inputGetter;
}

class ServiceStreamHandler<T> {
  ServiceStreamHandler(
    this.stream, // or pass service
    this.onDataSlice,
  );

  final Stream<T> stream;
  final void Function(T data) onDataSlice;

  StreamSubscription? streamSubscription;
  bool get isStopped => streamSubscription == null;

  StreamSubscription? begin() {
    if (!isStopped) return null;
    return streamSubscription = stream.listen(onDataSlice);
  }

  Future<void> end() async => streamSubscription?.cancel().whenComplete(() => streamSubscription = null);
  Future<void> restart() async => end().whenComplete(() => begin());
}

// IdKey, EntityKey, DataKey, FieldKey, VarKey,
// ServiceKey for retrieving data of dynamic type from external source and casting
abstract mixin class ServiceKey<K, V> implements UnionValueKey<V> {
  // VarKey
  K get key;
  String get label;
  // Stringifier? get valueStringifier;

  // a serviceKey can directly access the value with a provided reference to service
  // ServiceIO? get service;
  // V? get value => service?.get(keyValue);
  // alternatively as V always return a cached value
  V? get value;
  set value(V? newValue);
  Future<bool> updateValue(V value);
  Future<V?> loadValue();
  String get valueString;

  // Type get type;
  TypeKey<V> get valueType => TypeKey<V>();
}
