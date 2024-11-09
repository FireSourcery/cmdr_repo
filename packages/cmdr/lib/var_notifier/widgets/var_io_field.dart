import 'package:cmdr/var_notifier/widgets/var_menu.dart';
import 'package:flutter/material.dart';

import 'package:cmdr_common/basic_types.dart';

import '../../widgets/flyweight_menu/flyweight_menu.dart';
import '../../widgets/flyweight_menu/flyweight_menu_widgets.dart';
import '../../widgets/io_field.dart';
import '../var_context.dart';
import '../var_notifier.dart';
import 'var_widget.dart';
import 'var_dialog_anchor.dart';

////////////////////////////////////////////////////////////////////////////////
/// IO Field
////////////////////////////////////////////////////////////////////////////////
/// Interface without type parameter to be determined by Var
abstract interface class VarIOField extends StatelessWidget {
  // assigns type, maps additional options to config
  factory VarIOField(
    VarNotifier<dynamic> varNotifier, {
    VarEventController? eventController,
    bool showLabel = true,
    bool showPrefix = true,
    bool showSuffix = true,
    bool isDense = false,
    Key? key,
  }) {
    // convenience for passing parameters
    _VarIOField<V> local<V>() {
      final config = VarIOFieldConfig<V>(varNotifier, eventController: eventController, showLabel: showLabel, showPrefix: showPrefix, showSuffix: showSuffix, isDense: isDense);
      return _VarIOField<V>._(config);
    }

    return varNotifier.varKey.viewType(local);
  }

  factory VarIOField.compact(
    VarNotifier varNotifier, {
    VarEventController? eventController,
    bool showLabel = false,
    bool showPrefix = false,
    bool showSuffix = false,
    bool isDense = false,
    Key? key,
  }) {
    return VarIOField(varNotifier, eventController: eventController, showLabel: showLabel, isDense: isDense, showPrefix: showPrefix, showSuffix: showSuffix);
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

class VarIOFieldWithMenu<T extends VarKey> extends StatelessWidget {
  const VarIOFieldWithMenu({this.initialVarKey, required this.varEventController, super.key, required this.menuSource});

  final FlyweightMenuSource<T> menuSource;
  final T? initialVarKey;
  final VarEventController? varEventController;

  Widget buildVar(VarNotifier varNotifier) {
    return VarIOField(varNotifier, eventController: varEventController, showLabel: true, isDense: false, showPrefix: true, showSuffix: true);
  }

  Widget buildByContext(BuildContext context, T value, Widget? child) {
    return VarKeyBuilder(value, buildVar);
  }

  Widget buildByController(BuildContext context, T value, Widget? child) {
    return VarBuilder(varEventController!.varCache.allocate(value), buildVar); // builder optionally includes the same eventController
  }

  @override
  Widget build(BuildContext context) {
    final menu = menuSource.create(); // todo with dispose
    late final ValueWidgetBuilder<T> effectiveBuilder = (varEventController != null) ? buildByController : buildByContext;
    // final widget = FlyweightMenuListenableBuilder(menu: menu, builder: buildKey);

    return Row(
      children: [
        VarMenuButton<T>(menu: menu),
        const VerticalDivider(thickness: 0, color: Colors.transparent),
        // config rebuilds on varNotifier select update
        Expanded(child: FlyweightMenuListenableBuilder<T>(menu: menu, builder: buildByContext)),
      ],
    );

    // return ListTile(
    //   // dense: true,
    //   leading: menuSource.toButton(),
    //   title: menuSource.contain((_, __) => _VarIOFieldBuilder.options(selectController.varNotifier, showLabel: true, isDense: false, showPrefix: true, showSuffix: true)),
    // );
  }
}

class VarIOFieldWithSlider<V> extends StatelessWidget implements VarIOField {
  const VarIOFieldWithSlider(this.varKey, {super.key});
  final VarKey varKey;

  @override
  Widget build(BuildContext context) {
    return VarKeyBuilder.typed(varKey, <G>(varNotifier) => IOField<G>.withSlider(VarIOFieldConfig<G>(varNotifier)));
  }
}

class VarIOFieldConfig<V> implements IOFieldConfig<V> {
  const VarIOFieldConfig(
    this.varNotifier, {
    this.eventController,
    this.labelAlignment = FloatingLabelAlignment.start,
    this.showLabel = true,
    this.showPrefix = true,
    this.showSuffix = true,
    this.isDense = false,
  });

  final VarNotifier<dynamic> varNotifier; //should this be cast here?
  final VarEventController? eventController;

  // alternatively handle in constructor
  // VarIOFieldConfig._(this.varNotifier);
  final FloatingLabelAlignment? labelAlignment;
  final bool showLabel;
  final bool showPrefix;
  final bool showSuffix;
  final bool? isDense;

  // for simplicity assign type then copyWith options, this way options do not have to be included in every typed constructor
  // applying options needs VarIOFieldConfig with constructor and fields, or use parent class copyWith
  // IOFieldConfig<T> buildWith({
  //   FloatingLabelAlignment? labelAlignment = FloatingLabelAlignment.start,
  //   bool showLabel = true,
  //   bool showPrefix = true,
  //   bool showSuffix = true,
  //   bool? isDense = false,
  // }) {
  //   return copyWith(
  //     idDecoration: InputDecoration(
  //       labelText: (showLabel) ? idDecoration.labelText : null,
  //       prefixIcon: (showPrefix) ? idDecoration.prefixIcon : null,
  //       suffixText: (showSuffix) ? idDecoration.suffixText : null,
  //       floatingLabelAlignment: labelAlignment,
  //       isDense: isDense,
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
      isDense: isDense,
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
  ValueSetter<V> get valueSetter => (eventController != null) ? eventController!.submitByViewAs<V> : varNotifier.updateByViewAs<V>;
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
