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

  // for single status response
  // FutureOr<(S?, Iterable<V>?)> getBatchWithMeta(Iterable<K> keys);
  // Future<(S?, Iterable<S>?)> setBatchWithMeta(Iterable<(K, V)> pairs);

  int? get maxGetBatchSize;
  int? get maxSetBatchSize;

  Future<ServiceGetSlice<K, V>> _getSlice(Iterable<K> keysSlice) async => (keys: keysSlice, values: await getBatch(keysSlice));

  Stream<ServiceGetSlice<K, V>> _getSlices(Iterable<List<K>> keySlices, {Duration delay = const Duration(milliseconds: 1)}) async* {
    for (final slice in keySlices) {
      yield await _getSlice(slice);
      await Future.delayed(delay);
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// One-shot Stream
  ////////////////////////////////////////////////////////////////////////////////
  /// getEach, getIterative, getAll
  /// returns as slices of maxBatchSize
  /// Caller locks [keys] from modifications before building slices
  Stream<ServiceGetSlice<K, V>> getAll(Iterable<K> keys, {Duration delay = const Duration(milliseconds: 1)}) => _getSlices(keys.slices(maxGetBatchSize ?? keys.length));

  Stream<({Iterable<(K, V)> pairs, Iterable<S>? statuses})> setAll(Iterable<(K, V)> pairs, {Duration delay = const Duration(milliseconds: 1)}) async* {
    for (final slice in pairs.slices(maxSetBatchSize ?? pairs.length)) {
      yield (pairs: slice, statuses: await setBatch(slice));
      await Future.delayed(delay);
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Periodic Stream
  ////////////////////////////////////////////////////////////////////////////////
  Stream<ServiceGetSlice<K, V>> pollFixed(Iterable<K> keys, {Duration delay = const Duration(milliseconds: 1)}) async* {
    final fixedSlices = keys.slices(maxGetBatchSize ?? keys.length);
    while (true) {
      yield* _getSlices(fixedSlices, delay: delay);
      // await Future.delayed( ); // an additional delay after each round
    }
  }

  // getters resolve each full iteration of all keys, creates new slices
  Stream<ServiceGetSlice<K, V>> pollFlex(Iterable<K> Function() keysGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    while (true) {
      yield* getAll(keysGetter(), delay: delay); // while the getter iterates, the caller must not add/remove from the source
      // var slices = keysGetter().slices(maxGetBatchSize ?? keysGetter().length); // can this reuse the same allocated memory buffer for the new slices?
      // for (final slice in slices) {
      //   yield (keys: slice, values: await getBatch(slice));
      //   await Future.delayed(delay);
      // }
    }
  }

  Stream<({Iterable<(K, V)> pairs, Iterable<S>? statuses})> push(Iterable<(K, V)> Function() pairsGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    while (true) {
      yield* setAll(pairsGetter(), delay: delay);
      // var slices = pairsGetter().slices(maxSetBatchSize ?? pairsGetter().length);
      // for (final slice in slices) {
      //   yield (pairs: slice, statuses: await setBatch(slice));
      //   await Future.delayed(delay);
      // }
    }
  }
}

class ServiceStreamHandler {
  // ServiceStreamHandler();
  ServiceStreamHandler.polling(
    this.keysGetter,
    this.stream, // or pass service
    this.onDataSlice,
  );

  Iterable Function() keysGetter;
  Stream stream;
  void Function(dynamic event) onDataSlice;

  // Iterable<(int, int)> _writePairs()
  // Stream<({Iterable<(int, int)> pairs, Iterable<int>? statuses})> get _asPushStream => protocolService.push(keysGetter, delay: const Duration(milliseconds: 5));

  StreamSubscription? streamSubscription;
  bool get isStopped => streamSubscription == null;

  StreamSubscription? begin([Iterable? keys]) {
    if (keysGetter().isEmpty) return null;
    if (!isStopped) return null;
    // return _writeStream.listen(_onWriteSlice);
    // return listenWith(stream, onDataSlice);
    return streamSubscription = stream.listen(onDataSlice);
  }

  StreamSubscription listenWith<T>(Stream<T> stream, void Function(T)? onData) => streamSubscription = stream.listen(onData);

  Future<void> end() async => streamSubscription?.cancel().whenComplete(() => streamSubscription = null);
  Future<void> restart<T>(Stream<T> stream, void Function(T)? onData) async => end().whenComplete(() => listenWith<T>(stream, onData));
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
