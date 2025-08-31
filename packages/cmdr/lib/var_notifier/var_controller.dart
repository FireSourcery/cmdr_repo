part of 'var_notifier.dart';

/// [VarRepo]/[VarCache] with [Serivce]
///
class VarCacheController {
  const VarCacheController({required this.cache, required this.protocolService});

  final VarCache cache;
  final ServiceIO<int, int, int> protocolService;

  // VarStatus? readStatus; // optionally store previous response code
  // VarStatus? writeStatus;

  void dispose() => cache.dispose();

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Read Vars `Fetch/Load`
  ////////////////////////////////////////////////////////////////////////////////
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
    // if (keys != null){
    //   _write(keys where pendingVlue!= null)
    // }
    return _write(cache.dataPairsUpdatedByView);
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Single Read/Write Var
  ////////////////////////////////////////////////////////////////////////////////
  VarSingleController<V>? singleController<V>(VarKey key) {
    assert(key.viewType.type == V);
    if (cache[key] case VarNotifier<V> varNotifier) return VarSingleController(varNotifier: varNotifier, protocolService: protocolService);
    return null;
  }

  // fetch
  // Future<VarNotifier>
  // Future<VarStatus?>
  Future<bool> read(VarKey key) async {
    if (await protocolService.get(key.value) case int value) {
      cache[key]?.updateByData(value);
      return true;
    }
    return false;
  }

  // send
  Future<VarStatus?> write(VarKey key) async {
    if (await protocolService.set(key.value, cache[key]?.dataValue ?? 0) case int statusValue) {
      return (cache[key]?..updateStatusByData(statusValue))?.status;
    }
    return null;
  }

  Future<V?> readAs<V>(VarKey key) async {
    if (await read(key) == true) return cache[key]?.valueAs<V>();
    return null;
  }

  Future<VarStatus?> writeAs<V>(VarKey key, V value) async {
    cache[key]?.updateByViewAs<V>(value);
    return write(key);
  }

  // return num or object of key V type
  // Future<num?> operator [](VarKey key) async {
  //   if (await protocolService.get(key.value) case int value) {
  //     cache[key]?.updateByData(value);
  //   }
  //   return cache[key]!.valueAsNum;
  // }

  // @override
  // Future<Object?> get(VarKey key, {Loader? ifAbsent}) async {
  //   await read(key);
  //   return cache[key]?.viewValue;
  // }

  // @override
  // Future<void> invalidate(key) {
  //   // TODO: implement invalidate
  //   throw UnimplementedError();
  // }

  // @override
  // Future<void> set(key, value) {
  //   // TODO: implement set
  //   throw UnimplementedError();
  // }
}

/// Poll/Push Periodic Process Stream
// A var should not be in both streams, that would be a loop back.
// A var may be both read and write, but not both periodic.
//   e.g. periodic read, but write on update only
// returning on a yield should complete a send/receive request, so there cannot be send/receive mismatch
// Streams may be per cache, or partial selection
//
// if an entry is removed from the cache map, listener will still exist synced with previously allocated Var.
// it will no longer be updated by Streams.
//
// alternative to iterating over cache, add to a Set
// begin create a new copy of keys, updating selected keys to the working set
class VarRealTimeController extends VarCacheController {
  VarRealTimeController({required super.cache, required super.protocolService});

  late final ServicePollStreamHandler<int, int, int> pollHandler = ServicePollStreamHandler(protocolService, _readKeysGetter, _onReadSlice);
  late final ServicePushStreamHandler<int, int, int> pushHandler = ServicePushStreamHandler(protocolService, _writePairsGetter, _onWriteSlice);
  // Stream<ServiceGetSlice<K, V>> get _readStream => protocolService.pollFlex(_readKeysGetter, delay: const Duration(milliseconds: 5));
  // Stream<ServiceSetSlice<K, V, S>> get _writeStream => protocolService.push(_writePairsGetter, delay: const Duration(milliseconds: 5));

  // stream will call slices creating a new list, at the beginning of each multi-batch operation
  // although there is no active tx/rx via the service, the stream will iterate the Map backing.
  // while this iterator is accessed, view must not add or remove keys, either by lock or preallocate cache

  // hasListeners check is regularly updated.
  // (e.lastUpdate == VarLastUpdate.clear) read all once.
  Iterable<VarKey> get _readKeys => cache.varEntries.where((e) => e.varKey.isPolling && e.hasListenersCombined).map((e) => e.varKey);
  Iterable<int> _readKeysGetter() => _readKeys.map((e) => e.value);

  Iterable<VarKey> get _writeKeys => cache.varEntries.where((e) => e.varKey.isPushing || e.hasPendingChanges).map((e) => e.varKey);
  Iterable<(int, int)> _writePairsGetter() => cache.dataPairsOf(_writeKeys);

  ///[e.hasListenersCombined]
  // polling stream setters, optionally implement local <Set>
  void addPolling(Iterable<VarKey> keys) => cache.varsOf(keys).forEach((element) => element.hasIndirectListeners = true);
  void removePollingAll() => cache.varEntries.forEach((element) => element.hasIndirectListeners = false);
  void selectPolling(Iterable<VarKey> keys) => (this..removePollingAll()).addPolling(keys);

  Future<bool> beginPeriodic() async {
    if (!protocolService.isConnected) return false;
    pollHandler.begin();
    pushHandler.begin();
    return true;
  }

  Future<void> endPeriodic() async {
    await pollHandler.end();
    await pushHandler.end();
  }

  Future<void> get isStopped async => pollHandler.isStopped && pushHandler.isStopped;
}

extension VarNotifierAwait on VarNotifier {
  Future<void> pendingChanges() async {
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 20)); // wait some duration before every check
      return hasPendingChanges;
    });
  }

  // Future<void> nextRead() async {
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

  const VarSingleController.inline(this.varNotifier, this.protocolService);

  final ServiceIO<int, int, int> protocolService; // alternatively abstract as getter common per type
  final VarNotifier<V> varNotifier;
  // final VarEventNotifier? varEventNotifier;

  // async send request id, then receiving value
  Future<void> read() async {
    if (await protocolService.get(varNotifier.dataKey) case int value) {
      varNotifier.updateByData(value);
    }
  }

  // async send value, then receiving status
  Future<VarStatus?> write(/* [V? value] */) async {
    if (await protocolService.set(varNotifier.dataKey, varNotifier.dataValue) case int statusValue) {
      return (varNotifier..updateStatusByData(statusValue)).status;
    }
    return null;
  }

  Future<V?> value() async {
    await read();
    return varNotifier.value;
  }

  Future<void> updateValue(V value) async {
    varNotifier.updateByViewAs<V>(value);
    await write();
  }
}
