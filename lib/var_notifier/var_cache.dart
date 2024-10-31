part of 'var_notifier.dart';

////////////////////////////////////////////////////////////////////////////////
/// VarCache
///   map views to common listenable value
///   visible/active on pages
///   Read/Write Vars => use for stream and synced view
///   Write-Only Vars => use to maintain synced view only
///
/// ServiceIO can mixin to this module, still both derive from the same context
////////////////////////////////////////////////////////////////////////////////
@immutable
class VarCache {
  /// when a value is remove its listener will no longer received updates
  /// if an value of the same id is reinserted into the map. the disconnected listener, VarController, need be remapped to the new VarValue
  VarCache([this.lengthMax]) : _cache = {};

  // stores key in value when using dynamically generated iterable
  VarCache.preallocate(
    Iterable<VarKey> varKeys, {
    VarNotifier Function(VarKey) constructor = VarNotifier.of,
    this.lengthMax,
  }) : _cache = {for (final varKey in varKeys) varKey.value: constructor(varKey)};

  final Map<int, VarNotifier> _cache; // <int, VarNotifier> allows direct access by updateBy
  final int? lengthMax;

  // using default status ids unless overridden
  @mustBeOverridden
  VarNotifier<dynamic> constructor(covariant VarKey varKey) => VarNotifier.of(varKey);

  @override
  String toString() => 'VarCache: $runtimeType ${_cache.length}';

  /// Maps VarKey to VarNotifier
  /// `allocate` the same VarNotifier storage if found. `create if not found`
  ///
  /// Caller block cache map iteration before running allocate/deallocate
  VarNotifier allocate(VarKey varKey) {
    if (lengthMax case int max when _cache.length >= max) _cache.remove(_cache.entries.first.key);
    return _cache.putIfAbsent(varKey.value, () => constructor(varKey))..viewerCount += 1;
  }

  /// re run generator to update VarNotifier reference values
  VarNotifier reallocate(VarKey varKey) {
    return _cache.update(varKey.value, (_) => constructor(varKey))..viewerCount += 1;
  }

  // remove viewer
  bool deallocate(VarKey varKey) {
    if (_cache[varKey.value] case VarNotifier varEntry) {
      if (varEntry.hasListeners) {
        print('deallocate: ${varKey.value} ${varEntry.varKey}');
        print('deallocate: ${varEntry.viewerCount}');
        // return;
      }
      varEntry.viewerCount--;
      if (varEntry.viewerCount < 1) {
        _cache.remove(varKey.value)?.dispose();
        return true;
      }
    }
    return false;
  }

  VarNotifier replace(VarKey add, VarKey remove) => (this..deallocate(remove)).allocate(add);

  void replaceAll(Iterable<VarKey> varKeys) {
    clear();
    varKeys.forEach(allocate);
  }

  bool contains(VarKey varKey) => _cache.containsKey(varKey.value);
  void clear() => _cache.clear();
  void zero() => _cache.forEach((key, value) => value.numValue = 0);

  bool get isEmpty => _cache.isEmpty;

  void dispose() {
    _cache.forEach((_, value) => value.dispose());
    _cache.clear();
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// Per Instance
  ////////////////////////////////////////////////////////////////////////////////
  VarNotifier? operator [](VarKey varKey) => _cache[varKey.value];

  ////////////////////////////////////////////////////////////////////////////////
  /// Collective App View
  ////////////////////////////////////////////////////////////////////////////////
  // by results of the keys' generative constructor stored in VarNotifier, will not create new keys
  Iterable<VarKey> get keys => _cache.values.map((e) => e.varKey);
  Iterable<VarNotifier> get entries => _cache.values;

  /// for filter on keys, alternatively caller filter on entries
  Iterable<VarNotifier> entriesOf(Iterable<VarKey> keys) => keys.map<VarNotifier?>((e) => this[e]).whereNotNull();

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

  ////////////////////////////////////////////////////////////////////////////////
  /// Json
  ////////////////////////////////////////////////////////////////////////////////
  /// load from json
  void loadFromJson(List<Map<String, Object?>> json) {
    for (final paramJson in json) {
      if (paramJson case {'varId': int motVarId, 'varValue': num _, 'motValue': int _, 'description': String _}) {
        _cache[motVarId]?.loadFromJson(paramJson);
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

mixin VarCacheAsSubtype<V extends VarNotifier> on VarCache {
  // @override
  // Map<int, V> get _cache => super._cache as Map<int, V>;

  @mustBeOverridden
  V constructor(covariant VarKey varKey);

  @override
  V allocate(VarKey varKey) => super.allocate(varKey) as V;

  @override
  V reallocate(VarKey varKey) => super.reallocate(varKey) as V;

  @override
  V? operator [](VarKey varKey) => super[varKey] as V?;

  @override
  Iterable<V> get entries => super.entries.cast<V>();

  @override
  Iterable<V> entriesOf(Iterable<VarKey> keys) => super.entriesOf(keys).cast<V>();
}
