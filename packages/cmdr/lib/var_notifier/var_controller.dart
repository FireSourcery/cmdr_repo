import 'dart:async';
import 'dart:math';

import 'service_io.dart';
import 'var_cache.dart';
import 'var_key.dart';
import 'var_notifier.dart';

/// [VarRepo]/[VarCache] with [Serivce]
///
class const VarCacheController({required final VarCache cache, required final ServiceIO<int, int, int> protocolService}) {
  void dispose() => cache.dispose();

  ///
  /// Collective Read Vars `Fetch/Load`
  ///

  /// todo statuses
  /// cache.updateByDataSlice
  VarStatus? _onReadSlice(ServiceGetSlice<int, int> slice) {
    if (slice.values == null) return null; // no response error
    cache.updateByData(slice.keys, slice.values!);
    return VarStatusDefault.success;
  }

  Iterable<int> _ids(Iterable<VarKey>? keys) => keys?.map((e) => e.value) ?? cache.dataIds;

  /// Read iteratively, batch operation per slice. Each slice is 1 packet transaction.
  /// Returns first meta status error, e.g. not received. A Var error status may indicate some UI visualization.
  /// alternatively selectable return on error
  Future<VarStatus?> readAll([Iterable<VarKey>? keys]) async {
    await for (final event in protocolService.getAll(_ids(keys))) {
      if (_onReadSlice(event) == null) return null;
    }
    return VarStatusDefault.success;
  }

  /// overwrite user changes, e.g. on explicit fetch
  Future<VarStatus?> readOverwrite([Iterable<VarKey>? keys]) async {
    if (await readAll(keys) case final status when status == null || status.isError) return status;
    // todo unify
    for (final v in keys == null ? cache.varEntries : cache.varsOf(keys)) {
      v.discardUserChanges(); // device data wins on explicit fetch
    }
    return VarStatusDefault.success;
  }

  ///
  /// Collective Write Vars `Send/Update`
  ///
  VarStatus? _onWriteSlice(ServiceSetSlice<int, int, int> slice) {
    if (slice.statuses == null) return null; // no response error
    return cache.updateByDataResponse(slice.pairs, slice.statuses!); // clears scheduled write
  }

  // return first error, alternatively continue collecting errors in cache
  Future<VarStatus?> _write(Iterable<(int, int)> pairs) async {
    await for (final event in protocolService.setAll(pairs)) {
      if (_onWriteSlice(event) case final status when status == null || status.isError) return status;
    }
    return VarStatusDefault.success;
  }

  Iterable<(int, int)> _pairs(Iterable<VarKey>? keys) => cache.dataPairsOf(keys ?? cache.varKeys);

  // write all via batches
  // optionally select keys or both keys and values
  Future<VarStatus?> writeAll([Iterable<VarKey>? keys]) async => _write(_pairs(keys));

  // separate method, as updated involves varNotifier state
  Future<VarStatus?> writeUpdated() async {
    return _write(cache.dataPairsUpdatedByView);
  }

  ///
  /// `Single` Read/Write Var
  ///
  // fetch
  Future<V?> read<V>(VarKey<V> key) async {
    if (await protocolService.get(key.value) case int value) {
      cache[key]?.updateByData(value);
      return cache[key]?.value as V?;
    }
    return null;
  }

  // send
  Future<VarStatus?> write<V>(VarKey<V> key) async {
    if (cache[key] case VarNotifier notifier) {
      final (id, sent) = notifier.dataPair;
      if (await protocolService.set(id, sent) case int status) return (notifier..applyWriteResponse(sent, status)).status;
    }
    return null;
  }
}

/// `Poll/Push Periodic Process Stream`
// A var should not be in both streams, that would be a loop back.
// A var may be both read and write, but not both periodic.
//   e.g. periodic read, but write on update only
// returning on a yield should complete a send/receive request, so there cannot be send/receive mismatch
// Streams may be per cache, or partial selection
//
// if an entry is removed from the cache map, listener will still exist synced with previously allocated Var.
// it will no longer be updated by Streams.
class VarStreamController({required super.cache, required super.protocolService}) extends VarCacheController {
  final List<int> _readBuffer = []; // reuse allocation, no new List each cycle
  final List<(int, int)> _writeBuffer = [];
  final Set<VarPollingScope> _scopes = {};

  @override
  void dispose() {
    end().whenComplete(() => cache.dispose());
  }

  VarPollingScope createScope(Iterable<VarKey> keys) {
    final scope = VarPollingScope._(this, keys);
    _scopes.add(scope);
    return scope;
  }

  void _releaseScope(VarPollingScope scope) => _scopes.remove(scope);

  // stream will call slices creating a new list, at the beginning of each multi-batch operation
  // while this iterator is accessed, view must not add or remove keys, either by lock or preallocate cache
  Iterable<VarKey> get _readKeys => cache.varEntries.where((e) => (e.varKey.isPolling && e.isObserved) || _scopes.any((s) => s._keys.contains(e.varKey))).map((e) => e.varKey);
  List<int> _readKeysGetter() => (_readBuffer..clear())..addAll(cache.dataIdsOf(_readKeys));

  Iterable<VarKey> get _writeKeys => cache.varEntries.where((e) => e.varKey.isPushing || e.hasPendingChanges).map((e) => e.varKey);
  List<(int, int)> _writePairsGetter() => (_writeBuffer..clear())..addAll(cache.dataPairsOf(_writeKeys));

