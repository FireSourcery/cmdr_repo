part of 'var_notifier.dart';

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
