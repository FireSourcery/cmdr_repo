part of 'var_notifier.dart';

/// Poll/Push Periodic Stream Controller
class VarRealTimeController extends VarCacheController {
  VarRealTimeController({required super.cache, required super.protocolService});

  // if an entry is removed from the cache map, listener will still exist synced with previously allocated.
  // it will no longer be updated by ReadStream.
  // ensure call dispose

  // @protected
  Future<bool> beginPeriodic() async {
    if (!protocolService.isConnected) return false;
    beginRead();
    beginWrite();
    return true;
  }

  Future<void> endPeriodic() async {
    await readStreamProcessor.end();
    await writeStreamProcessor.end();
    // cache.clear();
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Periodic Process Stream
  /// A var should not be in both streams, that would be a loop back.
  /// A var may be both read and write, but not both periodic.
  ///   e.g. periodic read, but write on update only
  // Cache keeps views in sync, each Var entry occurs only once in the cache.
  // Streams may be per cache

  // as the slice are created, although there is no active tx/rx via the service, the stream may re-iterate the keys.
  // views must not add/remove keys, when calling add/remove, either await lock, await cancel, or preallocate keys

  // returning on a yield should complete a send/receive request, so there cannot be send/receive mismatch
  // begin create a new copy of keys, updating selected keys to the working set
  // need stream getter or begin() to call stream.listen(onData)
  ////////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  VarPeriodicHandler readStreamProcessor = VarPeriodicHandler();

  // final Set<VarKey> selectedRead = {}; // maintain list on allocate may be better performance and iterate keys on begin

  // stream will call slices creating a new list.
  // while this iterator is accessed, view must not add or remove keys
  // hasListeners check is regularly updated. warning is ok.
  Iterable<VarKey> get _readKeys => cache.varEntries.where((e) => e.varKey.isPolling && e.hasListeners).map((e) => e.varKey);

  // using a getter, ids auto update, handle concurrency
  Iterable<int> _readIds() => _readKeys.map((e) => e.value);

  Stream<({Iterable<int> keys, Iterable<int>? values})> get _readStream => protocolService.pollFlex(_readIds, delay: const Duration(milliseconds: 5));

  StreamSubscription? beginRead([Iterable<VarKey>? keys]) {
    if (_readKeys.isEmpty) return null;
    // if (keys != null) selectedRead.addAll(keys);
    // return _readStream.listen(_onReadSlice);
    return readStreamProcessor.listenWith(_readStream, _onReadSlice);
  }

  // if fixed, create a new list. stream will iterate a new list, while original list can be modified
  // Iterable<int> get _readIds => _readKeys.map((e) => e.value);
  // Stream<({Iterable<int> keys, Iterable<int>? values})> get _readStream => protocolService.pollFixed(_readIds, delay: const Duration(seconds: 1));
  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  // for an user initiated write to resolve
  Future<void> writeBatchCompleted(VarKey varKey) async {
    // Stopwatch timer = Stopwatch()..start();
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 10)); // this should wait some duration before every check
      return (cache[varKey]!.isUpdatedByView);
    });
    // print(timer.elapsedMilliseconds);
  }

  VarPeriodicHandler writeStreamProcessor = VarPeriodicHandler();
  // final Set<VarKey> selectedWrite  = {};
  // Iterable<VarKey> get periodicWriteKeys => cache.entries.map((e) => e.varKey).where((e) => e.isPeriodicWrite);
  // Iterable<VarKey> get writeOnUpdateKeys => cache.entries.where((e) => e.isUpdatedByView).map((e) => e.varKey);
  // Iterable<VarKey> get writeKeys => periodicWriteKeys.followedBy(writeOnUpdateKeys);
  // List<int> get _writeIds => writeKeys.map((e) => e.value).toList();
  Iterable<VarKey> get _writeKeys => cache.varEntries.where((e) => e.isUpdatedByView || e.varKey.isPushing).map((e) => e.varKey);
  Iterable<(int, int)> _writePairs() => cache.dataPairsOf(_writeKeys);
  Stream<({Iterable<(int, int)> pairs, Iterable<int>? statuses})> get _writeStream => protocolService.push(_writePairs, delay: const Duration(milliseconds: 5));

  // StreamSubscription? writeStreamSubscription;
  // bool get isWriteStopped => writeStreamSubscription == null;

  StreamSubscription? beginWrite([Iterable<VarKey>? keys]) {
    if (_writeKeys.isEmpty) return null;
    // if (keys != null) selectedWrite .addAll(keys!);
    // return _writeStream.listen(_onWriteSlice);
    return writeStreamProcessor.listenWith(_writeStream, _onWriteSlice);
  }

  // Future<void> endWrite() async => writeStreamSubscription?.cancel().whenComplete(() => writeStreamSubscription = null);

  ////////////////////////////////////////////////////////////////////////////////
  /// debug
  ////////////////////////////////////////////////////////////////////////////////
  void debugViewCache(Iterable<int> bytesValues, Iterable<int> ids) {
    cache.updateByData(ids, bytesValues);
    print(ids);
  }
}

extension on StreamSubscription {
  Future<StreamSubscription<T>> restart<T>(Stream<T> stream, void Function(T)? onData) async => cancel().then((_) => stream.listen(onData));
}

///todo move
class VarPeriodicHandler {
  VarPeriodicHandler();

  StreamSubscription? streamSubscription;
  bool get isStopped => streamSubscription == null;

  StreamSubscription? listenWith<T>(Stream<T> stream, void Function(T)? onData) {
    if (streamSubscription != null) return null;
    return streamSubscription = stream.listen(onData);
  }

  Future<void> end() async => streamSubscription?.cancel().whenComplete(() => streamSubscription = null);
  Future<void> restart<T>(Stream<T> stream, void Function(T)? onData) async => end().whenComplete(() => listenWith<T>(stream, onData));
}

// if fixed polling

// Future<VarNotifier<dynamic, VarStatus>> open(VarKey varKey) async {
//   // acquire lock or
//   switch (varKey) {
//     case VarKey(isPolling: true):
//       await readStreamProcessor.end();
//     // readStreamProcessor.selectedKeys.add(varKey);

//     case VarKey(isPushing: true):
//     // writeStreamProcessor.selectedKeys.add(varKey);
//   }

//   try {
//     return cache.allocate(varKey);
//   } finally {
//     beginRead();
//   }
// }

// // closeView
// // case of deallocating a var that is actively used by a stream - req/resp mismatch will be handled by null aware operator in cache update
// // however
// Future<void> close(VarKey varKey) async {
//   // await readStreamProcessor.end();
//   if (cache.deallocate(varKey)) {
//     // void nil = switch (varKey) {
//     //   VarKey(isPeriodicRead: true) => readStreamProcessor.selectedKeys.remove(varKey),
//     //   VarKey(isPeriodicWrite: true) => writeStreamProcessor.selectedKeys.remove(varKey),
//     //   VarKey(isPeriodicRead: false, isPeriodicWrite: false) => null,
//     // };
//   }
// }

// VarNotifier replace(VarKey add, VarKey remove) => (this..close(remove)).open(add);
// await restartReadStream();

// void replaceAll(Iterable<VarKey> varKeys) async {
//   cache.clear();
//   varKeys.forEach(open);
//   // await readStreamProcessor.restart();
//   // await writeStreamProcessor.restart();
// }
