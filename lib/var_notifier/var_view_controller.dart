// import 'package:flutter/foundation.dart';

// interface class VarViewer<T> {
//   const VarViewer({
//     required this.valueListenable,
//     required this.valueGetter,
//     this.valueErrorGetter,
//     this.isReadOnly = false,
//     this.stringMap,
//     this.valueSetter,
//     this.valueChanged,
//     this.valueMin, // required for num type, slider and input range check on submit
//     this.valueMax,
//     this.tip = '',
//     this.valueStringGetter,
//   }); //assert(!((T == num || T == int || T == double) && (config.valueMin == null || config.valueMax == null)));

//   // final InputDecoration inputDecoration;
//   final bool isReadOnly;
//   final String tip;

//   /// using ListenableBuilder for cases where value is not of the same type as valueListenable
//   final Listenable valueListenable; // read/output update
//   final ValueGetter<T> valueGetter;

//   final ValueGetter<bool>? valueErrorGetter; // true on error, or use MaterialStatesController
//   final ValueGetter<String>? valueStringGetter;
//   final ValueSetter<T>? valueSetter;

// // ValueWidgetBuilder<T>
//   // Enum or bool?
//   final Map<T, String>? stringMap; //  enum Key : label
//   final num? valueMin;
//   final num? valueMax;

//   final ValueChanged<T>? valueChanged;
//   // final bool useBoolButton;

//   // String? get fieldLabel => config.inputDecoration?.labelText;

//   VarViewer<T> copyWith({
//     // InputDecoration? inputDecoration,
//     bool? isReadOnly,
//     String? tip,
//     Listenable? valueListenable,
//     ValueGetter<T>? valueGetter,
//     ValueGetter<bool>? valueErrorGetter,
//     ValueGetter<String>? valueStringGetter,
//     ValueSetter<T>? valueSetter,
//     Map<T, String>? stringMap,
//     num? valueMin,
//     num? valueMax,
//     ValueChanged<T>? sliderChanged,
//   }) {
//     return VarViewer<T>(
//       inputDecoration: inputDecoration ?? this.inputDecoration,
//       isReadOnly: isReadOnly ?? this.isReadOnly,
//       tip: tip ?? this.tip,
//       valueListenable: valueListenable ?? this.valueListenable,
//       valueGetter: valueGetter ?? this.valueGetter,
//       valueErrorGetter: valueErrorGetter ?? this.valueErrorGetter,
//       valueStringGetter: valueStringGetter ?? this.valueStringGetter,
//       valueSetter: valueSetter ?? this.valueSetter,
//       stringMap: stringMap ?? this.stringMap,
//       valueMin: valueMin ?? this.valueMin,
//       valueMax: valueMax ?? this.valueMax,
//       sliderChanged: sliderChanged ?? this.sliderChanged,
//     );
//   }
// }

// class VarViewerIm<T> extends VarViewer<T> {

//   @override
//   bool get isReadOnly => motVar.varKey.isReadOnly;
//   @override
//   Listenable get valueListenable => motVar;
//   @override
//   ValueGetter<T> get valueGetter => motVar.valueAs<T>;
//   @override
//   ValueGetter<String> get valueStringGetter => motVar.valueString<T>;
//   @override
//   ValueGetter<bool> get valueErrorGetter => () => motVar.statusIsError;
//   @override
//   ValueSetter<T> get valueSetter => motVar.valueWriter<T>();
//   @override
//   ValueChanged<T> get onChanged => motVar.updateByView<T>;
//   @override
//   Map<T, String> get stringMap => motVar.varKey.valueStringMap<T>();
//   @override
//   String get tip => motVar.varKey.tag.tip;
//   @override
//   num get valueMin => motVar.varKey.viewMin.toDouble();
//   @override
//   num get valueMax => motVar.varKey.viewMax.toDouble();
// }
