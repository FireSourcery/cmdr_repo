part of 'var_notifier.dart';

////////////////////////////////////////////////////////////////////////////////
/// [VarCache] - Model of Client Side Entity
///   map views to shared listenable value -
///     keeps views in sync, each Var entry occurs only once in the cache.
///   visible/active on pages
///   Read/Write Vars => use for stream and synced view
///   Write-Only Vars => use to maintain synced view only
///
/// ServiceIO can mixin to this module, still both derive from the same context
////////////////////////////////////////////////////////////////////////////////
// class VarCache<K extends VarKey, V extends VarNotifier> {
class VarCache {
  VarCache() : _cache = {};

  // stores key in value when using dynamically generated iterable
  VarCache.preallocate(Iterable<VarKey> varKeys) : _cache = {for (final varKey in varKeys) varKey.value: VarNotifier.of(varKey)};

  VarCache.fixed(Iterable<VarKey> varKeys) : _cache = Map.unmodifiable({for (final varKey in varKeys) varKey.value: VarNotifier.of(varKey)});

  // notifiers are of a subtype
  // VarCache.subtype(Iterable<VarKey> varKeys, VarNotifier Function(VarKey) constructor) : _cache = {for (final varKey in varKeys) varKey.value: constructor(varKey)};

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
  // <int, VarNotifier> allows direct access by updateByData
  final Map<int, VarNotifier> _cache; // map key to entire state containing the key
  // final int? lengthMax;
  // final VarNotifier? undefined;

  // final Map<VarKey, ValueSetter<VarCache>>? onUpdate; // (onUpdate callbacks for dependent keys, if any)
  // final Map<VarKey, ValueSetter<Iterable<VarNotifier>>>? onUpdate; // (onUpdate callbacks for dependent keys, if any)
  // VarEvent lastEvent
  // final ValueNotifier _eventNotifier = ValueNotifier(null);
  // ValueListenable get eventNotifier => _eventNotifier; // for listeners to subscribe to events

  // override for subtype
  VarNotifier<dynamic> constructor(covariant VarKey varKey) => VarNotifier.of(varKey);

  /// Maps VarKey to VarNotifier
  /// `allocate` the same VarNotifier storage if found. `create if not found`
  ///
  VarNotifier resolve(VarKey varKey) {
    if (_cache is UnmodifiableMapView) return this[varKey]!; // fixed, throw if not found
    return _cache.putIfAbsent(varKey.value, () => constructor(varKey));
  }

  VarNotifier allocate(VarKey varKey) {
    // if (_cache is UnmodifiableMapView) return this[varKey] ?? constructor(varKey); // unmapped instance or throw
    // if (lengthMax case int max when _cache.length >= max) _cache.remove(_cache.entries.first.key)?.dispose();
    return _cache.putIfAbsent(varKey.value, () => constructor(varKey));
  }

  /// current listeners would need to reattach to the new VarNotifier
  VarNotifier reallocate(VarKey varKey) {
    return _cache.update(varKey.value, (value) {
      value.dispose(); // remove listeners
      return constructor(varKey);
    });
  }

  // in preallocated case, where size is not constrained. deallocate and replace is not necessary
  // remove viewer
  bool deallocate(VarKey varKey) {
    return ((_cache.remove(varKey.value)?..dispose()) == null); // dispose and remove from cache
  }

  /// re run to update VarNotifier reference values
  void reinitAll() => _cache.forEach((_, varEntry) => varEntry.initReferences());

  void allocateAll(Iterable<VarKey> varKeys, [VarNotifier Function(VarKey)? constructor]) {
    _cache.addEntries(varKeys.map((varKey) => MapEntry(varKey.value, constructor?.call(varKey) ?? VarNotifier.of(varKey))));
  }

  bool get isEmpty => _cache.isEmpty;
  bool contains(VarKey varKey) => _cache.containsKey(varKey.value);
  void zero() => _cache.forEach((key, value) => value.numView = 0);

  void dispose() => _cache.forEach((_, value) => value.dispose());

