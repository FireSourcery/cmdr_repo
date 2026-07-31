import 'package:struct_data/struct_data.dart';

///

///
///
///
// class NumUnion<V> with NumUnionCodec<V> {
//   NumUnion({this.numLimits, this.enumRange, this.bitsKeys});
//   final ({num min, num max})? numLimits; // must be null for non-num types
//   final List<Enum>? enumRange; // EnumSubtype.values must be non-null for Enum types
//   final List<BitField>? bitsKeys;
// }

// abstract mixin class NumUnionCodec<V> {
//   // maintain for view options
//   // Limits as the values the num can take, inclusive, compare with >= and <=
//   ({num min, num max})? get numLimits; // must be null for non-num types
//   List<Enum>? get enumRange; // EnumSubtype.values must be non-null for Enum types
//   List<BitField>? get bitsKeys;
//   // Iterable<V>? get enumRange;
//   // ({V min, V max})? get numLimits; // must be null for non-num types

//   V decode(int data) => decodeAs<V>(data);
//   int encode(V view) => encodeAs<V>(view);

//   num clamp(num value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) : value;
//   Enum? enumOf(int value) => enumRange?.byIndex(value);
//   BitStruct bitsOf(int value) => BitStruct.from(value);

//   // default without conversion
//   R decodeAs<R>(int data) {
//     return switch (R) {
//           const (int) => data,
//           const (double) => data.toDouble(),
//           const (num) => data,
//           const (bool) => (data != 0),
//           const (Enum) => enumRange!.byIndex(data),
//           const (BitStruct) => BitStruct.from(data),
//           _ => throw UnsupportedError('Unsupported type: $R'),
//         }
//         as R;
//   }

//   int encodeAs<T>(T view) {
//     return switch (T) {
//       const (int) => view as int,
//       const (double) => (view as double).toInt(),
//       const (num) => (view as num).toInt(),
//       const (bool) => (view as bool) ? 1 : 0,
//       const (Enum) => (view as Enum).index,
//       const (BitStruct) => (view as BitStruct).bits,
//       _ => throw UnsupportedError('Unsupported type: $T'),
//     };
//   }

//   V get valueDefault {
//     return switch (V) {
//           const (int) => 0,
//           const (double) => 0.0,
//           const (String) => '',
//           const (bool) => false,
//           // const (Enum) => Enum.unknown,
//           _ => decode.call(0) ?? (throw UnsupportedError('Unsupported type: $V')),
//         }
//         as V;
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
// }
