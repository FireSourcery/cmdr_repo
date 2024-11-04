import 'package:flutter/material.dart';

import 'package:cmdr_common/basic_types.dart';

import '../../widgets/io_field.dart';
import '../var_notifier.dart';
import '../var_widget.dart';

////////////////////////////////////////////////////////////////////////////////
/// IO Field
////////////////////////////////////////////////////////////////////////////////
/// Interface without type parameter to be determined by Var
abstract interface class VarIOField extends StatelessWidget {
  factory VarIOField(VarNotifier varNotifier, {bool showLabel, bool isCompact, bool showPrefix, bool showSuffix, Key? key}) = _VarIOField;
  factory VarIOField.compact(VarNotifier varNotifier, {bool showLabel, bool showPrefix, bool showSuffix, Key? key}) = _VarIOField.compact;
  // factory VarIOField.withMenu(VarNotifier varNotifier, {bool showLabel, bool isCompact, bool showPrefix, bool showSuffix, Key? key}) =  ;
  // factory VarIOField.withSlider(VarNotifier varNotifier, {bool showLabel, bool isCompact, bool showPrefix, bool showSuffix, Key? key}) =  ;
}

/// map VarNotifier to IOFieldConfig and build
/// options mapped in constructor
class _VarIOField<V> extends StatelessWidget implements VarIOField {
  // accepts the type parameter passed to constructor
  const _VarIOField._(this.config, {super.key});

  // assigns type, discard T passed
  // main builder, maps additional options to config
  factory _VarIOField(VarNotifier<dynamic> varNotifier, {bool showLabel = true, bool showPrefix = true, bool showSuffix = true, bool isCompact = false, Key? key}) {
    // convenience for passing parameters
    _VarIOField<V1> local<V1>(VarNotifier localVar) {
      final config = VarIOFieldConfig<V1>(varNotifier, showLabel: showLabel, showPrefix: showPrefix, showSuffix: showSuffix, isCompact: isCompact);
      return _VarIOField<V1>._(config);
    }

    return varNotifier.varKey.viewType(<G>() => local<G>(varNotifier) as _VarIOField<V>);
  }

  factory _VarIOField.compact(VarNotifier varNotifier, {bool showLabel = false, bool showPrefix = false, bool showSuffix = false, Key? key}) =>
      _VarIOField(varNotifier, showLabel: showLabel, isCompact: true, showPrefix: showPrefix, showSuffix: showSuffix);

  final IOFieldConfig<V> config;

  @override
  Widget build(BuildContext context) => IOField<V>(config);
}

// option to pass var selection
// class VarIOFieldWithMenu extends StatelessWidget {
//   const VarIOFieldWithMenu({this.initialVarKey, this.varSelectController, super.key});
//   final VarKey? initialVarKey;
//   final VarSelectController? varSelectController;

//   @override
//   Widget build(BuildContext context) {
//     final realTimeController = VarRealTimeContext.of(context).controller;
//     final selectController = varSelectController ?? VarSelectController(realTimeController, initialVarKey: initialVarKey);
//     final menuSource = VarMenuSource.realTime(selectController: selectController);

//     return Row(
//       children: [
//         menuSource.toButton(),
//         const VerticalDivider(thickness: 0, color: Colors.transparent),
//         // config rebuilds on varNotifier select update
//         Expanded(child: menuSource.contain((_, __) => VarIOField(selectController.varNotifier, showLabel: true, isCompact: false, showPrefix: true, showSuffix: true))),
//       ],
//     );

//     // return ListTile(
//     //   // dense: true,
//     //   leading: menuSource.toButton(),
//     //   title: menuSource.contain((_, __) => _VarIOFieldBuilder.options(selectController.varNotifier, showLabel: true, isCompact: false, showPrefix: true, showSuffix: true)),
//     // );
//   }
// }

class VarIOFieldWithSlider<V> extends StatelessWidget {
  const VarIOFieldWithSlider(this.varKey, {super.key});
  final VarKey varKey;

