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
  // <int, VarNotifier> allows direct access by updateByData
  final Map<int, VarNotifier> _cache;
  final int? lengthMax;
  // final VarNotifier? undefined ;

  // final Map<VarKey, VarNotifier> _cache; // this way keys are retained, access without going through var
  // final Set<VarKey>? preallocatedKeys; // retain if generated,

  // override for subtype
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
    return _cache.update(varKey.value, (value) {
      // _cache[varKey.value]?.dispose();
      value.dispose(); // remove listeners
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
  void zero() => _cache.forEach((key, value) => value._viewValue = 0);

  void dispose() => _cache.forEach((_, value) => value.dispose());

  // void allocateAll(Iterable<VarKey> varKeys, VarNotifier Function(VarKey) constructor) {
  //   _cache.addEntries(varKeys.map((varKey) => MapEntry(varKey.value, constructor(varKey))));
  // }

  ////////////////////////////////////////////////////////////////////////////////
  /// Per Instance
  ////////////////////////////////////////////////////////////////////////////////
  // would it be faster to use VarKey hash as base key? and cache varKey.value in VarNotifier
  VarNotifier? operator [](VarKey varKey) => _cache[varKey.value]; // alternatively ?? undefined;

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective App View
  ////////////////////////////////////////////////////////////////////////////////
  // by results of the keys' generative constructor stored in VarNotifier, will not create new keys
  // name as 'keys' creates some conflict on cast<>()
  Iterable<VarKey> get varKeys => _cache.values.map((e) => e.varKey);
  Iterable<VarNotifier> get varEntries => _cache.values;
  Iterable<VarNotifier> get varsUpdatedByView => varEntries.where((e) => e.lastUpdate == VarLastUpdate.byView);
  Iterable<VarNotifier> varsOf(Iterable<VarKey> keys) => keys.map<VarNotifier?>((e) => this[e]).nonNulls;
  // Iterable<VarNotifier> varsHaving(PropertyFilter<VarKey>? property) => varsOf(varKeys.havingProperty(property));
  // Iterable<VarNotifier> varsHaving<T extends VarKey>(PropertyFilter<T>? property) => varsOf(varKeys.havingProperty(property));

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Read
  ////////////////////////////////////////////////////////////////////////////////
  Iterable<int> get dataIds => _cache.keys;

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Write
  ///   Individual write use VarController/VarValue Instance
  ////////////////////////////////////////////////////////////////////////////////
  Iterable<(int, int)> dataPairsOf(Iterable<VarKey> keys) => varsOf(keys).map((e) => e.dataPair);
  Iterable<(int, int)> get dataPairs => varEntries.map((e) => e.dataPair);
  Iterable<(int, int)> get dataPairsUpdatedByView => varsUpdatedByView.map((e) => e.dataPair);

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Read Response - Update by Packet
  ////////////////////////////////////////////////////////////////////////////////
  // calling function checks packet length, data
  // returned values should be lists
  void updateByData(Iterable<int> ids, Iterable<int> valuesIn) {
    /* [bool overwriteUpdateByView = false] */
    assert(valuesIn.length == ids.length);
    for (final (id, value) in Iterable.generate(ids.length, (i) => (ids.elementAt(i), valuesIn.elementAt(i)))) {
      if (_cache[id] case VarNotifier varNotifier) {
        // Prevent sending results of fetch/poll, updateByData is blocked by isUpdatedByView,
        // handle case where value is polling response is received in between mark updateByView and send
        // relevant only when var is read/write; periodic polling AND calls updateByView
        if (varNotifier.lastUpdate != VarLastUpdate.byView) varNotifier.updateByData(value); // only update if not updatedByView pending
      }
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective Data Write Response
  ////////////////////////////////////////////////////////////////////////////////
  /// Update Status by mot response to view initiated write, per var status
  // void updateStatuses(Iterable<int> ids, Iterable<int> statusesIn, [bool clearPushPending = true]) {
  //   assert(statusesIn.length == ids.length);
  //   for (final (id, status) in Iterable.generate(ids.length, (i) => (ids.elementAt(i), statusesIn.elementAt(i)))) {
  //     _cache[id]?.updateStatusByData(status);
  //   }
  // }

  // update by DataResponse
  void updateByViewResponse(Iterable<(int id, int value)> pairs, Iterable<int> statusesIn) {
    assert(statusesIn.length == pairs.length);
    for (final ((id, value), status) in Iterable.generate(pairs.length, (i) => (pairs.elementAt(i), statusesIn.elementAt(i)))) {
      if (_cache[id] case VarNotifier varNotifier) {
        varNotifier.updateStatusByData(status);
        // handle case where value is updatedByView again in between send and response
        // isUpdatedByView cannot cleared on getdataids to block updateByData
        // sync note:
        //  there is a small window for error, if updateByViewResponse does not run to completion.
        //   if (pair.$2 == varNotifier.dataValue)
        //   -> user: set value, set pushPending
        //   clear pushPending
        if (value == varNotifier.dataValue) varNotifier.lastUpdate = VarLastUpdate.clear; // clear push pending unless value has changed since send
      }
    }
  }

  /// Single updateByView use VarValue directly

  ////////////////////////////////////////////////////////////////////////////////
  /// Json
  ////////////////////////////////////////////////////////////////////////////////
  /// load from json
  void loadFromJson(List<Map<String, Object?>> json) {
    for (final entry in json) {
      if (entry
          case {
            'varId': int motVarId,
            'varValue': num _,
            'dataValue': int _,
            'description': String _,
          }) {
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
  ///
  ////////////////////////////////////////////////////////////////////////////////
  String dependentsString(VarKey key, [String prefix = '', String divider = ': ', String separator = '\n']) {
    return (StringBuffer(prefix)
          ..writeAll(key.dependents?.map((k) => '${k.label}$divider${this[k]?.valueAsNum}') ?? [], separator)
          ..writeln(''))
        .toString();
  }

  // void updateDependentsOf(VarKey key, num Function(VarKey dependent) valueOf) {
  //   // update(key.dependents ?? []);
  //   key.dependents?.forEach((dependent) => this[dependent]?.updateByViewAs<num>(valueOf(dependent)));
  // }

  ////////////////////////////////////////////////////////////////////////////////
  /// debug
  ////////////////////////////////////////////////////////////////////////////////
  @visibleForTesting
  void printCache() {
    print(this);
    _cache.forEach((key, value) => print('{ ${value.varKey} : $value }'));
  }
}

////////////////////////////////////////////////////////////////////////////////
/// [VarCacheNotifier] - with context of [VarCache]
/// A notifier separate from [VarNotifier.value] [updateByView] updates
///    UI events
///    Var selection - e.g. change select with Menu
///    Submit notifier - e.g. generating dialog
///    Updating dependents residing in the same VarCache
////////////////////////////////////////////////////////////////////////////////
// altenatively combine with mixin
abstract mixin class VarCacheNotifier implements VarCache, ValueNotifier<VarViewEvent> {
  // propagateSet
  // caller provides function via switch case
  // updateHook
  void updateDependents(covariant VarKey key);

  // single listener table, notify with id. this way invokes extra notifications
  //  separate changeNotifier, separate tables for different types of events
  VarViewEvent _value = VarViewEvent.none;
  @override
  VarViewEvent get value => _value;

  // always update value, even if the same
  @override
  set value(VarViewEvent newValue) {
    _value = newValue;
    notifyListeners();
  }

  // passing key
  void submitEntryAs<T>(VarKey key, T varValue) {
    this[key]?.updateByViewAs<T>(varValue);
    // if (varCache case VarDependents typedCache) {
    updateDependents(key);
    // }
    value = VarViewEvent.submit;
  }

  // ValueSetter<T> valueSetterOf<T>(VarKey key) => ((T value) => submitEntryAs<T>(key, value));

  // //////////////////////////////////////////////////////////////////////////////
  // / User submit
  // /   associated with UI component, rather than VarNotifier
  // /   with context of cache for dependents
  // /   Listeners to the VarNotifier on another UI component will not be notified of submit
  // //////////////////////////////////////////////////////////////////////////////
  // using selected state
  // this is not needed if context of cache is provided
  // Type assigned by VarKey/VarCache
  // null for default. If a 'empty' VarNotifier is attached, it may register excess callbacks, and dispatch meaningless notifications.
  // VarNotifier<dynamic>? varNotifier; // always typed by Key returning as dynamic.

  // void submitByViewAs<T>(T varValue) {
  //   if (varNotifier == null) return;
  //   varNotifier!.updateByViewAs<T>(varValue);
  //   // if varCache has mixin VarDependents, update dependents
  //   // if (varCache case VarDependents typedCache) {
  //   updateDependents(varNotifier!.varKey);
  //   // }
  //   value = VarViewEvent.submit;
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
