import '../binary_data.dart';

///

///
///
///
class NumUnion<V> with NumUnionCodec<V> {
  NumUnion({this.numLimits, this.enumRange, this.bitsKeys});
  final ({num min, num max})? numLimits; // must be null for non-num types
  final List<Enum>? enumRange; // EnumSubtype.values must be non-null for Enum types
  final List<BitField>? bitsKeys;
}

abstract mixin class NumUnionCodec<V> {
  // maintain for view options
  // Limits as the values the num can take, inclusive, compare with >= and <=
  ({num min, num max})? get numLimits; // must be null for non-num types
  List<Enum>? get enumRange; // EnumSubtype.values must be non-null for Enum types
  List<BitField>? get bitsKeys;
  // Iterable<V>? get enumRange;
  // ({V min, V max})? get numLimits; // must be null for non-num types

  V decode(int data) => decodeAs<V>(data);
  int encode(V view) => encodeAs<V>(view);

  num clamp(num value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) : value;
  Enum? enumOf(int value) => enumRange?.elementAtOrNull(value);
  BitStruct bitsOf(int value) => BitStruct.view(bitsKeys ?? <BitField>[], value as Bits);

  // default without conversion
  R decodeAs<R>(int data) {
    return switch (R) {
          const (int) => data,
          const (double) => data.toDouble(),
          const (num) => data,
          const (bool) => (data != 0),
          const (Enum) => enumRange!.elementAtOrNull(data.clamp(0, enumRange!.length - 1)),
          const (BitStruct) => BitStruct.view(bitsKeys ?? <BitField>[], data as Bits),
          _ => throw UnsupportedError('Unsupported type: $R'),
        }
        as R;
  }

  int encodeAs<T>(T view) {
    return switch (T) {
      const (int) => view as int,
      const (double) => (view as double).toInt(),
      const (num) => (view as num).toInt(),
      const (bool) => (view as bool) ? 1 : 0,
      const (Enum) => (view as Enum).index,
      const (BitStruct) => (view as BitStruct).bits,
      _ => throw UnsupportedError('Unsupported type: $T'),
    };
  }

  V get valueDefault {
    return switch (V) {
          const (int) => 0,
          const (double) => 0.0,
          const (String) => '',
          const (bool) => false,
          // const (Enum) => Enum.unknown,
          _ => decode.call(0) ?? (throw UnsupportedError('Unsupported type: $V')),
        }
        as V;
  }
}

// abstract mixin class UnionFormat<V> {}

/// mixin value field
// abstract mixin class NumUnion  {
//   num get numValue;
//   set numValue(num newValue);

//   ({num min, num max})? get numLimits; // must be null for non-num types
//   List<Enum>? get enumRange; // EnumSubtype.values must be non-null for Enum types
//   List<BitField>? get bitsKeys;

//   R valueAs<R>() {
//     if (R == V) return decode(numValue.toInt());
//     return switch (R) {
//           const (int) => numValue.toInt() as R,
//           const (double) => numValue.toDouble() as R,
//           const (num) => numValue as R,
//           const (bool) => (numValue != 0) as R,
//           const (Enum) => enumRange?.byIndex(numValue.toInt())  ,
//           const (BitStruct) => BitStruct.view(bitsKeys ?? <BitField>[], numValue.toInt() as Bits) as R,
//           _ => throw UnsupportedError('Unsupported type: $R'),
//         }
//         as R;
//   }
// }

// extension on num {
//   V cast<V>([dynamic param]) {
//     return switch (V) {
//       const (int) => toInt() as V,
//       const (double) => toDouble() as V,
//       const (num) => this as V,
//       const (bool) => (this != 0) as V,

//       _ => throw UnsupportedError('Unsupported type: $V'),
//     };
//   }

//   BitStruct castAsStruct(List<BitField> bitsKeys) {
//     return BitStruct.view(bitsKeys, toInt() as Bits);
//   }

//   V castAsEnum<V>(List<V> enumRange) {
//     if (this is int) {
//       return enumRange.elementAtOrNull(this.toInt()) as V;
//     } else {
//       throw UnsupportedError('Unsupported type for enum casting: ${runtimeType}');
//     }
//   }
// }
