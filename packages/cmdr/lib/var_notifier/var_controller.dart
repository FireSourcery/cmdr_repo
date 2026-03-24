import 'dart:async';

import 'var_notifier.dart';
import 'service_io.dart';
import 'var_cache.dart';

/// [VarRepo]/[VarCache] with [Serivce]
///
class VarCacheController {
  const VarCacheController({required this.cache, required this.protocolService});

  final VarCache cache;
  final ServiceIO<int, int, int> protocolService;

  void dispose() => cache.dispose();

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Read Vars `Fetch/Load`
  ////////////////////////////////////////////////////////////////////////////////

  /// todo statuses
  // change multi tto VarHandlerStatus?
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

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Write Vars `Send/Update`
  ////////////////////////////////////////////////////////////////////////////////
  VarStatus? _onWriteSlice(ServiceSetSlice<int, int, int> slice) {
    if (slice.statuses == null) return null; // no response error
    cache.updateByDataResponse(slice.pairs, slice.statuses!); // clears scheduled write
    return VarStatusDefault.success;
  }

  // return first error, alternatively continue collecting errors in cache
  Future<VarStatus?> _write(Iterable<(int, int)> pairs) async {
    await for (final event in protocolService.setAll(pairs)) {
      if (_onWriteSlice(event) == null) return null;
    }
    return VarStatusDefault.success;
  }

  Iterable<(int, int)> _pairs(Iterable<VarKey>? keys) => cache.dataPairsOf(keys ?? cache.varKeys);

  // write all via batches
  // optionally select keys or both keys and values
  Future<VarStatus?> writeAll([Iterable<VarKey>? keys]) async => _write(_pairs(keys));

  // separate method, as updated involves varNotifier state
  Future<VarStatus?> writeUpdated([Iterable<VarKey>? keys]) async {
    return _write(cache.dataPairsUpdatedByView);
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// `Single` Read/Write Var
  ////////////////////////////////////////////////////////////////////////////////
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
    if (await protocolService.set(key.value, cache[key]?.dataValue ?? 0) case int status) {
      return (cache[key]?..updateStatusByData(status))?.status;
    }
    return null;
  }

  // maps to protocol service, not cache, so no cache update or status update.
  VarSingleController<V> single<V>(VarNotifier<V> notifier) => VarSingleController(varNotifier: notifier, protocolService: protocolService);
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
class VarStreamController extends VarCacheController {
  VarStreamController({required super.cache, required super.protocolService});

  Stream<ServiceGetSlice<int, int>> get _readStream => protocolService.pollFlex(_readKeysGetter);
  Stream<ServiceSetSlice<int, int, int>> get _writeStream => protocolService.push(_writePairsGetter);

  StreamSubscription? pollSubscription;
  StreamSubscription? pushSubscription;

  final List<int> _readBuffer = []; // reuse allocation, no new List each cycle
  final List<(int, int)> _writeBuffer = [];
  final Set<PollingScope> _scopes = {};

  PollingScope createScope(Iterable<VarKey> keys) {
    final scope = PollingScope._(this, keys);
    _scopes.add(scope);
    return scope;
  }

  void _releaseScope(PollingScope scope) => _scopes.remove(scope);

  // stream will call slices creating a new list, at the beginning of each multi-batch operation
  // while this iterator is accessed, view must not add or remove keys, either by lock or preallocate cache
  Iterable<VarKey> get _readKeys => cache.varEntries.where((e) => (e.varKey.isPolling && e.hasListeners) || _scopes.any((s) => s._keys.contains(e.varKey))).map((e) => e.varKey);
  List<int> _readKeysGetter() => (_readBuffer..clear())..addAll(cache.dataIdsOf(_readKeys));

  Iterable<VarKey> get _writeKeys => cache.varEntries.where((e) => e.varKey.isPushing || e.hasPendingChanges).map((e) => e.varKey);
  List<(int, int)> _writePairsGetter() => (_writeBuffer..clear())..addAll(cache.dataPairsOf(_writeKeys));

  ///
  bool beginPeriodic({void Function(Object error)? onError, void Function()? onDone, bool? cancelOnError}) {
    if (!protocolService.isConnected) return false;
    pollSubscription ??= _readStream.listen(_onReadSlice, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    pushSubscription ??= _writeStream.listen(_onWriteSlice, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    return true;
  }

  Future<void> endPeriodic() async {
    await pollSubscription?.cancel().whenComplete(() => pollSubscription = null);
    await pushSubscription?.cancel().whenComplete(() => pushSubscription = null);
  }

  void pause() {
    pollSubscription?.pause();
    pushSubscription?.pause();
  }

  void resume() {
    pollSubscription?.resume();
    pushSubscription?.resume();
  }

  void forEach(void Function(StreamSubscription? subscription) action) {
    action(pollSubscription);
    action(pushSubscription);
  }

  bool get isStopped => (pollSubscription == null && pushSubscription == null);

  // Future<void> get stopped async => endPeriodic()
}

///
extension VarNotifierAwait on VarNotifier {
  Future<void> pendingChanges() async {
    while (hasPendingChanges) {
      await Future.delayed(const Duration(milliseconds: 20)); // Polls every 20ms until condition is false
    }
  }

  // todo await on status
  // of a polling, read/write
  // assuming no periodic writes
  // needs to be set with listeners, add to polling
  // Future<void> nextRead() async {
  //   await pendingChanges();
  //   view = viewOf(data); // set pending value to the same value and wait for it to clear
  //   await pendingChanges();
  // }
}

////////////////////////////////////////////////////////////////////////////////
/// if a single var update is required. Batch updates via VarCacheController handles most cases.
/// call service immediately
/// value will not be synced with cache
////////////////////////////////////////////////////////////////////////////////
class VarSingleController<V> {
  const VarSingleController({required this.varNotifier, required this.protocolService});

  final ServiceIO<int, int, int> protocolService;
  final VarNotifier<V> varNotifier;
  // final VarEventNotifier? varEventNotifier;

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
    if (await protocolService.set(varNotifier.dataKey, varNotifier.dataValue) case int statusValue) {
      return (varNotifier..updateStatusByData(statusValue)).status;
    }
    return null;
  }
}

class PollingScope {
  PollingScope._(this._controller, Iterable<VarKey> keys) : _keys = Set.unmodifiable(keys);
  final VarStreamController _controller;
  Set<VarKey> _keys;

  void update(Iterable<VarKey> keys) => _keys = Set.unmodifiable(keys);

  void dispose() => _controller._releaseScope(this);
}
