import 'package:cmdr/type_ext/stringifier.dart';
import 'package:flutter/foundation.dart';

// setting/var notifier
abstract interface class ValueViewer<V> {
  // alternatively handle in constructor
  // FloatingLabelAlignment? get labelAlignment;
  bool get showLabel;
  bool get showPrefix;
  bool get showSuffix;
  bool? get isDense;
  bool? get readOnly;

  // InputDecoration? idDecoration

  // control over whether the parameters from VarNotifier are passed

  // InputDecoration get idDecoration {
  //   return InputDecoration(
  //     labelText: (showLabel) ?  label : null,
  //     prefixIcon: (showPrefix) ? (!isReadOnly ? const Icon(Icons.input) : null) : null,
  //     suffixText: (showSuffix) ?  suffix : null,
  //     isDense: isDense,
  //     // floatingLabelAlignment: labelAlignment,
  //   );
  // }

  bool get isReadOnly;

  Listenable get valueListenable;

  ValueGetter<V> get valueGetter;

  // ValueGetter<String> get valueStringGetter;

  ValueSetter<V> get valueSetter;

  ValueGetter<bool> get errorGetter;

  ValueChanged<V> get valueChanged;

  String get tip;

  ({num max, num min})? get valueNumLimits;
  List<V>? get valueEnumRange;

  Stringifier<V>? get valueStringifier;
}

/// num/double/int share the decimal keyboard and clamp; subtypes narrow the format and result.
// abstract interface class ValueViewerNum<T extends num> extends ValueViewer<T> {
//   ValueViewerNum({Key? key}) : assert(config.valueNumLimits != null, 'num field requires valueNumLimits');

//   @override
//   List<TextInputFormatter>? get inputFormatters => [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')), FilteringTextInputFormatter.singleLineFormatter];
//   @override
//   TextInputType get keyboardType => const TextInputType.numberWithOptions(decimal: true, signed: true);
//   @override
//   T? parse(String text) => _fromNum(num.tryParse(text)?.clamp(numMin, numMax));

//   T? _fromNum(num? value) => value as T?;
// }

// abstract interface class ValueViewerDouble extends ValueViewer<double> {
//   @override
//   T? _fromNum(num? value) => value?.toDouble() as T?;
// }

// abstract interface class ValueViewerInt extends ValueViewerNum<int> {
//   ValueViewerInt(super.config, {super.key});
//   @override
//   List<TextInputFormatter>? get inputFormatters => [FilteringTextInputFormatter.digitsOnly, FilteringTextInputFormatter.singleLineFormatter];
//   @override
//   TextInputType get keyboardType => const TextInputType.numberWithOptions(decimal: false, signed: true);
//   @override
//   T? _fromNum(num? value) => value?.toInt() as T?;
// }
