import 'dart:async';

import 'package:collection/collection.dart';

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

  FutureOr<V?> get(K key);
  FutureOr<S?> set(K key, V value);

  int? get maxGetBatchSize;
  int? get maxSetBatchSize;

  FutureOr<Iterable<V>?> getBatch(Iterable<K> keys);
  FutureOr<Iterable<S>?> setBatch(Iterable<(K, V)> pairs);

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

  ///
  /// One-Shot Stream
  /// Splits input/output into slices of [maxBatchSize]
  /// Caller locks [keys] from modifications before building slices
  ///
  /// known List uses `List.slices` instead
  Stream<ServiceGetSlice<K, V>> getAll(Iterable<K> keys, {Duration delay = const Duration(milliseconds: 1)}) {
    return _getSlices(keys.slices(maxGetBatchSize ?? keys.length), delay: delay);
  }

  Stream<ServiceSetSlice<K, V, S>> setAll(Iterable<(K, V)> pairs, {Duration delay = const Duration(milliseconds: 1)}) {
    return _setSlices(pairs.slices(maxSetBatchSize ?? pairs.length), delay: delay);
  }

  ///
  /// Periodic Stream
  // getters resolve each full iteration of all keys, creates new slices
  // while the getter iterates, the caller must not add/remove from the source
  ///
  Stream<ServiceGetSlice<K, V>> pollFixed(Iterable<K> keys, {Duration delay = const Duration(milliseconds: 1)}) async* {
    if (keys.isEmpty) return; // input does not change
    while (true) {
      yield* getAll(keys, delay: delay);
      // await Future.delayed(perIterationDelay); // an additional delay after each round
    }
  }

  /// caller optimize, if keys is iterable allocates slices, if list sliced with list view.
  Stream<ServiceGetSlice<K, V>> pollFlex(Iterable<K> Function() keysGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    while (true) {
      var keys = keysGetter();
      if (keys.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 50)); // subsitute time of 1 iteration
        continue;
      } else {
        yield* getAll(keys, delay: delay);
      }
      // await Future.delayed(perIterationDelay); // an additional delay after each round
    }
  }

  Stream<ServiceSetSlice<K, V, S>> push(Iterable<(K, V)> Function() pairsGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    while (true) {
      var pairs = pairsGetter();
      if (pairs.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 50));
        continue;
      } else {
        yield* setAll(pairs, delay: delay);
      }
    }
  }
}

class ServicePollStreamHandler<K, V, S> extends ServiceStreamHandler<ServiceGetSlice<K, V>> {
  ServicePollStreamHandler(this.protocolService, this.inputGetter, super.onDataSlice);

  final ServiceIO<K, V, S> protocolService;
  final Iterable<K> Function() inputGetter;

  @override
  Stream<ServiceGetSlice<K, V>> get stream => protocolService.pollFlex(inputGetter, delay: const Duration(milliseconds: 1));
}

class ServicePushStreamHandler<K, V, S> extends ServiceStreamHandler<ServiceSetSlice<K, V, S>> {
  ServicePushStreamHandler(this.protocolService, this.inputGetter, super.onDataSlice);

  final ServiceIO<K, V, S> protocolService;
  final Iterable<(K, V)> Function() inputGetter;

  @override
  Stream<ServiceSetSlice<K, V, S>> get stream => protocolService.push(inputGetter, delay: const Duration(milliseconds: 1));
}

abstract class ServiceStreamHandler<T> {
  ServiceStreamHandler(this.onDataSlice);

  // createStream()
  Stream<T> get stream; // creates a new stream, call from begin() only

  final void Function(T data) onDataSlice;

  StreamSubscription? streamSubscription;
  bool get isStopped => streamSubscription == null;

  void _restartOnError(Object error) {
    if (streamSubscription == null) return; // intentional stop, do not restart
    final wasPaused = streamSubscription?.isPaused ?? false;
    streamSubscription = stream.listen(onDataSlice, onError: _restartOnError);
    if (wasPaused) streamSubscription?.pause();
  }

  StreamSubscription listenWithRestart() {
    return streamSubscription ??= stream.listen(onDataSlice, onError: _restartOnError);
  }

  Future<void> end() async => streamSubscription?.cancel().whenComplete(() => streamSubscription = null);

  // StreamSubscription? begin() {
  //   if (!isStopped) return null;
  //   return streamSubscription = stream.listen(onDataSlice);
  // }
  // Future<void> restart() async => end().whenComplete(() => begin());
}

// class StreamSubscriptionWith<T> {
//   StreamSubscriptionWith(this.stream, this.onDataSlice);

//   final Stream<T> Function() streamFactory;
//   final void Function(T data) onDataSlice;

//   StreamSubscription<T>? subscription;

//   void _restartOnError(Object error) {
//     if (subscription == null) return; // intentional stop, do not restart
//     final wasPaused = subscription?.isPaused ?? false;
//     subscription = stream.listen(onDataSlice, onError: _restartOnError);
//     if (wasPaused) subscription?.pause();
//   }
// }

// extension StreamExtensions<T> on Stream<T> {
//   StreamSubscriptionWith<T> listenWithRestart(void Function(T) onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
//     StreamSubscriptionWith<T> subscriptionWith = StreamSubscriptionWith(this, onData);

//     subscriptionWith.subscription = listen(onData, onError: subscriptionWith._restartOnError, onDone: onDone, cancelOnError: cancelOnError);
//     return subscriptionWith;
//   }
// }
