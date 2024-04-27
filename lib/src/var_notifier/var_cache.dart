// import 'package:collection/collection.dart';
// import 'package:meta/meta.dart';

// import 'var_key.dart';

// ////////////////////////////////////////////////////////////////////////////////
// /// VarCache
// ///   Read/Write Vars => use for stream and synced view
// ///   Write-Only Vars => use to maintain synced view only
// ////////////////////////////////////////////////////////////////////////////////
// @immutable
// class VarCache {
//   VarCache([this.lengthMax]) : _cache = {};
//   VarCache.preallocate(Iterable<VarKey> varKeys, [this.lengthMax]) : _cache = {for (final varKey in varKeys) varKey.asMotDataId: VarNotifier(varKey)};

//   final Map<int, VarNotifier> _cache;
//   final int? lengthMax;

//   // limitations
//   // use LruMap is putIfAbsent promotion is needed
//   // no tracking if most recent entries are viewed and update protocol list
//   // VarCache([this.lengthMax]) : _map = LruMap(maximumSize: lengthMax);
//   // final LruMap<int, VarNotifierValue> _map;

//   @visibleForTesting
//   Map<int, VarNotifier> get map => _cache;

//   /// when a value is remove its listener will no longer received updates
//   /// if an value of the same id is reinserted into the map. the disconnected listener, VarNotifierController, need be remapped to the new VarNotifierValue
//   ///
//   /// caller block cache map iteration before running allocate
//   /// stores key in value when using dynamically generated iterable
//   VarNotifier allocate(VarKey varKey) {
//     if ((lengthMax != null) && (_cache.length >= lengthMax!)) _cache.remove(_cache.entries.first.key);
//     return _cache.putIfAbsent(varKey.asMotDataId, () => VarNotifier(varKey))..viewerCount += 1;
//   }

//   // remove viewer
//   void deallocate(VarKey varKey) {
//     final VarNotifier = _cache[varKey.asMotDataId];
//     if (VarNotifier != null) {
//       VarNotifier.viewerCount--;
//       if (VarNotifier.viewerCount < 1) _cache.remove(varKey.asMotDataId);
//     }
//   }

//   bool contains(VarKey varKey) => _cache.containsKey(varKey.asMotDataId);
//   void clear() => _cache.clear();
//   void zero() => _cache.forEach((key, value) => value.numValue = 0);

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Per Instance
//   ////////////////////////////////////////////////////////////////////////////////
//   VarNotifier? operator [](VarKey varKey) => _cache[varKey.asMotDataId];

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Collective App View
//   ////////////////////////////////////////////////////////////////////////////////
//   // store generative constructor key in VarNotifier, will not create new keys
//   Iterable<VarKey> get keys => _cache.values.map((e) => e.varKey);
//   Iterable<VarNotifier> get entries => _cache.values;
//   // assert((this[e] != null) ? (this[e]!.varKey == e) : true); assert new keys haven't been created
//   /// for filter on keys, alternatively caller filter on entries
//   Iterable<VarNotifier> entriesOf(Iterable<VarKey> keys) => keys.map<VarNotifier?>((e) => this[e]).whereNotNull();

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Collective Data Read
//   ////////////////////////////////////////////////////////////////////////////////
//   Iterable<int> get dataIds => _cache.keys;

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Collective Data Write
//   ///   Individual write use VarNotifierController/VarNotifierValue Instance
//   ////////////////////////////////////////////////////////////////////////////////
//   Iterable<MapEntry<int, int>> get dataPairs => _cache.values.map((e) => e.motDataPair);
//   Iterable<(int, int)> get dataRecords => _cache.values.map((e) => e.motDataRecord);

//   Iterable<(int, int)> dataRecordsOf(Iterable<VarKey> keys) => entriesOf(keys).map((e) => e.motDataRecord);
//   Iterable<MapEntry<int, int>> dataPairsOf(Iterable<VarKey> keys) => entriesOf(keys).map((e) => e.motDataPair);
//   // Map<int, int> dataMapOf(Iterable<VarKey> keys) => Map.fromEntries(dataPairsOf(keys));

//   // support update priority interval

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Collective Data Read Response - Update by MotPacket
//   ////////////////////////////////////////////////////////////////////////////////
//   // calling function checks packet length, data
//   void updateByMot(Iterable<int> ids, Iterable<int> bytesValuesIn, [Iterable<int>? statusesIn]) {
//     assert(bytesValuesIn.length == ids.length);
//     for (final pairs in IterableZip([bytesValuesIn, ids])) {
//       _cache[pairs[1]]?.updateByMot(pairs[0]);
//     }
//     // if (bytesValues .length != ids.length) return;
//     // var value = bytesValues!.iterator;
//     // var id = ids.iterator;
//     // while (id.moveNext() && value.moveNext()) {
//     //   _cache[id.current]?.updateByMot(value.current);
//     // }

//     //  notifyListeners(); allow listeners on collective update
//   }

//   /// Update Status by mot response to view initiated write, per var status
//   void updateStatuses(Iterable<int> ids, Iterable<int> statusesIn) {
//     assert(statusesIn.length == ids.length);
//     for (final pairs in IterableZip([statusesIn, ids])) {
//       _cache[pairs[1]]?.updateStatus(pairs[0]);
//     }
//     // if (statusesIn?.length != idsOut.length) return;
//     // var status = statusesIn!.iterator;
//     // var id = idsOut.iterator;
//     // while (status.moveNext() && id.moveNext()) {
//     //   _cache[id.current]?.updateStatus(status.current);
//     // }
//   }

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Collective updateByView
//   ///   Single update use VarNotifierValue directly
//   ////////////////////////////////////////////////////////////////////////////////

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Json
//   ////////////////////////////////////////////////////////////////////////////////
//   /// load from json
//   void loadFromJson(List<Map<String, Object?>> json) {
//     for (final paramJson in json) {
//       if (paramJson case {'varId': int VarNotifierId, 'varValue': num _, 'motValue': int _, 'description': String _}) {
//         this[VarKey.from(VarNotifierId)]?.loadFromJson(paramJson);
//       } else {
//         throw const FormatException('Unexpected JSON');
//       }
//     }
//   }

//   List<Map<String, Object?>> toJson() => entries.map((e) => e.toJson()).toList();
// }
