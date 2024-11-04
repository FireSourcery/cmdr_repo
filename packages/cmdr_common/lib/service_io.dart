import 'dart:async';

import 'package:collection/collection.dart';

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

  ////////////////////////////////////////////////////////////////////////////////
  /// One-shot Stream
  ////////////////////////////////////////////////////////////////////////////////
  /// getEach, getIterative, getAll
  /// returns as slices of maxBatchSize
  /// Caller locks [keys] from modifications before building slices
  Stream<({Iterable<K> keys, Iterable<V>? values})> getAll(Iterable<K> keys, {Duration delay = const Duration(milliseconds: 1)}) async* {
    for (final slice in keys.slices(maxGetBatchSize ?? keys.length)) {
      yield (keys: slice, values: await getBatch(slice));
      await Future.delayed(delay);
    }
  }

  Stream<({Iterable<(K, V)> pairs, Iterable<S>? statuses})> setAll(Iterable<(K, V)> pairs, {Duration delay = const Duration(milliseconds: 1)}) async* {
    for (final slice in pairs.slices(maxSetBatchSize ?? pairs.length)) {
      yield (pairs: slice, statuses: await setBatch(slice));
      await Future.delayed(delay);
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Periodic Stream
  ////////////////////////////////////////////////////////////////////////////////
  Stream<({Iterable<K> keys, Iterable<V>? values})> pollFixed(Iterable<K> keys, {Duration delay = const Duration(milliseconds: 1)}) async* {
    // since keys are fixed
    final fixedSlices = keys.slices(maxGetBatchSize ?? keys.length);
    while (true) {
      // yield* getAll(keys, delay: delay); // does this create new slices each time?
      for (final slice in fixedSlices) {
        yield (keys: slice, values: await getBatch(slice));
        await Future.delayed(delay);
      }

      // await Future.delayed( ); // an additional delay after each round
    }
  }

  // getters resolve each full iteration of all keys, creates new slices
  Stream<({Iterable<K> keys, Iterable<V>? values})> pollFlex(Iterable<K> Function() keysGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    // var slices;
    while (true) {
      // yield* getAll(keysGetter(), delay: delay);
      // while the getter iterates, the caller must not add/remove from the source
      var slices = keysGetter().slices(maxGetBatchSize ?? keysGetter().length); // can this reuse the same allocated memory for the new slices?
      for (final slice in slices) {
        yield (keys: slice, values: await getBatch(slice));
        await Future.delayed(delay);
      }
    }
  }

  Stream<({Iterable<(K, V)> pairs, Iterable<S>? statuses})> push(Iterable<(K, V)> Function() pairsGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    while (true) {
      // yield* setAll(pairsGetter(), delay: delay);
      var slices = pairsGetter().slices(maxSetBatchSize ?? pairsGetter().length);
      for (final slice in slices) {
        yield (pairs: slice, statuses: await setBatch(slice));
        await Future.delayed(delay);
      }
    }
  }
}
