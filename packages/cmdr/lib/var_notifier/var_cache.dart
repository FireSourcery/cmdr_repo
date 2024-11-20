part of 'var_notifier.dart';

////////////////////////////////////////////////////////////////////////////////
/// VarCache - Model of Client Side Entity
///   map views to shared listenable value
///   visible/active on pages
///   Read/Write Vars => use for stream and synced view
///   Write-Only Vars => use to maintain synced view only
///
/// ServiceIO can mixin to this module, still both derive from the same context
////////////////////////////////////////////////////////////////////////////////
@immutable
class VarCache {
  VarCache([this.lengthMax]) : _cache = {};

  // stores key in value when using dynamically generated iterable
  VarCache.preallocate(
    Iterable<VarKey> varKeys, {
    VarNotifier Function(VarKey) constructor = VarNotifier.of,
    this.lengthMax,
  }) : _cache = {for (final varKey in varKeys) varKey.value: constructor(varKey)};
  // todo preallocate as Map.unmodifiable, VarNotifier need to change some fields to getters
  // re generating varnotifer parameters will need to create a new cache

  final Map<int, VarNotifier> _cache; // <int, VarNotifier> allows direct access by updateBy
  final int? lengthMax;

  // final Map<VarKey, VarNotifier> _cache; //  this way keys are retained, access without going through var
  // final Set<VarKey>? preallocatedKeys; // retain if generated,

  // @protected
  // void allocateAll(Iterable<VarKey> varKeys, VarNotifier Function(VarKey) constructor) {
  //   _cache.addEntries(varKeys.map((varKey) => MapEntry(varKey.value, constructor(varKey))));
  // }

  // using default status ids unless overridden
  @mustBeOverridden
  VarNotifier<dynamic> constructor(covariant VarKey varKey) => VarNotifier.of(varKey);

  @override
  String toString() => 'VarCache: $runtimeType ${_cache.length}';

  /// Maps VarKey to VarNotifier
  /// `allocate` the same VarNotifier storage if found. `create if not found`
  ///
  /// Caller block cache map iteration before running allocate/deallocate
  ///
  /// when a value is remove its listener will no longer received updates. from stream data updates. view updates still occur
  /// if an value of the same id is reinserted into the map. the disconnected listener, VarController, need be remapped to the new VarValue
  VarNotifier allocate(VarKey varKey) {
    if (lengthMax case int max when _cache.length >= max) _cache.remove(_cache.entries.first.key);
    return _cache.putIfAbsent(varKey.value, () => constructor(varKey))..viewerCount += 1;
  }

  /// re run generator to update VarNotifier reference values
  VarNotifier reallocate(VarKey varKey) {
    return _cache.update(varKey.value, (_) => constructor(varKey))..viewerCount += 1;
  }

  // in preallocated case, where size is not constrained. deallocate and replace is not necessary
  // remove viewer
  // bool deallocate(VarKey? varKey) {
  //   if (_cache[varKey?.value] case VarNotifier varEntry) {
  //     print('deallocate: ${varKey?.value} ${varEntry.varKey}');
  //     print('deallocate: ${varEntry.viewerCount}');
  //     print('varEntry.hasListeners: ${varEntry.hasListeners}');

  //     // caller removes itself as listener first
  //     // if (!varEntry.hasListeners) {
  //     //   _cache.remove(varKey?.value)?.dispose();
  //     //   return true;
  //     // }
  //     varEntry.viewerCount--;
  //     if (varEntry.viewerCount < 1) {
  //       _cache.remove(varKey?.value)?.dispose();
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  // VarNotifier replace(VarKey add, [VarKey? remove]) => (this..deallocate(remove)).allocate(add);

  // void replaceAll(Iterable<VarKey> varKeys) {
  //   clear();
  //   varKeys.forEach(allocate);
  // }

  bool contains(VarKey varKey) => _cache.containsKey(varKey.value);
  void zero() => _cache.forEach((key, value) => value.numValue = 0);
  // void clear() => _cache.clear();

  bool get isEmpty => _cache.isEmpty;

