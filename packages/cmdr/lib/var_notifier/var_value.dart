part of 'var_notifier.dart';

/// [VarDataView<V>]
/// UnionCodec + InplaceValue + sync pending buffer
/// handle conversions
/// handling syncing 2 variable representations
/// optionally split union value interface
mixin class VarValue<V> {
  /// Config
  /// caching results from VarKey for performance. does not have to be immutable.
  /// all mutability is contained in a single layer. cache preallocate can be immutable
  /// by default get from varKey. resolve in constructor to cached values derived from varKey
  ///
  /// Handle Return as the exact type, to account for user defined method on that type
  /// codec handles sign extension
  BinaryUnionCodec<V> codec = BinaryUnionCodec<V>.of();

  V viewOf(int data) => codec.decode(data);
  int dataOf(V view) => codec.encode(view);

  /// runtime
  /// Handle syncing server data and local view, mark for outbound
  /// `ReadOnly Mode` may directly access serverData. _pendingValue is not updated;
  int serverData = 0; // Source of truth from server // Base storage as server's native type
  V? _pendingValue; // User changes (null = synchronized), // effectively LastUpdateFlag

  /// [view] the value seen by the user
  V get view => _pendingValue ?? viewOf(serverData); // Single source of truth: pending takes precedence

  /// update view without outputting to server
  /// always sets pending first,  submit needs to mark pending unless add to outbound Set is implemented
  set view(V newValue) {
    // _pendingValue = newValue; // let codec handle clamping on [encode], view may be out of bounds
    _pendingValue = switch (V) {
      const (int) => codec.clamp(newValue as int).toInt() as V,
      const (double) => codec.clamp(newValue as double).toDouble() as V, // clamp returns num, maybe return int
      const (num) => codec.clamp(newValue as num) as V,
      const (bool) => newValue,
      _ => newValue,
    };
  }

  /// additional way to clear pending on Status response
  /// restore [get view] to [serverData]
  /// not for view `submit`, pending marks for outbound stream
  void commitView() {
    if (_pendingValue case V newValue) {
      serverData = dataOf(newValue); // update in case of write only, no server polling updates
      _pendingValue = null; // allow further [data] updates to determine [view]
      // No notification needed - effective value doesn't change
    }
  }

  /// [data] to/from packet. convert on transmit only. lazy update on updateByView
  /// Always accept server data.
  /// value over view boundaries handle by [view]
  int get data => (_pendingValue != null) ? dataOf(_pendingValue as V) : serverData;

  set data(int newValue) {
    serverData = newValue; // codec handle sign extension
    if (_pendingValue == null) return;
    if (_pendingValue == viewOf(newValue)) _pendingValue = null; // only if user value matches server value, clear pending.
  }

  /// todo move to codec unioinValue
  /// [numView] The num view representation of the [view] value as a num.
  //  BinaryNumCodec<num> numCodec = BinaryNumCodec<num>.of(); optionally include as default num codec

  // /   since it is the base for all generic types that can be converted to and from,
  // /     [valueAs<R>()] can always return a value without throwing; the closest representation possible.
  // /   primitive/register sized only for now
  // /   consistent DataOfView interface
  // /   multiple view on the same value will require conversion anyway
  // /   using view side num as notifier,
  // /   notify view side listener on all updates, not all changes are pushed to client

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

  /// assert(V is num);
  // bool get isOverLimit => (numView > codec.numLimits!.max);
  // bool get isUnderLimit => (numView < codec.numLimits!.min);
  double get normalized => (numView / codec.numLimits!.max).clamp(-1.0, 1.0);
  double get percent => normalized * 100;

  /// [valueAs<V>] Generic parameter / union handling
  /// UnionCodec
  /// widgets optionally select
  num get valueAsNum => numView;
  int get valueAsInt => (numView).toInt();
  double get valueAsDouble => (numView).toDouble();
  bool get valueAsBool => (numView != 0);
  Enum get valueAsEnum => codec?.enumOf(numView as int) ?? VarValueEnum.unknown;
  BitStruct get valueAsBitFields => codec?.bitsOf(numView as int) ?? BitStruct.view([], valueAsInt as Bits);
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
    // if (TypeKey<R>().isSubtype<V>()) return view as R;
    // codec.decodeAs<R>( numValue.toInt());
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
  /// generic setter can optionally switch on object type
  void updateValueAs<T>(T typedValue) {
    if (T == V) {
      view = typedValue as V;
    } else {
      numView = numValueOf<T>(typedValue);
      // view = decode(numValueOf<T>(typedValue).toInt()),
    }
  }

  // void updateValueAs<T>(T typedValue) {
  //   numValue = switch (T) {
  //     _ when T == V => typedValue as num,
  //     const (double) || const (int) || const (num) => (typedValue as num),
  //     const (bool) => (typedValue as bool) ? 1 : 0,
  //     const (Enum) => (typedValue as Enum).index,
  //     const (BitStruct) => (typedValue as BitStruct).bits,
  //     _ => throw UnsupportedError('Unsupported type: $T'),
  //   };

  //   lastUpdate = VarLastUpdate.byView;
  //   if (typedValue case num input when input != numValue) statusCode = 1;
  // }
}

// simplified version without local view cache
// mixin class _VarData<V> {
//   BinaryUnionCodec<V> codec = BinaryUnionCodec<V>.of();

//   V viewOf(int data) => codec.decode(data);
//   int dataOf(V view) => codec.encode(view);

//   int serverData = 0; // Source of truth from server // Base storage as server's native type

//   V get view => viewOf(serverData); // Single source of truth: pending takes precedence
//   set view(V newValue) => serverData = dataOf(newValue);

//   int get data => serverData;
//   set data(int newValue) => serverData = newValue;
// }
