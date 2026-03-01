part of 'var_notifier.dart';

/// [VarDataView<V>]
///   - handle type and numeric unit conversions, [UnionCodec]
///   - sync 2 variable representations, local and remote
///   - all mutability contained in a single layer, to simplify syncing and state management
///   - hold value allocation
// optionally split union value interface
mixin class VarValue<V> {
  /// `Config`
  /// caching results from VarKey for performance.
  /// by default get from varKey. resolve in constructor to cached values derived from varKey
  /// Handle Return as the exact type, to account for user defined method on that type
  // codec handles sign extension
  // does not have to be immutable. only case of cache preallocate can benefit from immutable
  late BinaryCodec<V> codec;
  NumUnionCodec? unionCodec;

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
  // int get data => serverData; // on transmit to server. committed value only

  /// [set] on receive from server. always store serverData even if pending
  /// does not update/overwrite [view] if it was set by the UI
  set data(int newValue) {
    serverData = newValue; // codec handle sign extension
    if (_viewValue case V val when val == viewOf(newValue)) _viewValue = null; // clear pending, view as serverData again, only if user value matches server value,
    // auto restore control to serverData for read/write-only cases
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
  bool get isSynced => isLastUpdateByData;
  // alternatively separate
  // enum VarLastUpdate { clear, byData, byView }

  /// assert(V is num);
  // bool get isOverLimit => (numView > codec.numLimits!.max);
  // bool get isUnderLimit => (numView < codec.numLimits!.min);
  // double get normalized => (numView / codec!.numLimits!.max).clamp(-1.0, 1.0);
  // double get percent => normalized * 100;

  /// value conversion
  /// todo move to codec unionValue
  /// [numView] The num view representation of the [view] value as a num.
  // /     [valueAs<R>()] can always return a value without throwing; the closest representation possible.
  num get numView {
    return switch (V) {
      const (int) || const (double) || const (num) => view as num,
      const (bool) => (view as bool) ? 1 : 0,
      _ => data,
    };
  }

  // set pending first
  set numView(num newValue) {
    view = switch (V) {
      const (int) => newValue.toInt() as V,
      const (double) => newValue.toDouble() as V,
      const (num) => newValue as V,
      const (bool) => (newValue != 0) as V,
      _ => viewOf(newValue.toInt()), // decode to view type
    };
  }

  /// [valueAs<V>] Generic parameter / union handling
  /// UnionCodec
  /// widgets optionally select
  num get valueAsNum => numView;
  int get valueAsInt => (numView).toInt();
  double get valueAsDouble => (numView).toDouble();
  bool get valueAsBool => (numView != 0);
  Enum get valueAsEnum => unionCodec?.enumOf(numView as int) ?? VarValueEnum.unknown;
  BitStruct get valueAsBitFields => unionCodec?.bitsOf(numView as int) ?? BitStruct.view([], valueAsInt as Bits);
  String get valueAsString => String.fromCharCodes(valueAsBytes);
  Uint8List get valueAsBytes => Uint8List(8)..buffer.asByteData().setUint64(0, numView as int, Endian.little);

  // set valueAsBool(bool newValue) => (numValue = newValue ? 1 : 0);
  // set valueAsNum(num newValue) {
  //   // assert(V == int || V == double, 'Only num types are supported');
  //   if (viewer.numLimits != null) {
  //     value = newValue.clamp(viewer.numLimits!.min, viewer.numLimits!.max) as V;
  //   }
  // }
  // set valueAsEnum(Enum newValue) => _numValue = newValue.index;
  // set valueAsEnum(Enum newValue) {
  //   if (viewer.enumRange != null) {
  //     if (viewer.enumRange![newValue.index] == newValue) value = newValue as V;
  //   }
  // }
  // set valueAsBitFields(BitStruct newValue) => _numValue = newValue.bits;

  ///
  /// caller determines type after accounting for VarKey
  /// generic getter use switch on type literal, and require extension to account for subtypes
  R valueAs<R>() {
    if (R == V) return view as R;

    return switch (R) {
          const (int) => valueAsInt,
          const (double) => valueAsDouble,
          const (num) => valueAsNum,
          const (bool) => valueAsBool,
          // match by type literal cannot be subtype
          const (Enum) => valueAsEnum,
          const (BitStruct) => valueAsBitFields,
          const (String) => valueAsString,
          _ => throw UnsupportedError('Unsupported type: $R'),
        }
        as R;
  }

  /// update
  static num numValueOf<T>(T typedValue) {
    return switch (T) {
      const (int) => typedValue as int,
      const (double) => typedValue as double,
      const (num) => typedValue as num,
      const (bool) => (typedValue as bool) ? 1 : 0,
      const (Enum) => (typedValue as Enum).index,
      const (BitStruct) => (typedValue as BitStruct).bits,
      _ => throw UnsupportedError('Unsupported type: $T'),
    };
  }

  // input bounds checked only to ensure a valid value is sent to client side
  // switch on value will also handle dynamic
  // generic setter can optionally switch on object type
  void updateValueAs<T>(T typedValue) {
    if (T == V) {
      view = typedValue as V;
    } else {
      numView = numValueOf<T>(typedValue);
      // view = decode(numValueOf<T>(typedValue).toInt()),
    }
  }
}

// replace null for over bounds
enum VarValueEnum { unknown }

// simplified version without local view cache
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