  Stream<ServiceGetSlice<int, int>> get _readStream => protocolService.pollFlex(_readKeysGetter);
  Stream<ServiceSetSlice<int, int, int>> get _writeStream => protocolService.push(_writePairsGetter);

  StreamSubscription? pollSubscription;
  StreamSubscription? pushSubscription;

  void Function(Object error)? _onError;

  /// The wait before a stream restarts after its first error in a row; each further error doubles it, up to 32 times.
  static const Duration restartDelay = Duration(milliseconds: 50);
  int _pollErrors = 0; // in a row, until a slice
  int _pushErrors = 0;

  /// The restart policy of both streams: reports the first error in a row, and starts [stream] after the backoff.
  /// The wait belongs to the replacement subscription, so [end] acts on it.
  Stream<T> _restart<T>(Stream<T> stream, Object error, int errors) {
    if (errors == 1) _onError?.call(error);
    return Stream.fromFuture(Future.delayed(restartDelay * (1 << min(errors - 1, 5)))).asyncExpand((_) => stream);
  }

  // cancelOnError: true cancels the dead subscription, then re-subscribe with a fresh stream. without it, the dead one keeps polling beside its replacement
  // [end] nulls subscriptions, so the null check prevents restart after intentional stop
  void _restartPollOnError(Object error) {
    if (pollSubscription == null) return;
    pollSubscription = _restart(_readStream, error, ++_pollErrors).listen(_onPollSlice, onError: _restartPollOnError, cancelOnError: true);
  }

  void _restartPushOnError(Object error) {
    if (pushSubscription == null) return;
    pushSubscription = _restart(_writeStream, error, ++_pushErrors).listen(_onPushSlice, onError: _restartPushOnError, cancelOnError: true);
  }

  // a slice ends the errors in a row
  void _onPollSlice(ServiceGetSlice<int, int> slice) {
    _pollErrors = 0;
    _onReadSlice(slice);
  }

  void _onPushSlice(ServiceSetSlice<int, int, int> slice) {
    _pushErrors = 0;
    _onWriteSlice(slice);
  }

  /// [onError] gets the first error in a row of each stream; the stream restarts after [restartDelay], backing off.
  bool begin({void Function(Object error)? onError}) {
    if (!protocolService.isConnected) return false;
    _onError = onError;
    pollSubscription ??= _readStream.listen(_onPollSlice, onError: _restartPollOnError, cancelOnError: true);
    pushSubscription ??= _writeStream.listen(_onPushSlice, onError: _restartPushOnError, cancelOnError: true);
    return true;
  }

  Future<void> end() async {
    final cancels = [pollSubscription?.cancel(), pushSubscription?.cancel()];
    pollSubscription = pushSubscription = null; // before the cancels land: a begin meanwhile starts fresh streams
    _pollErrors = _pushErrors = 0; // a burst ends with its run
    await Future.wait(cancels.nonNulls);
  }

  /// Ends the streams for the duration of [action], and begins them again after if they ran.
  ///
  /// A long link operation — a full config write, a flash save — otherwise interleaves with the
  /// periodic reads. Ended, not paused: a paused stream would keep its slice in flight until it resumed,
  /// a view into a reply buffer the action reuses.
  Future<T> hold<T>(Future<T> Function() action) async {
    final wasRunning = !isStopped;
    unawaited(end()); // lands at the next yield: the read in flight finishes, its slice dropped
    try {
      return await action();
    } finally {
      if (wasRunning) begin(onError: _onError);
    }
  }

  bool get isStopped => (pollSubscription == null && pushSubscription == null);
}

class VarPollingScope._(final VarStreamController _controller, Iterable<VarKey> keys) {
  this : _keys = _readable(keys);
  Set<VarKey> _keys;

  static Set<VarKey> _readable(Iterable<VarKey> keys) => Set.unmodifiable(keys.where((e) => !e.isWriteOnly));

  void update(Iterable<VarKey> keys) => _keys = _readable(keys);

  void dispose() => _controller._releaseScope(this);
}

///
/// if a single var update is required. Batch updates via VarCacheController handles most cases.
/// call service immediately
/// the response updates [varNotifier]'s value and status: the cache's entry, where it was resolved from one
///
class const VarSingleController<V>({required final VarNotifier<V> varNotifier, required final ServiceIO<int, int, int> protocolService}) {
  // async send request id, then receiving value
  Future<V?> fetch() async {
    if (await protocolService.get(varNotifier.dataKey) case int data) {
      return (varNotifier..updateByData(data)).value;
    }
    return null;
  }

  // async send value, then receiving status
  Future<VarStatus?> send([V? value]) async {
    if (value != null) varNotifier.updateByView(value);
    final (key, sent) = varNotifier.dataPair;
    if (await protocolService.set(key, sent) case int status) return (varNotifier..applyWriteResponse(sent, status)).status;
    return null;
  }
}

// extension on VarCacheController to provide single var access
// maps to protocol service directly, not through the batch; the response updates the notifier's value and status.
// VarSingleController<V> single<V>(VarNotifier<V> notifier) => VarSingleController(varNotifier: notifier, protocolService: protocolService);