  void dispose() {
    _cache.forEach((_, value) => value.dispose());
    // _cache.clear();
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Per Instance
  ////////////////////////////////////////////////////////////////////////////////
  VarNotifier? operator [](VarKey varKey) => _cache[varKey.value];

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective App View
  ////////////////////////////////////////////////////////////////////////////////
  // by results of the keys' generative constructor stored in VarNotifier, will not create new keys
  Iterable<VarKey> get varKeys => _cache.values.map((e) => e.varKey);
  Iterable<VarNotifier> get entries => _cache.values;

  /// for filter on keys, alternatively caller filter on entries
  Iterable<VarNotifier> entriesOf(Iterable<VarKey> keys) => keys.map<VarNotifier?>((e) => this[e]).nonNulls;

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Read
  ////////////////////////////////////////////////////////////////////////////////
  Iterable<int> get dataIds => _cache.keys;

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Write
  ///   Individual write use VarController/VarValue Instance
  ////////////////////////////////////////////////////////////////////////////////
  Iterable<MapEntry<int, int>> get dataEntries => _cache.values.map((e) => e.dataEntry);
  Iterable<(int, int)> get dataPairs => _cache.values.map((e) => e.dataPair);

  Iterable<MapEntry<int, int>> dataEntriesOf(Iterable<VarKey> keys) => entriesOf(keys).map((e) => e.dataEntry);
  Iterable<(int, int)> dataPairsOf(Iterable<VarKey> keys) => entriesOf(keys).map((e) => e.dataPair);

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Read Response - Update by Packet
  ////////////////////////////////////////////////////////////////////////////////
  // calling function checks packet length, data
  void updateByData(Iterable<int> ids, Iterable<int> bytesValuesIn, [Iterable<int>? statusesIn]) {
    assert(bytesValuesIn.length == ids.length);
    for (final (id, value) in Iterable.generate(ids.length, (i) => (ids.elementAt(i), bytesValuesIn.elementAt(i)))) {
      _cache[id]?.updateByData(value);
    }
  }

  /// DataWriteResponse
  /// Update Status by mot response to view initiated write, per var status
  void updateStatuses(Iterable<int> ids, Iterable<int> statusesIn, [bool clearWriteBit = true]) {
    assert(statusesIn.length == ids.length);
    for (final (id, status) in Iterable.generate(ids.length, (i) => (ids.elementAt(i), statusesIn.elementAt(i)))) {
      _cache[id]
        ?..updateStatusByData(status)
        ..isUpdatedByView = false;
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective updateByView
  ///   Single update use VarValue directly
  ////////////////////////////////////////////////////////////////////////////////
  void updateByView(Iterable<(VarKey, dynamic)> pairs) {
    for (final (varKey, value) in pairs) {
      _cache[varKey.value]?.updateByView(value);
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  // group with mixin?
  String dependentsString(VarKey key, [String prefix = '', String divider = ': ', String separator = '\n']) {
    return (StringBuffer(prefix)
          ..writeAll(key.dependents?.map((k) => '${k.label}$divider${this[k]?.viewValue}') ?? [], separator)
          ..writeln(''))
        .toString();
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Json
  ////////////////////////////////////////////////////////////////////////////////
  /// load from json
  void loadFromJson(List<Map<String, Object?>> json) {
    for (final paramJson in json) {
      if (paramJson case {'varId': int motVarId, 'varValue': num _, 'motValue': int _, 'description': String _}) {
        _cache[motVarId]?.loadFromJson(paramJson);
        // this[VarKey.from(motVarId)]?.loadFromJson(paramJson);
      } else {
        throw const FormatException('Unexpected JSON');
      }
    }
  }

  List<Map<String, Object?>> toJson() => entries.map((e) => e.toJson()).toList();

  @visibleForTesting
  void printCache() {
    print('VarCache: ${_cache.length}');
    _cache.forEach((key, value) => print('{ ${value.varKey} : var: $value }'));
  }
}

// abstract mixin as compile time const instead of function variable
mixin VarDependents on VarCache {
  // caller provides function via switch case
  // resetDependentsOfKey
  // final void Function(VarKey key)? dependentsResetter;

  // Map<VarKey, VoidCallback?> _dependents; / /caller provides function via map

  // propagateSet
  // caller provides function via switch case
  void updateDependents(covariant VarKey key);
}

// gives Notifier context of cache for dependents
// mixin VarDependents on VarNotifier {
//   VarCache get cache;
//   void updateDependents();
// }

// mixin VarCacheAsSubtype<K extends VarKey, V extends VarNotifier> on VarCache {
//   // @override
//   // Map<int, V> get _cache => super._cache as Map<int, V>;

//   @override
//   @mustBeOverridden
//   V constructor(covariant K varKey);

//   @override
//   Iterable<K> get keys => super.keys.cast<K>();

//   @override
//   V allocate(covariant K varKey) => super.allocate(varKey) as V;

//   @override
//   V reallocate(covariant K varKey) => super.reallocate(varKey) as V;

//   @override
//   V? operator [](covariant K varKey) => super[varKey] as V?;

//   @override
//   Iterable<V> get entries => super.entries.cast<V>();

//   @override
//   Iterable<V> entriesOf(covariant Iterable<K> keys) => super.entriesOf(keys).cast<V>();
// }

////////////////////////////////////////////////////////////////////////////////
/// VarHandler, VarViewer
/// [VarEventController] - a controller for a single [VarNotifier] with context of [VarCache]
/// Use cases requiring notifications less than every VarNotifier value updateByView
///    Var selection - e.g. change select with Menu
///    Submit notifier - e.g. generating dialog
///    Updating dependents residing in the same VarCache
/// single var service - move to separate mixin
////////////////////////////////////////////////////////////////////////////////
class VarEventController with ChangeNotifier implements ValueNotifier<VarViewEvent> {
  VarEventController({required this.varCache, this.varNotifier});
  VarEventController.byKey({required this.varCache, required VarKey varKey}) : varNotifier = varCache.allocate(varKey);

  // VarCacheController if combining with service
  final VarCache varCache; // a reference to the cache containing this varNotifier, use controller to include service

  /// Type assigned by VarKey/VarCache
  // use null for default. If a 'empty' VarNotifier is attached, it may register excess callbacks, and dispatch meaningless notifications.
  VarNotifier<dynamic>? varNotifier; // always typed by Key returning as dynamic.
  // set varNotifier(VarNotifier notifier) => varNotifier = notifier;

// single listener table, notfiy with id. this way invokes extra notifications
// or use separate changeNotifier?
//    separate tables for different types of events
  VarViewEvent _value = VarViewEvent.none;
  @override
  VarViewEvent get value => _value;
  // always update value, even if the same
  @override
  set value(VarViewEvent newValue) {
    _value = newValue;
    notifyListeners();
  }

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  // update Var by VarKey, notify with parent class
  // caller update Stream when using realtime
  // Future<void> select(VarKey key) async {
  //   // varNotifier = varCache.replace(key, varNotifier?.varKey);
  //   value = VarViewEvent.select;
  //   // await cacheController.updatePeriodicStream([key]);
  // }

  // void notifyDependents(VarKey key) => varCache.updateDependents(varNotifier!.varKey);

  ////////////////////////////////////////////////////////////////////////////////
  /// User submit
  ///   associated with UI component, rather than VarNotifier
  ///   with context of cache for dependents
  ///   Listeners to the VarNotifier on another UI component will not be notified of submit
  ////////////////////////////////////////////////////////////////////////////////
  void submitByViewAs<T>(T varValue) {
    if (varNotifier == null) return;
    varNotifier!.updateByViewAs<T>(varValue);
    // if varCache has mixin VarDependents, update dependents
    if (varCache case VarDependents typedCache) {
      typedCache.updateDependents(varNotifier!.varKey);
    }
    //isSubmittedByView
    value = VarViewEvent.submit;
  }

  void submitByView(dynamic typedValue) {
    if (varNotifier == null) return;
    varNotifier!.updateAsDynamic(typedValue);
    if (varCache case VarDependents typedCache) {
      typedCache.updateDependents(varNotifier!.varKey);
    }
    value = VarViewEvent.submit;
  }
}

enum VarViewEvent {
  select,
  submit,
  // update,
  // error,
  // clear,
  none
}
