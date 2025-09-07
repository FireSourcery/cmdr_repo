import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

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

  ////////////////////////////////////////////////////////////////////////////////
  /// One-Shot Stream
  /// Splits input/output into slices of [maxBatchSize]
  /// Caller locks [keys] from modifications before building slices
  ////////////////////////////////////////////////////////////////////////////////
  Stream<ServiceGetSlice<K, V>> getAll(Iterable<K> keys, {Duration delay = const Duration(milliseconds: 1)}) {
    return _getSlices(keys.slices(maxGetBatchSize ?? keys.length), delay: delay);
  }

  Stream<ServiceSetSlice<K, V, S>> setAll(Iterable<(K, V)> pairs, {Duration delay = const Duration(milliseconds: 1)}) {
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
      // await Future.delayed(perIterationDelay); // an additional delay after each round
    }
  }

  Stream<ServiceGetSlice<K, V>> pollFlex(Iterable<K> Function() keysGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    while (true) {
      var keys = keysGetter();
      if (keys.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 50)); // subsitute time of 1 iteration
        yield* const Stream.empty(); // so empty keys can be canceled
      } else {
        yield* getAll(keys, delay: delay);
      }
    }

    // List<K> keys = []; // Reusable buffer
    // keys.setAll(0, keysGetter());
    // var sliceLength = maxGetBatchSize ?? keys.length;
    // yield* _getSlices(keys.mapIndexed((index, key) => ListSlice(keys, index * sliceLength, index * sliceLength + sliceLength)), delay: delay);
  }

  Stream<ServiceSetSlice<K, V, S>> push(Iterable<(K, V)> Function() pairsGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
    while (true) {
      var pairs = pairsGetter();
      if (pairs.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 50));
        yield* const Stream.empty(); //
      } else {
        yield* setAll(pairs, delay: delay);
      }
    }
  }

  // Stream<ServiceSetSlice<K, V, S>> pushFixed(Iterable<K> keys, Iterable<V> Function() valuesGetter, {Duration delay = const Duration(milliseconds: 1)}) async* {
  //   if (keys.isEmpty) return;
  //   while (true) {
  //     yield* setAll(Iterable.generate(keys.length, (index) => (keys.elementAt(index), valuesGetter().elementAt(index))), delay: delay);
  //   }
  // }
}

extension ListBuffer<T> on List<List<T>> {
  void setSlices(Iterable<List<T>> newSlices) {
    clear();
    addAll(newSlices);
  }
}

// class ServicePollStreamHandler<K, V, S> extends ServiceStreamHandler<ServiceGetSlice<K, V>> {
//   ServicePollStreamHandler(this.protocolService, this.inputGetter, super.onDataSlice);

//   final ServiceIO<K, V, S> protocolService;
//   final Iterable<K> Function() inputGetter;

//   @protected
//   @override
//   Stream<ServiceGetSlice<K, V>> get stream => protocolService.pollFlex(inputGetter, delay: const Duration(milliseconds: 1));
// }

// class ServicePushStreamHandler<K, V, S> extends ServiceStreamHandler<ServiceSetSlice<K, V, S>> {
//   ServicePushStreamHandler(this.protocolService, this.inputGetter, super.onDataSlice);

//   final ServiceIO<K, V, S> protocolService;
//   final Iterable<(K, V)> Function() inputGetter;

//   @protected
//   @override
//   Stream<ServiceSetSlice<K, V, S>> get stream => protocolService.push(inputGetter, delay: const Duration(milliseconds: 1));
// }

// abstract class ServiceStreamHandler<T> {
//   ServiceStreamHandler(this.onDataSlice);

//   // final ServiceIO protocolService;
//   // final Iterable<T> Function() inputGetter;

//   // createStream()
//   @protected
//   Stream<T> get stream; // creates a new stream, call from begin() only

//   final void Function(T data) onDataSlice;

//   StreamSubscription? streamSubscription;
//   bool get isStopped => streamSubscription == null;

//   StreamSubscription? begin() {
//     if (!isStopped) return null;
//     return streamSubscription = stream.listen(onDataSlice);
//   }

//   // Future<void> get stopped => streamSubscription?.asFuture() ?? Future.value();

//   Future<void> end() async => streamSubscription?.cancel().whenComplete(() => streamSubscription = null);
//   Future<void> restart() async => end().whenComplete(() => begin());
// }
