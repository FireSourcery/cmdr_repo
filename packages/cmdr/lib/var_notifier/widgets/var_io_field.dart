import 'package:flutter/material.dart';

import 'package:type_ext/basic_types.dart';
import 'package:cmdr/var_notifier/widgets/var_menu.dart';

import '../../widgets/flyweight_menu/flyweight_menu.dart';
import '../../widgets/flyweight_menu/flyweight_menu_widgets.dart';
import '../../widgets/io_field/io_field.dart';
import '../var_notifier.dart';
import 'var_widget.dart';
import 'var_input_dialog.dart';

////////////////////////////////////////////////////////////////////////////////
/// IO Field
////////////////////////////////////////////////////////////////////////////////
/// Interface without type parameter to be determined by Var
abstract interface class VarIOField extends StatelessWidget {
  // assigns type, maps additional options to config
  factory VarIOField(
    VarNotifier<dynamic> varNotifier, {
    VarEventNotifier? eventNotifier,
    VarSingleController? controller,
    // bool? readOnly,
    bool showLabel = true,
    bool showPrefix = true,
    bool showSuffix = true,
    bool isDense = false,
    Key? key,
  }) {
    // convenience for passing parameters
    _VarIOField<V> local<V>() {
      final config = VarIOFieldConfig<V>(
        varNotifier,
        eventNotifier: eventNotifier,
        controller: controller,
        showLabel: showLabel,
        showPrefix: showPrefix,
        showSuffix: showSuffix,
        isDense: isDense,
      );
      return _VarIOField<V>._(config);
    }

    return varNotifier.varKey.viewType.callWithType(local);
  }

  factory VarIOField.compact(
    VarNotifier varNotifier, {
    VarEventNotifier? eventNotifier,
    VarSingleController? controller,
    bool showLabel = false,
    bool showPrefix = false,
    bool showSuffix = false,
    bool isDense = false,
    Key? key,
  }) {
    return VarIOField(
      varNotifier,
      eventNotifier: eventNotifier,
      showLabel: showLabel,
      isDense: isDense,
      showPrefix: showPrefix,
      showSuffix: showSuffix,
    );
  }

  // factory VarIOField.withMenu(VarNotifier varNotifier, {bool showLabel, bool isDense, bool showPrefix, bool showSuffix, Key? key}) =  ;
  // factory VarIOField.withSlider(VarNotifier varNotifier, {bool showLabel, bool isDense, bool showPrefix, bool showSuffix, Key? key}) =  ;
}

/// map [VarNotifier] to [IOFieldConfig] and build
/// options mapped in constructor
class _VarIOField<V> extends StatelessWidget implements VarIOField {
  // accepts the type parameter passed to constructor
  const _VarIOField._(this.config, {super.key});

  final IOFieldConfig<V> config;

  @override
  Widget build(BuildContext context) => IOField<V>(config);
}

/// with menu
///
/// decouple from Var? to
/// SelectableIOField
///
///
class VarIOFieldWithMenu<T extends VarKey> extends StatelessWidget {
  const VarIOFieldWithMenu({this.initialVarKey, this.varCache, this.eventNotifier, super.key, required this.menuSource});

  final FlyweightMenuSource<T> menuSource;
  final T? initialVarKey;
  final VarCache? varCache;
  final VarEventNotifier? eventNotifier;

  Widget _varWidgetBuilder(VarNotifier varNotifier) {
    return VarIOField(varNotifier, eventNotifier: eventNotifier, showLabel: true, isDense: false, showPrefix: true, showSuffix: true);
  }

  Widget _menuAnchorBuilder(BuildContext context, FlyweightMenu<T> menu, Widget keyWidget) {
    return Row(
      children: [
        FlyweightMenuButton<T>(menu: menu),
        const VerticalDivider(thickness: 0, color: Colors.transparent),
        // config rebuilds on varNotifier select update
        Expanded(child: keyWidget),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ValueWidgetBuilder<T> keyWidgetBuilder = VarKeyWidgetBuilder(builder: _varWidgetBuilder, varCache: varCache).asValueWidgetBuilder;

    return MenuAnchorBuilder(
      menuSource: menuSource,
      initialItem: initialVarKey,
      menuAnchorBuilder: _menuAnchorBuilder,
      keyBuilder: keyWidgetBuilder,
    );
  }
}

/// with
///
///
// class VarIOFieldWithSlider<V> extends StatelessWidget implements VarIOField {
//   const VarIOFieldWithSlider(this.varKey, {super.key});
//   final VarKey varKey;

//   @override
//   Widget build(BuildContext context) {
//     return VarKeyContextBuilderWithType(varKey, <G>(varNotifier) => IOField<G>.withSlider(VarIOFieldConfig<G>(varNotifier)));

//     //     return LayoutBuilder(
//     //   builder: (context, constraints) {
//     //     return (constraints.maxWidth > breakWidth) ? Row(children: [Expanded(child: ioField), Expanded(flex: 2, child: slider)]) : OverflowBar(children: [ioField, slider]);
//     //   },
//     // );
//   }
// }

///
///
///
class VarIOFieldConfig<V> implements IOFieldConfig<V> {
  const VarIOFieldConfig(
    this.varNotifier, {
    this.eventNotifier,
    this.controller,
    //disableConversion = false,
    this.labelAlignment = FloatingLabelAlignment.start,
    this.showLabel = true,
    this.showPrefix = true,
    this.showSuffix = true,
    this.isDense = false,
    //readonly
  });

  final VarNotifier<dynamic> varNotifier; //should this be cast here?
  final VarEventNotifier? eventNotifier;
  final VarSingleController? controller;

  // alternatively handle in constructor
  final FloatingLabelAlignment? labelAlignment;
  final bool showLabel;
  final bool showPrefix;
  final bool showSuffix;
  final bool? isDense;

  // control over whether the parameters from VarNotifier are passed
  @override
  InputDecoration get idDecoration {
    return InputDecoration(
      labelText: (showLabel) ? varNotifier.varKey.label : null,
      prefixIcon: (showPrefix) ? (!varNotifier.varKey.isReadOnly ? const Icon(Icons.input) : null) : null,
      suffixText: (showSuffix) ? varNotifier.varKey.suffix : null,
      isDense: isDense,
    );

    // return InputDecoration(
    //   labelText: varNotifier.varKey.label,
    //   prefixIcon: !varNotifier.varKey.isReadOnly ? const Icon(Icons.input) : null,
    //   suffixText: varNotifier.varKey.suffix,
    //   isDense: isDense,
    // ).copyWithHide(
    //   showLabel: showLabel,
    //   showPrefix: showPrefix,
    //   showSuffix: showSuffix,
    // );
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
  ValueSetter<V> get valueSetter => (eventNotifier != null) ? eventNotifier!.submitByViewAs<V> : varNotifier.updateByViewAs<V>;

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
  IOFieldConfig<V> copyWith({
    InputDecoration? idDecoration,
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
    IOFieldBoolStyle? boolStyle,
  }) {
    throw UnimplementedError();
  }
}
