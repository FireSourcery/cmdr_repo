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
// class VarCache<K extends VarKey, V extends VarNotifier> {
class VarCache {
  VarCache([this.lengthMax]) : _cache = {};

  // stores key in value when using dynamically generated iterable
  VarCache.preallocate(
    Iterable<VarKey> varKeys, {
    VarNotifier Function(VarKey) constructor = VarNotifier.of,
    this.lengthMax,
  }) : _cache = Map.unmodifiable({for (final varKey in varKeys) varKey.value: constructor(varKey)});

  /// "It is generally not allowed to modify the map (add or remove keys) while
  /// an operation is being performed on the map."
  ///
  /// Preallocation is preferred. This was streams do not need to stop and restart
  /// Otherwise, caller block cache map iteration before allocate/deallocate
  ///
  /// when a Var is remove its listener will no longer received updates, from stream data updates.
  /// view updates still occur - should not _need_ to manually remove listeners,
  ///   although the listeners map is still filled, nothing references the Var itself, will be handled by garbage collection
  /// if an Var of the same id is reinserted into the map. the disconnected listeners, need be remapped to the new Var
  /// Widgets using allocate in build will update automatically
  ///
  // <int, VarNotifier> allows direct access by updateBy
  final Map<int, VarNotifier> _cache;
  final int? lengthMax;
  // final VarNotifier? undefined ;

  // final Map<VarKey, VarNotifier> _cache; // this way keys are retained, access without going through var
  // final Set<VarKey>? preallocatedKeys; // retain if generated,

  // using default status ids unless overridden
  @mustBeOverridden
  VarNotifier<dynamic> constructor(covariant VarKey varKey) => VarNotifier.of(varKey);

  /// Maps VarKey to VarNotifier
  /// `allocate` the same VarNotifier storage if found. `create if not found`
  ///
  VarNotifier allocate(VarKey varKey) {
    if (_cache is UnmodifiableMapView) return this[varKey]!; // preallocated
    return _cache.putIfAbsent(varKey.value, () {
      if (lengthMax case int max when _cache.length >= max) _cache.remove(_cache.entries.first.key)?.dispose();
      return constructor(varKey);
    });
  }

  /// current listeners would need to reattach to the new VarNotifier
  VarNotifier reallocate(VarKey varKey) {
    return _cache.update(varKey.value, (_) {
      _cache[varKey.value]?.dispose();
      return constructor(varKey);
    });
  }

  /// re run to update VarNotifier reference values
  void reinitAll() => _cache.forEach((_, varEntry) => varEntry.initReferences());

  // in preallocated case, where size is not constrained. deallocate and replace is not necessary
  // remove viewer
  // bool deallocate(VarKey? varKey) {
  //   if (_cache[varKey?.value] case VarNotifier varEntry) {
  //     print('deallocate: ${varKey?.value} ${varEntry.varKey}');
  //     print('deallocate: ${varEntry.viewerCount}');
  //     print('varEntry.hasListeners: ${varEntry.hasListeners}');
  //     // caller removes itself as listener first
  //     if (!varEntry.hasListeners) {
  //       _cache.remove(varKey?.value);
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  bool get isEmpty => _cache.isEmpty;
  bool contains(VarKey varKey) => _cache.containsKey(varKey.value);
  void zero() => _cache.forEach((key, value) => value.numValue = 0);

  void dispose() => _cache.forEach((_, value) => value.dispose());

  // void allocateAll(Iterable<VarKey> varKeys, VarNotifier Function(VarKey) constructor) {
  //   _cache.addEntries(varKeys.map((varKey) => MapEntry(varKey.value, constructor(varKey))));
  // }

  ////////////////////////////////////////////////////////////////////////////////
  /// Per Instance
  ////////////////////////////////////////////////////////////////////////////////
  // would it be faster to use VarKey has as base key? and cache varKey.value in VarNotifier
  VarNotifier? operator [](VarKey varKey) => _cache[varKey.value]; // alternatively ?? undefined;

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective App View
  ////////////////////////////////////////////////////////////////////////////////
  // by results of the keys' generative constructor stored in VarNotifier, will not create new keys
  // name as 'keys' creates some conflict on cast<>()
  Iterable<VarKey> get varKeys => _cache.values.map((e) => e.varKey);
  Iterable<VarNotifier> get varEntries => _cache.values;

  /// for filter on keys, alternatively caller filter on entries
  Iterable<VarNotifier> varsOf(Iterable<VarKey> keys) => keys.map<VarNotifier?>((e) => this[e]).nonNulls;
  // Iterable<VarNotifier> varsHaving(PropertyFilter<VarKey>? property) => varsOf(varKeys.havingProperty(property));
  // Iterable<VarNotifier> varsHaving<T extends VarKey>(PropertyFilter<T>? property) => varsOf(varKeys.havingProperty(property));