  @override
  Widget build(BuildContext context) {
    return VarKeyBuilder.withType(varKey, <G>(varNotifier) => IOField<G>.withSlider(VarIOFieldConfig<G>(varNotifier)));
  }
}

class VarIOFieldConfig<V> implements IOFieldConfig<V> {
  VarIOFieldConfig(
    this.varNotifier, {
    this.labelAlignment = FloatingLabelAlignment.start,
    this.showLabel = true,
    this.showPrefix = true,
    this.showSuffix = true,
    this.isCompact = false,
  });

  final VarNotifier<dynamic> varNotifier;

  final FloatingLabelAlignment? labelAlignment;
  final bool showLabel;
  final bool showPrefix;
  final bool showSuffix;
  final bool? isCompact;

  // for brevity assign type then copyWith options, this way options do not have to be included in every typed constructor
  // applying options needs VarIOFieldConfig with constructor and fields, or use parent class copyWith
  // IOFieldConfig<T> buildWith({
  //   FloatingLabelAlignment? labelAlignment = FloatingLabelAlignment.start,
  //   bool showLabel = true,
  //   bool showPrefix = true,
  //   bool showSuffix = true,
  //   bool? isCompact = false,
  // }) {
  //   return copyWith(
  //     idDecoration: InputDecoration(
  //       labelText: (showLabel) ? idDecoration.labelText : null,
  //       prefixIcon: (showPrefix) ? idDecoration.prefixIcon : null,
  //       suffixText: (showSuffix) ? idDecoration.suffixText : null,
  //       floatingLabelAlignment: labelAlignment,
  //       isDense: isCompact,
  //     ),
  //   );
  // }

  // control over whether the callbacks from VarNotifier are passed
  @override
  InputDecoration get idDecoration {
    return InputDecoration(
      labelText: (showLabel) ? varNotifier.varKey.label : null,
      prefixIcon: (showPrefix) ? (!varNotifier.varKey.isReadOnly ? const Icon(Icons.input) : null) : null,
      suffixText: (showSuffix) ? varNotifier.varKey.suffix : null,
      isCollapsed: isCompact,
    );
  }

  @override
  bool get isReadOnly => varNotifier.varKey.isReadOnly;
  @override
  Listenable get valueListenable => varNotifier;
  @override
  ValueGetter<V> get valueGetter => varNotifier.valueAs<V>;
  @override
  ValueGetter<String> get valueStringGetter => varNotifier.valueStringAs<V>;
  @override
  ValueGetter<bool> get errorGetter => () => varNotifier.statusIsError;
  @override
  ValueSetter<V> get valueSetter => varNotifier.updateByViewAs<V>;
  @override
  ValueChanged<V> get sliderChanged => varNotifier.updateByViewAs<V>;
  @override
  String get tip => varNotifier.varKey.tip ?? '';
  @override
  ({num max, num min})? get valueNumLimits => varNotifier.varKey.valueNumLimits;
  @override
  List<V>? get valueEnumRange => varNotifier.varKey.valueEnumRange as List<V>?;
  @override
  Stringifier<V>? get valueStringifier => varNotifier.varKey.stringify<V>;

  @override
  IOFieldBoolStyle get boolStyle => IOFieldBoolStyle.latchingSwitch;
  @override
  bool get useSliderBorder => false;
  @override
  bool get useSwitchBorder => true;

  @override
  IOFieldConfig<V> copyWith(
      {InputDecoration? idDecoration,
      bool? isReadOnly,
      String? tip,
      Listenable? valueListenable,
      ValueGetter<V?>? valueGetter,
      ValueSetter<V>? valueSetter,
      ValueGetter<bool>? errorGetter,
      ValueGetter<String>? valueStringGetter,
      Stringifier<V>? valueStringifier,
      List<V>? valueEnumRange,
      ValueChanged<V>? sliderChanged,
      bool? useSliderBorder,
      bool? useSwitchBorder,
      IOFieldBoolStyle? boolStyle}) {
    throw UnimplementedError();
  }
}
