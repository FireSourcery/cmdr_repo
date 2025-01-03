// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'var_notifier.dart';

/// Map Service to VarCache
// base type and interface
class VarCacheController {
  const VarCacheController({required this.cache, required this.protocolService});
  // initCache and dispose handle here?

  final VarCache cache;
  final ServiceIO<int, int, int> protocolService;

  // VarStatus? readStatus; // optionally store previous response code
  // VarStatus? writeStatus;

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
  /// Collective Write Vars `Update`
  ////////////////////////////////////////////////////////////////////////////////
  VarStatus? _onWriteSlice(ServiceSetSlice<int, int, int> slice) {
    if (slice.statuses == null) return null; // no response error
    cache.updateStatuses(slice.pairs.map((e) => e.$1), slice.statuses!); // clears scheduled write
    return VarStatusDefault.success;
  }

  Iterable<(int, int)> _pairs(Iterable<VarKey>? keys) => cache.dataPairsOf(keys ?? cache.varKeys);

  // optionally select keys or both keys and values
  Future<VarStatus?> writeAll([Iterable<VarKey>? keys]) async {
    await for (final event in protocolService.setAll(_pairs(keys))) {
      if (_onWriteSlice(event) == null) return null;
    }
    return VarStatusDefault.success;
  }

  // Future<VarStatus?> writeEachAs<V>([Iterable<(VarKey, V)>? pairs]) async {
  //   cache.updateByView(pairs!);
  //   return writeEach(pairs.map((e) => e.$1));
  // }

  ////////////////////////////////////////////////////////////////////////////////
  /// Single Read/Write Var
  ////////////////////////////////////////////////////////////////////////////////
  Future<void> read(VarKey key) async {
    if (await protocolService.get(key.value) case int value) {
      cache[key]?.updateByData(value);
    }
  }

  Future<VarStatus?> writeAs<V>(VarKey key, [V? value]) async {
    if (value != null) cache[key]?.updateByView(value);
    if (await protocolService.set(key.value, cache[key]?.dataValue ?? 0) case int statusValue) {
      return (cache[key]?..updateStatusByData(statusValue))?.status;
    }
    return null;
  }
}

/// Poll/Push Periodic Process Stream
// A var should not be in both streams, that would be a loop back.
// A var may be both read and write, but not both periodic.
//   e.g. periodic read, but write on update only
//
// returning on a yield should complete a send/receive request, so there cannot be send/receive mismatch
// begin create a new copy of keys, updating selected keys to the working set
// need stream getter or begin() to call stream.listen(onData)
//
// Cache keeps views in sync, each Var entry occurs only once in the cache.
// Streams may be per cache, or partial selection
//
// as the slice are created, although there is no active tx/rx via the service, the stream may re-iterate the keys.
// views must not add/remove keys, when calling add/remove, either await lock, await cancel, or preallocate keys
//
// if an entry is removed from the cache map, listener will still exist synced with previously allocated.
// it will no longer be updated by Streams.
class VarRealTimeController extends VarCacheController {
  VarRealTimeController({required super.cache, required super.protocolService});

  late final ServicePollStreamHandler<int, int, int> pollHandler = ServicePollStreamHandler(protocolService, _readKeysGetter, _onReadSlice);
  late final ServicePushStreamHandler<int, int, int> pushHandler = ServicePushStreamHandler(protocolService, _writePairsGetter, _onWriteSlice);

  // stream will call slices creating a new list, at the beginning of each multi-batch operation
  // while this iterator is accessed, view must not add or remove keys, either by lock or preallocate cache

  // hasListeners check is regularly updated.
  Iterable<VarKey> get _readKeys => cache.varEntries.where((e) => e.varKey.isPolling && e.isPollingMarked).map((e) => e.varKey);
  Iterable<int> _readKeysGetter() => _readKeys.map((e) => e.value);

  Iterable<VarKey> get _writeKeys => cache.varEntries.where((e) => e.varKey.isPushing || e.isPushPending).map((e) => e.varKey);
  Iterable<(int, int)> _writePairsGetter() => cache.dataPairsOf(_writeKeys);

  // Stream<(ServiceGetSlice> get _readStream => protocolService.pollFlex(_readKeysGetter, delay: const Duration(milliseconds: 5));
  // Stream<(ServiceSetSlice> get _writeStream => protocolService.push(_writePairsGetter, delay: const Duration(milliseconds: 5));

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

  // wait for an user initiated write to resolve
  Future<void> writeBatchCompleted(VarKey varKey) async {
    // while (cache[varKey]!.isPushPending) {
    //   await Future.delayed(const Duration(milliseconds: 10)); // wait some duration before every check
    // }
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 10)); // wait some duration before every check
      return (cache[varKey]!.isPushPending);
    });
  }

  Future<void> readBatchCompleted(VarKey varKey) async {
    cache[varKey]!.isPullComplete = false;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 10)); // wait some duration before every check
      return (cache[varKey]!.isPullComplete);
    });
  }
}

////////////////////////////////////////////////////////////////////////////////
/// if a single var update is required. Batch updates via VarCacheController handles most cases.
/// call service immediately
/// value will not be synced with cache
////////////////////////////////////////////////////////////////////////////////
class VarSingleController {
  VarSingleController({
    required this.varNotifier,
    required this.protocolService,
  });

  final VarNotifier<dynamic> varNotifier;
  final ServiceIO<int, int, int> protocolService;

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
}
