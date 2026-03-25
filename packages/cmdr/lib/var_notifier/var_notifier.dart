import 'package:cmdr/cmdr.dart';
import 'package:flutter/foundation.dart';

import 'package:binary_data/binary_data.dart';
import 'var_key.dart';

export 'package:binary_data/binary_data.dart';
export 'service_io.dart';
export 'var_cache.dart';
export 'var_controller.dart';
export 'var_key.dart';

///
/// each retrievable value as a View Model
// only default status ids need to be overridden
class VarNotifier<V> with ChangeNotifier, VarValue<V>, VarValueNotifier<V>, VarStatusNotifier implements ValueNotifier<V> {
  VarNotifier({required this.varKey, BinaryCodec<V>? codec}) {
    this.codec = codec ?? varKey.buildViewer();
  }

  VarNotifier.ofKey(this.varKey) {
    initReferences();
  }

  factory VarNotifier.of(VarKey<V> varKey) {
    return VarNotifier<V>.ofKey(varKey);
  }

  final VarKey<V> varKey;
  late final int dataKey = varKey.value; // compute once and cache

  /// as outbound data depending on [dataKey]
  MapEntry<int, int> get dataEntry => MapEntry(dataKey, dataValue);
  (int key, int value) get dataPair => (dataKey, dataValue);

  /// Derived from [VarKey] and cached
  /// reinit on VarKey update
  void initReferences() {
    codec = varKey.buildViewer();
  }

  /// [VarStatus] type is the same for all vars in most cases.
  /// Compile time const defined in [VarKey]. Does not need to build and cache.
  @override
  VarStatus statusOf(int statusCode) => varKey.varStatusOf(statusCode);

  ////////////////////////////////////////////////////////////////////////////////
  /// Stringify
  ////////////////////////////////////////////////////////////////////////////////
  String get valueString => varKey.stringify<V>(value);

  @override
  String toString() => '${describeIdentity(this)}(<$V>$value)($numView)';

  // ValueListenable<String> get toTextListenable => ValueNotifier<String>(valueString);

  ////////////////////////////////////////////////////////////////////////////////
  /// Json
  ////////////////////////////////////////////////////////////////////////////////
  Map<String, Object?> toJson() {
    return {'varId': dataKey, 'varValue': numView, 'dataValue': dataValue, 'description': varKey.label};
  }

  /// init values from json config file, no new/allocation.
  /// caller may need to reinit references
  void loadFromJson(Map<String, Object?> json) {
    if (json case {'varId': int dataKey, 'varValue': num viewValue, 'dataValue': int _, 'description': String _}) {
      updateByFile(viewValue);

      assert(dataKey == this.dataKey, 'VarKey mismatch: $dataKey != ${this.dataKey}'); // handled by caller
      // viewValue bound should keep dataValue within format bounds after conversion
      // assert((varKey.binaryFormat?.max != null) ? (dataValue <= varKey.binaryFormat!.max) : true);
      // assert((varKey.binaryFormat?.min != null) ? (dataValue >= varKey.binaryFormat!.min) : true);
    }
  }

  // for set before loading num limits
  void updateByFile(num newValue) => numView = newValue;

  // ////////////////////////////////////////////////////////////////////////////////
  // /// PollingScope
  // ////////////////////////////////////////////////////////////////////////////////
  // PollingScope? polling;

  // @override
  // void addListener(VoidCallback listener) {
  //   polling?.add(this);
  //   super.addListener(listener);
  // }

  // @override
  // void removeListener(VoidCallback listener) {
  //   super.removeListener(listener);
  //   if (!hasListeners) polling?.remove(this);
  // }
}

extension VarNotifiers on Iterable<VarNotifier> {
  Iterable<(String, num)> get namedValues => map((e) => (e.varKey.label, e.valueAsNum));
  Iterable<(VarKey, VarNotifier)> get keyed => map((e) => (e.varKey, e));

  Iterable<String> toNamedValueStrings([String divider = ': ', int precision = 2]) {
    return namedValues.map((e) => '${e.$1}$divider${e.$2.toStringAsFixed(precision)}');
  }
}

