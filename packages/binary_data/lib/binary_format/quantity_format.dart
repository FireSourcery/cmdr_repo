import '../data/num_ext.dart';
import 'binary_format.dart';
import 'binary_codec.dart';

///
/// [Num]
///
/// Quantity Codec
// wrapper around num for runtime creation. conversion in 1 step. alternatively chain function calls
class BinaryQuantityCodec<V extends num> implements BinaryCodec<V> {
  const BinaryQuantityCodec(this.format, this.numConversion, {this.numLimits});

  // const BinaryNumCodec.integer(this.format, {this.numLimits}) : numConversion = _disabled;

  // NumConversion override
  BinaryQuantityCodec.of(this.format, {NumDataConversion? conversion, this.numLimits})
    : numConversion = switch (format) {
        IntFormat() => _disabled,
        FractFormat() => conversion ?? _disabled,
        Adcu() => conversion ?? _disabled,
      };

  // BinaryQuantityCodec.linear(this.format, num unitRef, {this.numLimits}) : numConversion = NumLinearConversion(unitRef / format.reference).conversion ?? _disabled;

  //alternatively wrap format with numeric only conversion

  final NumFormat<dynamic, V> format;
  final NumDataConversion numConversion;
  final ({num min, num max})? numLimits;

  num _clamp(num value) => (numLimits != null) ? value.clamp(numLimits!.min, numLimits!.max) : value;

  @override
  V decode(int data) => numConversion.viewOfData(format.signedOf(data)).to<V>();
  @override
  int encode(V view) => numConversion.dataOfView(_clamp(view));

  //alternatively
  // V decode(int data) => numConversion.of(format.decode(data)).to<V>();

  /// disabled conversion, direct data to view mapping
  static const NumDataConversion _disabled = (viewOfData: _defaultNumOf, dataOfView: _defaultDataOf);
  static num _defaultNumOf(int data) => data;
  static int _defaultDataOf(num view) => view.toInt();
}

/// Numeric value conversion
typedef NumOfData = num Function(int data);
typedef DataOfNum = int Function(num view);
typedef NumDataConversion = ({NumOfData viewOfData, DataOfNum dataOfView});

// Linear conversion between data and view
extension type const NumLinearConversion(num coefficient) {
  num viewOf(int dataValue) => (dataValue * coefficient);
  int dataOf(num viewValue) => (viewValue ~/ coefficient);

  NumDataConversion? get conversion {
    return switch (coefficient) {
      1 => null, // no conversion
      0 => null, // no conversion
      num(isFinite: false) => null, // no conversion
      _ => (viewOfData: viewOf, dataOfView: dataOf),
    };
  }
}