  void addPolling(Iterable<VarKey> keys) => varsOf(keys).forEach((element) => element.isPollingMarked = true);
  void removePollingAll() => _cache.forEach((_, element) => element.isPollingMarked = false);
  void selectPolling(Iterable<VarKey> keys) => (this..removePollingAll())..addPolling(keys);

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Read
  ////////////////////////////////////////////////////////////////////////////////
  Iterable<int> get dataIds => _cache.keys;

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Write
  ///   Individual write use VarController/VarValue Instance
  ////////////////////////////////////////////////////////////////////////////////
  Iterable<(int, int)> dataPairsOf(Iterable<VarKey> keys) => varsOf(keys).map((e) => e.dataPair);
  Iterable<(int, int)> get dataPairs => _cache.values.map((e) => e.dataPair);

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Read Response - Update by Packet
  ////////////////////////////////////////////////////////////////////////////////
  // calling function checks packet length, data
  // returned values should be lists
  void updateByData(Iterable<int> ids, Iterable<int> bytesValuesIn, [Iterable<int>? statusesIn]) {
    assert(bytesValuesIn.length == ids.length);
    for (final (id, value) in Iterable.generate(ids.length, (i) => (ids.elementAt(i), bytesValuesIn.elementAt(i)))) {
      _cache[id]?.updateByData(value);
    }
  }

  /// DataWriteResponse
  /// Update Status by mot response to view initiated write, per var status
  void updateStatuses(Iterable<int> ids, Iterable<int> statusesIn, [bool clearPushPending = true]) {
    assert(statusesIn.length == ids.length);
    for (final (id, status) in Iterable.generate(ids.length, (i) => (ids.elementAt(i), statusesIn.elementAt(i)))) {
      _cache[id]
        ?..updateStatusByData(status)
        ..isPushPending = false;
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

  List<Map<String, Object?>> toJson() => varEntries.map((e) => e.toJson()).toList();

  @override
  String toString() => describeIdentity(this);

  ////////////////////////////////////////////////////////////////////////////////
  ///
  ////////////////////////////////////////////////////////////////////////////////
  String dependentsString(VarKey key, [String prefix = '', String divider = ': ', String separator = '\n']) {
    return (StringBuffer(prefix)
          ..writeAll(key.dependents?.map((k) => '${k.label}$divider${this[k]?.viewValue}') ?? [], separator)
          ..writeln(''))
        .toString();
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// debug
  ////////////////////////////////////////////////////////////////////////////////
  @visibleForTesting
  void printCache() {
    print(this);
    _cache.forEach((key, value) => print('{ ${value.varKey} : $value }'));
  }
}

// abstract mixin as compile time const instead of function variable
mixin VarDependents on VarCache {
  // propagateSet
  // caller provides function via switch case
  void updateDependents(covariant VarKey key);
}

// gives Notifier context of cache for dependents
// mixin VarDependents on VarNotifier {
//   void updateDependents(VarCache cache);
// }

////////////////////////////////////////////////////////////////////////////////
/// VarHandler, VarViewer
/// [VarEventController] - a controller for a single [VarNotifier] with context of [VarCache]
/// A notifier separate from [VarNotifier.value] [updateByView] updates, for UI events
///    Var selection - e.g. change select with Menu
///    Submit notifier - e.g. generating dialog
///    Updating dependents residing in the same VarCache
////////////////////////////////////////////////////////////////////////////////
class VarEventController with ChangeNotifier implements ValueNotifier<VarViewEvent> {
  VarEventController({required this.varCache, this.varNotifier});
  // VarEventController.byKey({required this.varCache, required VarKey varKey}) : varNotifier = varCache.allocate(varKey);

  final VarCache varCache; // a reference to the cache containing this varNotifier

  // this is not needed if context of cache is provided
  /// Type assigned by VarKey/VarCache
  // use null for default. If a 'empty' VarNotifier is attached, it may register excess callbacks, and dispatch meaningless notifications.
  VarNotifier<dynamic>? varNotifier; // always typed by Key returning as dynamic.

  // single listener table, notify with id. this way invokes extra notifications
  // or use separate changeNotifier? separate tables for different types of events
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

  // VarNotifier open(VarKey varKey);
  // void close(VarKey varKey);
  // VarNotifier replace(VarKey add, VarKey remove);

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

  void submitAndPushAs<T>(T varValue) {
    submitByViewAs(varValue);
    varNotifier?.push();
    // cacheController.push(varNotifier!.varKey);
  }

//  void submitEntryByViewAs<T>(VarKey key, T varValue)
}

enum VarViewEvent {
  select,
  submit,
  // update,
  // error,
  // clear,
  none
}

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
