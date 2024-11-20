part of 'var_notifier.dart';

/// Map Service to VarCache
// base type and interface
class VarCacheController {
  VarCacheController({required this.cache, required this.protocolService});
  // initCache and dispose handle here?

  final VarCache cache;
  final ServiceIO<int, int, int> protocolService;

  // VarNotifier open(VarKey varKey);
  // void close(VarKey varKey);
  // VarNotifier replace(VarKey add, VarKey remove);

  // VarStatus? readStatus; // optionally store previous response code
  // VarStatus? writeStatus;

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Read Vars `Load`
  ////////////////////////////////////////////////////////////////////////////////
  /// cache.updateByDataSlice
  VarStatus? _onReadSlice(({Iterable<int> keys, Iterable<int>? values}) slice) {
    if (slice.values == null) return null; // no response error
    cache.updateByData(slice.keys, slice.values!);
    return VarStatusDefault.success;
  }

  Iterable<int> _ids(Iterable<VarKey>? keys) => keys?.map((e) => e.value) ?? cache.dataIds;

  /// Read as slices. Each slice is 1 packet transaction.
  /// Returns first meta status error, e.g. not received. A Var error status may indicate some UI visualization.
  /// alternatively selectable return on error
  Future<VarStatus?> readEach([Iterable<VarKey>? keys]) async {
    await for (final event in protocolService.getAll(_ids(keys))) {
      if (_onReadSlice(event) == null) return null;
    }
    return VarStatusDefault.success;
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Write Vars `Update`
  ////////////////////////////////////////////////////////////////////////////////
  VarStatus? _onWriteSlice(({Iterable<(int, int)> pairs, Iterable<int>? statuses}) slice) {
    if (slice.statuses == null) return null; // no response error
    cache.updateStatuses(slice.pairs.map((e) => e.$1), slice.statuses!); // clears scheduled write
    return VarStatusDefault.success;
  }

  Iterable<(int, int)> _pairs(Iterable<VarKey>? keys) => cache.dataPairsOf(keys ?? cache.varKeys);

  // optionally select keys or both keys and values
  Future<VarStatus?> writeEach([Iterable<VarKey>? keys]) async {
    await for (final event in protocolService.setAll(_pairs(keys))) {
      if (_onWriteSlice(event) == null) return null;
    }
    return VarStatusDefault.success;
  }

  // Future<VarStatus?> writeEachAs<V>([Iterable<(VarKey, V)>? pairs]) async {
  //   cache.updateByView(pairs!);
  //   return writeEach(pairs.map((e) => e.$1));
  // }
}

////////////////////////////////////////////////////////////////////////////////
/// if a single var update is required. Batch updates via VarCacheController handles most cases.
/// call service immediately
///
/// This could be in its own context, without selectable VarNotifier
////////////////////////////////////////////////////////////////////////////////
abstract mixin class VarSingleController {
  VarNotifier<dynamic> get varNotifier;
  ServiceIO<int, int, int> get protocolService;

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
