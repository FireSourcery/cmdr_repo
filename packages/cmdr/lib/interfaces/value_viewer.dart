import 'package:cmdr/type_ext/stringifier.dart';
import 'package:flutter/foundation.dart';

// setting/var notifier
// abstract interface class ValueViewer<V> {
//   // alternatively handle in constructor
//   // FloatingLabelAlignment? get labelAlignment;
//   bool get showLabel;
//   bool get showPrefix;
//   bool get showSuffix;
//   bool? get isDense;
//   bool? get readOnly;

//   // InputDecoration? idDecoration

//   // control over whether the parameters from VarNotifier are passed

//   // InputDecoration get idDecoration {
//   //   return InputDecoration(
//   //     labelText: (showLabel) ?  label : null,
//   //     prefixIcon: (showPrefix) ? (!isReadOnly ? const Icon(Icons.input) : null) : null,
//   //     suffixText: (showSuffix) ?  suffix : null,
//   //     isDense: isDense,
//   //     // floatingLabelAlignment: labelAlignment,
//   //   );
//   // }

//   bool get isReadOnly;

//   Listenable get valueListenable;

//   ValueGetter<V> get valueGetter;

//   // ValueGetter<String> get valueStringGetter;

//   ValueSetter<V> get valueSetter;

//   ValueGetter<bool> get errorGetter;

//   ValueChanged<V> get valueChanged;

//   String get tip;

//   ({num max, num min})? get valueNumLimits;
//   List<V>? get valueEnumRange;

//   Stringifier<V>? get valueStringifier;
// }

// abstract mixin class _IOFieldStringBox<T> implements IOField<T> {
//   ValueGetter<T?> get valueGetter;
//   ValueGetter<String>? get valueStringGetter;
//   Stringifier<T>? get valueStringifier;

//   static String _stringifyDefault(Object? value) => value.toString(); // unhandled null value string
//   // static String _stringifyEnum(Enum value) => value.name.titleCase;

//   Stringifier<T> get _effectiveStringifier => valueStringifier ?? _stringifyDefault;

//   Stringifier<T?> get _effectiveNullableStringifier {
//     if (valueStringifier case Stringifier<T?> stringifier) stringifier;
//     return _stringifyDefault;
//   }

//   String _stringifyValue() {
//     if (valueGetter() case T value) return _effectiveStringifier(value);
//     return ''; // or handle null

//     // _effectiveNullableStringifier(valueGetter());
//   }

//   ValueGetter<String> get _effectiveValueStringGetter => valueStringGetter ?? _stringifyValue;

//   // String? get fieldLabel => inputDecoration?.labelText;
// }