  ////////////////////////////////////////////////////////////////////////////////
  /// Per Instance
  ////////////////////////////////////////////////////////////////////////////////
  VarNotifier? operator [](VarKey varKey) => _cache[varKey.value]; // alternatively ?? undefined;

  // @protected
  // VarNotifier? ofId(int id) => _cache[id];

  // directely return value. useful for sync update
  @protected
  num valueOf(VarKey varKey) => _cache[varKey.value]?.numView ?? 0;
  @protected
  void setValueOf(VarKey varKey, num value) => _cache[varKey.value]?.numView = value;

  /// Single updateByView can call from VarNotifier ref
  VarNotifier? updateByViewAs<T>(VarKey key, T varValue) => this[key]?..updateByViewAs<T>(varValue);

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective App View
  ////////////////////////////////////////////////////////////////////////////////
  // by results of the keys' generative constructor stored in VarNotifier, will not create new keys
  // name as 'keys' creates some conflict on cast<>()
  Iterable<VarKey> get varKeys => _cache.values.map((e) => e.varKey);

  Iterable<VarNotifier> get varEntries => _cache.values;
  Iterable<VarNotifier> varsOf(Iterable<VarKey> keys) => keys.map<VarNotifier?>((e) => this[e]).nonNulls;

  /// Collective Data Read
  Iterable<int> get dataIds => _cache.keys;
  Iterable<int> dataIdsOf(Iterable<VarKey> keys) => varsOf(keys).map((e) => e.dataKey); // use the cached value

  /// Collective Data Write - Individual write use VarController/VarValue Instance
  Iterable<(int, int)> get dataPairs => varEntries.map((e) => e.dataPair);
  Iterable<(int, int)> dataPairsOf(Iterable<VarKey> keys) => varsOf(keys).map((e) => e.dataPair);

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Read Response - Update by Packet
  ////////////////////////////////////////////////////////////////////////////////
  // caller clear varNotifier.lastUpdate to overwrite
  // Prevent sending results of fetch/poll, updateByData is blocked by isUpdatedByView,
  // handle case where value is polling response is received in between mark updateByView and send
  // relevant only when var is read/write; periodic polling AND calls updateByView
  // if (varNotifier.lastUpdate != VarLastUpdate.byView) varNotifier.updateByData(value); // only update if not updatedByView pending
  void _updateByData(int id, int value) => _cache[id]?.updateByData(value);

