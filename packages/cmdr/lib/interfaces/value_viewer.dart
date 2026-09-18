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
/// convenience interface for mapping widget callbacks
///
/// implicitly casts the VarNotifier 
// extension VarNotifierViewer<V> on VarNotifier {
//   // const VarNotifierViewer();
//   //   _VarWidgetSource.assertType(this.eventNotifier) : assert(eventNotifier.varNotifier.varKey.viewType.isExactType<T>());

//   @protected
//   VarNotifier<dynamic> get varNotifier => this;
//   // VarEventController? get eventController;

//   ValueNotifier<dynamic> get valueNotifier => varNotifier; // for value updates
//   ValueChanged<V> get valueChanged => varNotifier.updateByViewAs<V>; // onChange. call for all updates to update UI

//   // Anonymous functions defined this way should not be reallocated
//   ValueGetter<V> get valueGetter => varNotifier.valueAs<V>;
//   ValueGetter<String> get valueStringGetter => varNotifier.valueStringAs<V>; // default valueStringifier
//   ValueGetter<bool> get statusErrorGetter => (() => varNotifier.statusIsError);
//   ValueGetter<Enum?> get statusEnumGetter => (() => varNotifier.status.enumId);
//   ValueGetter<VarStatus> get statusGetter => (() => varNotifier.status);

//   V get viewValue => varNotifier.valueAs<V>();
//   ({num max, num min})? get valueNumLimits => varNotifier.varKey.valueNumLimits;

//   Stringifier<V> get valueStringifier => varNotifier.varKey.stringify<V>; // can be used to generate value labels for values other than the current value
//   bool get isReadOnly => varNotifier.varKey.isReadOnly;
//   String? get tip => varNotifier.varKey.tip;

//   // ValueSetter<V> get valueSubmitted => cache.eventController.submitByViewAs<V>; // onSubmit. only for updates requesting write and/or indicating user confirmation. using scheduled write
// }

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
 