/// [VarValueNotifier<V>]
/// A notifier combining a ValueNotifier with support for conversion between view types and data values.
///   - Implements [ValueNotifier]
///   - hold value allocation
///   - Unit conversion between view and data values
///   - all mutability contained in a single layer, to simplify syncing and state management
///   - Sync local and remote values, with pending change tracking
/// It be can further combined with a status notifier.
abstract mixin class VarValueNotifier<V> implements VarValue<V>, ValueNotifier<V> {
  ////////////////////////////////////////////////////////////////////////////////
  /// Typed view [value] as view side
  ////////////////////////////////////////////////////////////////////////////////
  @override
  V get value => view;
  @override
  set value(V newValue) {
    // if (view == newValue) return;
    if (_viewValue == newValue) return;
    view = newValue;
    notifyListeners();
  }

  // by user for output
  void updateByView(V newValue) => value = newValue;

  // also clear on updateByDataStatus
  void commitUserChanges() => commitView();

  // Call to discard user changes
  void discardUserChanges() {
    if (_viewValue != null) {
      _viewValue = null; // Value reverts to last update by server value
      notifyListeners();
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// [dataValue] Inbound data from server/packets
  ////////////////////////////////////////////////////////////////////////////////
  int get dataValue => data;

  void updateByData(int bytesValue) {
    data = bytesValue; // Always update server value
    if (_viewValue == null) notifyListeners(); // Only notify if effective value changed
  }

  ////////////////////////////////////////////////////////////////////////////////
  /// runtime variables
  ////////////////////////////////////////////////////////////////////////////////
  bool get hasPendingChanges => _viewValue != null;
}

mixin class VarValue<V> {
  /// `Config`
  /// caching results from VarKey for performance.
  /// by default get from varKey. resolve in constructor to cached values derived from varKey
  /// Handle Return as the exact type, to account for user defined method on that type
  // codec handles sign extension and conversion
  // does not have to be immutable. only case of cache preallocate can benefit from immutable
  late BinaryCodec<V> codec;

  V viewOf(int data) => codec.decode(data);
  int dataOf(V view) => codec.encode(view);

  /// `Runtime`
  /// Handle syncing server data and local view, mark for outbound
  /// Implementation
  ///   Base storage as server's native type.
  ///   convert on transmit only, get [data]. lazy update on updateByView
  ///   [serverData] is public for `Read Only Mode` vars setter access, may directly access serverData. [_viewValue] is not updated;
  int serverData = 0; // Server data. Source of truth from server. in sync with server by receive and commit to transmit.
  V? _viewValue; // User view - BOTH cached UI changes + pending before commit. (null => synchronized). Cached storage as view + effectively LastUpdateFlag

  /// [data] to/from server. Always accept server data.

  /// [get] on transmit to server. serverData unless pending _viewValue is set
  /// value over view boundaries handle by [view]
  int get data => (_viewValue == null) ? serverData : dataOf(_viewValue as V);

  /// [set] on receive from server. always store serverData even if pending
  /// does not update/overwrite [view] if it was set by the UI
  set data(int newValue) {
    serverData = newValue; // codec handle sign extension
    // or remove and manually call commit
    // auto restore control to serverData for read/write-only cases
    if (_viewValue case V val when val == viewOf(newValue)) _viewValue = null; // clear pending, view as serverData again, only if user value matches server value,
  }

  /// [view] value linked to UI

  /// [get] UI. last UI set takes precedence, get the same as set value
  V get view => _viewValue ?? viewOf(serverData);

  /// [set] UI. update view without outputting to server, wait for commit to set [dataOf(_viewValue as V)]
  /// always sets pending first, submit needs to mark pending, unless add to outbound collection is implemented
  set view(V newValue) => _viewValue = newValue; // let codec handle clamping on [encode], view may be out of bounds

  /// separate clear pending.
  /// submit/mark for outbound to server, not for view-only changes
  /// call on Status response to restore serverData as source
  /// restore get [view] to reflect serverData, [viewOf(serverData)],
  /// after calling, unaccepted [view] changes will be overwritten
  // No notification needed - view value doesn't change
  void commitView() {
    if (_viewValue case V val) {
      serverData = dataOf(val); // update in case of write only var, no server polling updates
      _viewValue = null; // unblocks further [data] updates to affect [view]
    }
  }

  ///
  bool get isLastUpdateByView => _viewValue != null;
  bool get isLastUpdateByData => _viewValue == null;
  // bool get isSynced => isLastUpdateByData;

  // enum VarLastUpdate { view, data, synced } as combined status
  //   VarLastUpdate get lastUpdate {
  //     (_viewValue == null)
  // (viewOf(serverData) == _viewValue) ? VarLastUpdate.data : VarLastUpdate.view;
  //     hasPendingChanges ? VarLastUpdate.view : VarLastUpdate.data;
  //   }

  ////////////////////////////////////////////////////////////////////////////////
  /// [numView] The num view representation of the [view] value as a num.
  /// serialization use
  ////////////////////////////////////////////////////////////////////////////////
  num get numView {
    return switch (V) {
      const (int) || const (double) || const (num) => view as num,
      const (bool) => (view as bool) ? 1 : 0,
      _ => data,
    };
  }

  set numView(num newValue) {
    view = switch (V) {
      const (int) => newValue.toInt() as V,
      const (double) => newValue.toDouble() as V,
      const (num) => newValue as V,
      const (bool) => (newValue != 0) as V,
      _ => viewOf(newValue as int), // stored as data
    };
  }

  /// [valueAs<V>] Generic parameter / union handling
  /// UnionCodec
  num get valueAsNum => numView;
  int get valueAsInt => (numView).toInt();
  double get valueAsDouble => (numView).toDouble();
  bool get valueAsBool => (numView != 0);
  String get valueAsString => String.fromCharCodes(valueAsBytes);
  Uint8List get valueAsBytes => Uint8List(8)..buffer.asByteData().setUint64(0, numView as int, Endian.little);
}

// simplified version without local view cache
// polling vars may overwrite user changes before they are sent
// UI-only change vs submit for push must be implemented separately
// no cache for intermediate UI view initiated changes/animations (e.g. slider)
// less sync step, but more expensive to convert on every view get and set,
// UI updates 16ms, serverUpdates ~50ms
// mixin class VarData<V> {
//   BinaryUnionCodec<V> codec = BinaryUnionCodec<V>.of();

//   V viewOf(int data) => codec.decode(data);
//   int dataOf(V view) => codec.encode(view);

//   int data = 0; // Source of truth from server. Base storage as server's native type

//   V get view => viewOf(data);
//   set view(V newValue) => data = dataOf(newValue);
// }

////////////////////////////////////////////////////////////////////////////////
/// [VarStatusNotifier]
/// implement as mixin
///   optionally mixin to share notifier
///   or compose for seperated value/status, multiple status
///     if status is only updated on value update
///   e.g.status from client side
///
/// alternatively, include code value only, caller handling Enum mapping
///
/// Does not mixin ValueNotifier<VarStatus> to not take up single inheritance
/// S does not have to be generic if all vars share the same status type
///
// todo as async status contain response status handle user iniiated await
////////////////////////////////////////////////////////////////////////////////
abstract mixin class VarStatusNotifier implements ChangeNotifier {
  int _statusCode = 0;
  int get statusCode => _statusCode;
  set statusCode(int value) {
    _statusCode = value;
    notifyListeners();
  }

  VarStatus statusOf(int statusCode) => VarStatus.defaultOf(statusCode);

  VarStatus get status => statusOf(statusCode);
  set status(VarStatus newValue) => statusCode = newValue.code;

  void updateStatusByData(int status) => statusCode = status;
  void updateStatusByView(VarStatus status) => statusCode = status.code;

  // hand by format
  Enum? get statusAsEnum => status.enumId;
  bool get statusIsError => statusCode != 0;
  bool get statusIsSuccess => statusCode == 0;
}

//////////////////////////////////////////////////////////////////////////////
// User submit
//   associated with UI component, instead of VarNotifier value
//   not triggered by value changes
//   Listeners to the VarNotifier value on another UI component will not be notified of submit
//////////////////////////////////////////////////////////////////////////////
class VarEventNotifier<V> extends ChangeNotifier {
  VarEventNotifier({required this.varNotifier, required this.onSubmit});
  final VarNotifier<V> varNotifier; // typed by Key. returning as dynamic.
  final ValueSetter<VarNotifier<V>> onSubmit; // handle additional logic on submit

  void submitByView(V varValue) {
    varNotifier.updateByView(varValue);
    onSubmit(varNotifier);
    notifyListeners();
  }

  void call(Function(VarNotifier<V>) submitAction) {
    submitAction(varNotifier);
    notifyListeners();
  }
}