  // returned values should be lists
  /* [bool overwriteUpdateByView = false] */
  void updateByData(Iterable<int> ids, Iterable<int> valuesIn) {
    assert(valuesIn.length == ids.length); // caller checks packet length, data

    if (valuesIn case List<int> valuesList) {
      for (final (id, value) in ids.mapIndexed((index, id) => (id, valuesList[index]))) {
        _updateByData(id, value);
      }
    } else {
      final iterIds = ids.iterator;
      final iterValues = valuesIn.iterator;
      while (iterIds.moveNext() && iterValues.moveNext()) {
        _updateByData(iterIds.current, iterValues.current);
      }
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Write
  ////////////////////////////////////////////////////////////////////////////////
  /// awaiting push
  // Iterable<VarNotifier> get varsUpdatedByView => varEntries.where((e) => e.lastUpdate == VarLastUpdate.byView);
  Iterable<VarNotifier> get varsUpdatedByView => varEntries.where((e) => e.hasPendingChanges);
  Iterable<(int, int)> get dataPairsUpdatedByView => varsUpdatedByView.map((e) => e.dataPair);

  /// Update by Response Data
  // handle case where value is updatedByView again in between send and response
  // isUpdatedByView should not clear on getdataids to block updateByData
  // sync note:
  //  there is a small window for error, if updateByDataResponse does not run to completion.
  //   ...
  //   if (value == varNotifier.dataValue)
  //   -> user function interrupt: set value, set pushPending
  //   clear pushPending
  // if (value == varNotifier.dataValue) varNotifier.lastUpdate = VarLastUpdate.clear; // clear push pending unless value has changed since send
  void _updateByDataResponse(int id, int value, int status) {
    if (_cache[id] case VarNotifier varNotifier) {
      varNotifier.updateStatusByData(status);
      varNotifier.commitUserChanges();
    }
  }

  /// Update Status by mot response to view initiated write, per var status
  void updateByDataResponse(Iterable<(int id, int value)> pairs, Iterable<int> statusesIn) {
    assert(statusesIn.length == pairs.length);

    final iterPairs = pairs.iterator;
    final iterStatuses = statusesIn.iterator;
    while (iterPairs.moveNext() && iterStatuses.moveNext()) {
      _updateByDataResponse(iterPairs.current.$1, iterPairs.current.$2, iterStatuses.current);
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Assigned by VarKey
  ////////////////////////////////////////////////////////////////////////////////
  Iterable<VarNotifier> dependentsOf(VarKey key) => varsOf(key.dependents ?? []);

  ////////////////////////////////////////////////////////////////////////////////
  /// Json
  ////////////////////////////////////////////////////////////////////////////////
  /// load from json
  /// existing ids only
  void loadFromJson(List<Map<String, Object?>> json) {
    for (final entry in json) {
      if (entry case {'varId': int motVarId, 'varValue': num _, 'dataValue': int _, 'description': String _}) {
        _cache[motVarId]?.loadFromJson(entry);
      } else {
        throw const FormatException('Unexpected JSON');
      }
    }
  }

  List<Map<String, Object?>> toJson() => varEntries.map((e) => e.toJson()).toList();

  @override
  String toString() => describeIdentity(this);

  ////////////////////////////////////////////////////////////////////////////////
  /// debug
  ////////////////////////////////////////////////////////////////////////////////
  @visibleForTesting
  void printCache() {
    print(this);
    _cache.forEach((key, value) => print('{ ${value.varKey} : $value }'));
  }
}

extension VarNotifiers on Iterable<VarNotifier> {
  Iterable<(String, num)> get namedValues => map((e) => (e.varKey.label, e.valueAsNum));
  Iterable<(VarKey, VarNotifier)> get keyed => map((e) => (e.varKey, e));

  Iterable<String> toNamedValueStrings([String divider = ': ', int precision = 2]) {
    return namedValues.map((e) => '${e.$1}$divider${e.$2.toStringAsFixed(precision)}');
  }
}

////////////////////////////////////////////////////////////////////////////////
// / [VarCacheNotifier] - with context of [VarCache]
// / A notifier separate from [VarNotifier.value] [updateByView] updates
// /    UI events as collective
// /    Var selection - e.g. change select with Menu
// /    Submit notifier - e.g. generating dialog
// /    Updating dependents residing in the same VarCache
////////////////////////////////////////////////////////////////////////////////
// abstract mixin class VarCacheNotifier implements VarCache, ValueNotifier<VarViewEvent> {
//   // propagateSet
//   // caller provides function via switch case
//   // updateHook
//   void updateDependents(covariant VarKey key);
//   // void syncDependents(VarKey key);

//   // single listener table, notify with id. this way invokes extra notifications
//   //  separate changeNotifier, separate tables for different types of events
//   VarViewEvent _value = VarViewEvent.none;
//   @override
//   VarViewEvent get value => _value;
//   // always update value, even if the same

//   // VarKey get value => _value; alternatively last key

//   @override
//   set value(VarViewEvent newValue) {
//     _value = newValue;
//     notifyListeners();
//   }

//   // passing key
//   void submitEntryAs<T>(VarKey key, T varValue) {
//     this[key]?.updateByViewAs<T>(varValue);
//     updateDependents(key);
//     value = VarViewEvent.submit;
//     //return this[key]
//   }

//   // ValueSetter<T> valueSetterOf<T>(VarKey key) => ((T value) => submitEntryAs<T>(key, value));
// }

// enum VarViewEvent {
//   select,
//   submit,
//   // update,
//   // error,
//   // clear,
//   none
// }
