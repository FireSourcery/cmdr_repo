import '../utilities/basic_ext.dart';
import '../utilities/num_ext.dart';
import 'binary_format.dart';

/// [Quantity Codec]
// wrapper around num for runtime creation. conversion in 1 step. alternatively chain function calls
// double only if other cases are handled
class BinaryQuantityCodec<V extends num> implements BinaryCodec<V> {
  const BinaryQuantityCodec(this.format, this.numConversion, {this.numLimits});

  BinaryQuantityCodec.of(this.format, {NumDataConversion? conversion, ({num min, num max})? numLimits})
    : numConversion = switch (format) {
        IntFormat() => _disabled, // handle with sign extension + bounds. // scaled down int (larger quantity) treat as fract for now.
        FractFormat() => conversion ?? _disabled,
        Adcu() => conversion ?? _disabled,
      },
      numLimits = numLimits ?? numLimitsOf(conversion, format);

  final NumFormat<dynamic, V> format;
  final NumDataConversion numConversion;
  final ({num min, num max})? numLimits; // quantity limits.

  @override
  V decode(int data) => numConversion.viewOfData(format.signedOf(data)).to<V>();
  @override
  int encode(V view) => numConversion.dataOfView(view).clamp(format.binaryRange.min, format.binaryRange.max);

  // num _clamp(num value) => numLimits?.clamp(value) ?? value;
  //     return numConversion.dataOfView(_clamp(view));

  static ({num min, num max})? numLimitsOf(NumDataConversion? conversion, BinaryFormat<dynamic, num> format) {
    return conversion?.ifNonNull((conv) => format.binaryRange * conv.viewOfData(1));
  }

  /// disabled conversion, direct data to view mapping
  static const NumDataConversion _disabled = (viewOfData: _defaultNumOf, dataOfView: _defaultDataOf);
  static num _defaultNumOf(int data) => data;
  static int _defaultDataOf(num view) => view.toInt();
}

/// Numeric value conversion
typedef NumOfData = num Function(int data);
typedef DataOfNum = int Function(num view);
typedef NumDataConversion = ({NumOfData viewOfData, DataOfNum dataOfView});

extension type const NumDataScale(num coefficient) {
  num viewOf(int dataValue) => (dataValue * coefficient);
  int dataOf(num viewValue) => (viewValue ~/ coefficient);

  NumDataConversion? get conversion {
    // no conversion needed for coefficient of 1, 0, or infinite (e.g. for unbounded quantities).
    if (coefficient case 1 || 0 || num(isFinite: false)) return null;
    return (viewOfData: viewOf, dataOfView: dataOf);
  }
}

extension NumDataConversionOperators on NumDataConversion {
  num get unit => viewOfData(1);
}

// Caller provides [NumConversion] for chaining
// wrap format with numeric only conversion
// class BinaryQuantityCodecWith<V extends num> implements BinaryCodec<V> {
//   const BinaryQuantityCodecWith(this.format, this.conversion, {this.numLimits});
//   final NumFormat<dynamic, V> format;
//   final NumConversion conversion;
//   final ({num min, num max})? numLimits;

//   @override
//   V decode(int data) => conversion.decode(format.decode(data)).to<V>();

//   @override
//   int encode(V view) => format.encode(conversion.encode(view).to<V>());
// }

// extension BinaryCodecNumExt<V extends num> on BinaryCodec<V> {
//   //   num decodeAsNum(int data) => decode(data);
//   //   int encodeAsNum(num view) => encode(view as V);
//   BinaryCodec fuseStatelessCodec(NumConversion conversion) => BinaryCodecByHandlers(
//     decoder: (data) => conversion.decode(decode(data)),
//     encoder: (view) => encode(conversion.encode(view as V) as V),
//   );
// }
// mixin QuantityFormat on NumFormat<NativeType, num> {
//   NumConversion get conversion;
//   ({num min, num max})? get numLimits; // quantity limits.

//   @override
//   num decode(int data) => conversion.decode(super.decode(data));
//   @override
//   int encode(num view) => super.encode(conversion.encode(view));
// }
