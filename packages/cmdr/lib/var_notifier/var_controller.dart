part of 'var_notifier.dart';

// view model portion handling
//  single var service
//  selectable key
//  submit notifier
//  type conversion

/// must be untyped for
class VarEventController /* <V, S extends Enum>  */ /* implements VarNotifier<V, S> */ {
  VarEventController({required this.cacheController, this.varNotifier});
  VarEventController.byKey({required this.cacheController, required VarKey varKey}) : varNotifier = cacheController.cache.allocate(varKey);

  final VarCacheController cacheController; // a reference to the cache containing this varNotifier

  // use null for default. If a 'empty' VarNotifier is attached, it may register excess callbacks, and dispatch meaningless notifications.
  VarNotifier<dynamic>? varNotifier; // always typed by Key returning as dynamic.

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  // as long as an the listener widget calls dispose of the eventNotifier, this class will not need to
  final ValueNotifier<VarViewEvent?> eventNotifier = ValueNotifier(VarViewEvent.none);

  // update Var by VarKey, notify with parent class
  // caller calls updateStream when using realtime
  Future<void> select(VarKey key) async {
    varNotifier = cacheController.cache.replace(key, varNotifier?.varKey);
    // eventNotifier.value = VarViewEvent.select;
    // eventNotifier.value = null;
    // await cacheController.updatePeriodicStream([key]);
    eventNotifier.notifyListeners();
  }

  // void setVar(VarNotifier notifier) async => varNotifier = notifier;

  ////////////////////////////////////////////////////////////////////////////////
  /// User submit
  /// associated with UI component, rather than VarKey
  /// Listeners to the VarNotifier on another UI component will not be notified
  ////////////////////////////////////////////////////////////////////////////////
  void submitByViewAs<T>(T value) {
    varNotifier?.updateByViewAs<T>(value);
    // eventNotifier.value = VarViewEvent.submit;
    // eventNotifier.value = null;
    eventNotifier.notifyListeners();
  }

  // void submitByView(V typedValue) {
  //   varNotifier.updateByView(typedValue);
  //   submitNotifier.notifyListeners();
  // }

  // // individual send, alternatively set dirty bit for batched send
  // @protected
  // Future<S?> submitAndWrite(V value) async {
  //   submitByView(value); // update first for conversion
  //   return write();
  // }

  ////////////////////////////////////////////////////////////////////////////////
  /// Call service immediately
  ///
  /// This could be in its own context, without selectable VarNotifier
  /// Combined here for simplicity
  ////////////////////////////////////////////////////////////////////////////////
  // ServiceIO<int, int, int> get protocolService => cacheController.protocolService;

  // // async send request id, then receiving value
  // Future<void> read() async {
  //   if (varNotifier == null) return;
  //   if (await protocolService.get(varNotifier!.dataKey) case int value) {
  //     varNotifier!.updateByData(value);
  //   }
  // }

  // // async send value, then receiving status
  // Future<VarStatus?> write(/* [V? value] */) async {
  //   if (varNotifier == null) return null;
  //   if (await protocolService.set(varNotifier!.dataKey, varNotifier!.dataValue) case int statusValue) {
  //     varNotifier!.updateStatusByData(statusValue);
  //     return varNotifier!.statusId;
  //   }
  //   return null;
  // }
}

enum VarViewEvent {
  select,
  submit,
  // update,
  // error,
  // clear,
  none
}

// base type and interface
class VarCacheController {
  VarCacheController({required this.cache, required this.protocolService});

  final VarCache cache;
  final ServiceIO<int, int, int> protocolService;

  // VarNotifier open(VarKey varKey);
  // void close(VarKey varKey);
  // VarNotifier replace(VarKey add, VarKey remove);

  // VarStatus? readStreamStatus; // optionally store previous response code
  // VarStatus? writeStreamStatus;

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Read Vars
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
  /// Collective Write Vars
  ////////////////////////////////////////////////////////////////////////////////
  VarStatus? _onWriteSlice(({Iterable<(int, int)> pairs, Iterable<int>? statuses}) slice) {
    if (slice.statuses == null) return null; // no response error
    cache.updateStatuses(slice.pairs.map((e) => e.$1), slice.statuses!); // clears scheduled write
    return VarStatusDefault.success;
  }

  // optionally select keys or both keys and values
  Future<VarStatus?> writeEach([Iterable<VarKey>? keys, Iterable<dynamic>? values]) async {
    final dataPairs = cache.dataPairsOf(keys ?? cache.keys);
    await for (final event in protocolService.setAll(dataPairs)) {
      if (_onWriteSlice(event) == null) return null;
    }
    return VarStatusDefault.success;
  }
}

/// if a single var update is required. Batch updates via VarCacheController handles most cases.
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
      varNotifier.updateStatusByData(statusValue);
      return varNotifier.statusId;
    }
    return null;
  }
}
