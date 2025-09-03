// abstract mixin class ValueUnion<V> {
//   // /// Config
//   // /// caching results from VarKey for performance. does not have to be immutable.
//   // /// additionally all mutability is contained in a single layer. cache preallocate can be immutable
//   // /// by default get from varKey. resolve in constructor to cached values derived from varKey
//   // ///
//   // /// Handle Return as the exact type, to account for user defined method on that type
//   // /// codec handles sign extension
//   // BinaryUnionCodec<V> codec = BinaryUnionCodec<V>.of();

//   // V viewOf(int data) => codec.decode(data);
//   // int dataOf(V view) => codec.encode(view);

//   V get value;
//   set value(V newValue);

//   /// todo move to codec unioinValue
//   /// [numView] The num view representation of the [view] value as a num.
//   //  BinaryNumCodec<num> numCodec = BinaryNumCodec<num>.of(); optionally include as default num codec

//   num get numView {
//     return switch (V) {
//       const (int) || const (double) || const (num) => view as num,
//       const (bool) => (view as bool) ? 1 : 0,
//       _ => data,
//     };
//   }

//   // set pending first
//   set numView(num newValue) {
//     view = switch (V) {
//       const (int) => newValue.toInt() as V,
//       const (double) => newValue.toDouble() as V,
//       const (num) => newValue as V,
//       const (bool) => (newValue != 0) as V,
//       _ => viewOf(newValue.toInt()), // decode to view type
//     };
//   }

//   /// assert(V is num);
//   double get normalized => (numView / codec.numLimits!.max).clamp(-1.0, 1.0);
//   double get percent => normalized * 100;

//   /// [valueAs<V>] Generic parameter / union handling
//   /// UnionCodec
//   /// widgets optionally select
//   num get valueAsNum => numView;
//   int get valueAsInt => (numView).toInt();
//   double get valueAsDouble => (numView).toDouble();
//   bool get valueAsBool => (numView != 0);
//   Enum get valueAsEnum => codec?.enumOf(numView as int) ?? VarValueEnum.unknown;
//   BitStruct get valueAsBitFields => codec?.bitsOf(numView as int) ?? BitStruct.view([], valueAsInt as Bits);
//   String get valueAsString => String.fromCharCodes(valueAsBytes);
//   Uint8List get valueAsBytes => Uint8List(8)..buffer.asByteData().setUint64(0, numView as int, Endian.little);

//   // set valueAsBool(bool newValue) => (numValue = newValue ? 1 : 0);
//   // set valueAsNum(num newValue) {
//   //   // assert(V == int || V == double, 'Only num types are supported');
//   //   if (viewer.numLimits != null) {
//   //     value = newValue.clamp(viewer.numLimits!.min, viewer.numLimits!.max) as V;
//   //   }
//   // }
//   // set valueAsEnum(Enum newValue) => _numValue = newValue.index;
//   // set valueAsEnum(Enum newValue) {
//   //   if (viewer.enumRange != null) {
//   //     if (viewer.enumRange![newValue.index] == newValue) value = newValue as V;
//   //   }
//   // }
//   // set valueAsBitFields(BitStruct newValue) => _numValue = newValue.bits;

//   ///
//   /// caller determines type after accounting for VarKey
//   /// generic getter use switch on type literal, and require extension to account for subtypes
//   R valueAs<R>() {
//     if (R == V) return view as R;
//     // codec.decodeAs<R>( numValue.toInt());
//     return switch (R) {
//           const (int) => valueAsInt,
//           const (double) => valueAsDouble,
//           const (num) => valueAsNum,
//           const (bool) => valueAsBool,
//           // match by type literal cannot be subtype
//           const (Enum) => valueAsEnum,
//           const (BitStruct) => valueAsBitFields,
//           const (String) => valueAsString,
//           _ => throw UnsupportedError('Unsupported type: $R'),
//         }
//         as R;
//   }

//   /// update
//   static num numValueOf<T>(T typedValue) {
//     return switch (T) {
//       const (int) => typedValue as int,
//       const (double) => typedValue as double,
//       const (num) => typedValue as num,
//       const (bool) => (typedValue as bool) ? 1 : 0,
//       const (Enum) => (typedValue as Enum).index,
//       const (BitStruct) => (typedValue as BitStruct).bits,
//       _ => throw UnsupportedError('Unsupported type: $T'),
//     };
//   }

//   // input bounds checked only to ensure a valid value is sent to client side
//   // switch on value will also handle dynamic
//   /// generic setter can optionally switch on object type
//   void updateValueAs<T>(T typedValue) {
//     if (T == V) {
//       view = typedValue as V;
//     } else {
//       numView = numValueOf<T>(typedValue);
//       // view = decode(numValueOf<T>(typedValue).toInt()),
//     }
//   }

//   // void updateValueAs<T>(T typedValue) {
//   //   numValue = switch (T) {
//   //     _ when T == V => typedValue as num,
//   //     const (double) || const (int) || const (num) => (typedValue as num),
//   //     const (bool) => (typedValue as bool) ? 1 : 0,
//   //     const (Enum) => (typedValue as Enum).index,
//   //     const (BitStruct) => (typedValue as BitStruct).bits,
//   //     _ => throw UnsupportedError('Unsupported type: $T'),
//   //   };

//   //   lastUpdate = VarLastUpdate.byView;
//   //   if (typedValue case num input when input != numValue) statusCode = 1;
//   // }
// }
