import 'package:flutter/material.dart';

import '../../type_ext/stringifier.dart';
import '../../widgets/io_field/io_field.dart';
import '../var_notifier.dart';
import 'var_menu.dart';

///
/// IO Field
///
/// Interface without type parameter to be determined by Var
abstract interface class VarIOField extends StatelessWidget {
  // assigns type, maps additional options to config
  factory VarIOField(
    VarNotifier<dynamic> varNotifier, {
    VarSingleController? controller,
    bool? readOnly,
    bool showLabel = true,
    bool showPrefix = true,
    bool showSuffix = true,
    bool isDense = false,
    Key? key,
  }) {
    // convenience for passing parameters
    _VarIOField<V> local<V>() {
      final config = VarIOFieldConfig<V>(
        varNotifier as VarNotifier<V>,
        controller: controller,
        readOnly: readOnly,
        showLabel: showLabel,
        showPrefix: showPrefix,
        showSuffix: showSuffix,
        isDense: isDense,
      );
      return _VarIOField<V>._(config);
    }

    return varNotifier.varKey.viewType.callWithType(local);

    // final config = VarIOFieldConfig(
    //   varNotifier,
    //   controller: controller,
    //   readOnly: readOnly,
    //   showLabel: showLabel,
    //   showPrefix: showPrefix,
    //   showSuffix: showSuffix,
    //   isDense: isDense,
    // );
    // return _VarIOField._(config);
  }

  factory VarIOField.compact(
    VarNotifier varNotifier, {
    VarSingleController? controller,
    bool? readOnly,
    bool showLabel = false,
    bool showPrefix = false,
    bool showSuffix = false,
    bool isDense = false,
    Key? key,
  }) {
    return VarIOField(varNotifier, readOnly: readOnly, showLabel: showLabel, isDense: isDense, showPrefix: showPrefix, showSuffix: showSuffix);
  }

  // const factory VarIOField.withConfig(IOFieldConfig config) = _VarIOField._;
}

/// map [VarNotifier] to [IOFieldConfig] and build
/// options mapped in constructor
class const _VarIOField<V>._(final IOFieldConfig<V> config, {super.key}) extends StatelessWidget implements VarIOField {
  // accepts the type parameter passed to constructor
  @override
  Widget build(BuildContext context) => IOField<V>(config);
}

/// with menu
///
/// decouple from Var? to
/// SelectableIOField
class const VarIOFieldWithMenu<T extends VarKey>({
  final T? initialVarKey,
  final VarCache? varCache,
  super.key,
  required final FlyweightMenuSource<T> menuSource,
  // IOFieldConfig ? config,
}) extends StatelessWidget {
  Widget _varWidgetBuilder(VarNotifier varNotifier) {
    return VarIOField(varNotifier, showLabel: true, isDense: false, showPrefix: true, showSuffix: true);
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

    return MenuAnchorBuilder(menuSource: menuSource, initialItem: initialVarKey, menuAnchorBuilder: _menuAnchorBuilder, keyBuilder: keyWidgetBuilder);
  }
}

///
///
///
class const VarIOFieldConfig<V>(
  final VarNotifier<V> varNotifier, { //alternatively split valuenotifier/valueUnion
  final VarSingleController? controller, // unused for now
  // alternatively handle in constructor
  final FloatingLabelAlignment? labelAlignment = FloatingLabelAlignment.start,
  final bool showLabel = true,
  final bool showPrefix = true,
  final bool showSuffix = true,
  final bool? isDense = false,
  final bool? readOnly,
}) implements IOFieldConfig<V> {
  factory VarIOFieldConfig.of(VarNotifier varNotifier) {
    VarIOFieldConfig<G> local<G>() {
      return VarIOFieldConfig<G>(varNotifier as VarNotifier<G>);
    }

    return varNotifier.varKey.viewType.callWithType(local) as VarIOFieldConfig<V>;
  }

  // InputDecoration? idDecoration

  // control over whether the parameters from VarNotifier are passed
  @override
  InputDecoration get idDecoration {
    return InputDecoration(
      labelText: (showLabel) ? varNotifier.varKey.label : null,
      prefixIcon: (showPrefix) ? (!isReadOnly ? const Icon(Icons.input) : null) : null,
      suffixText: (showSuffix) ? varNotifier.varKey.suffix : null,
      isDense: isDense,

      // floatingLabelAlignment: labelAlignment,
    );

    // return InputDecoration(
    //   labelText: varNotifier.varKey.label,
    //   prefixIcon: !isReadOnly ? const Icon(Icons.input) : null,
    //   suffixText: varNotifier.varKey.suffix,
    //   isDense: isDense,
    // ).copyWithHide(
    //   showLabel: showLabel,
    //   showPrefix: showPrefix,
    //   showSuffix: showSuffix,
    // );
  }

  @override
  bool get isReadOnly => readOnly ?? varNotifier.varKey.isReadOnly;
  @override
  Listenable get valueListenable => varNotifier;
  @override
  ValueGetter<V> get valueGetter => (() => varNotifier.value);
  @override
  ValueSetter<V> get valueSetter => varNotifier.updateByView;
  @override
  ValueGetter<bool> get errorGetter => (() => varNotifier.statusIsError);
  @override
  Stringifier<V> get valueStringifier => varNotifier.varKey.stringify<V>;
  @override
  ValueChanged<V> get valueChanged => varNotifier.updateByView;
  @override
  String get tip => varNotifier.varKey.tip ?? '';

  @override
  ({num max, num min})? get valueNumLimits {
    if (varNotifier is VarNotifier<num>) {
      if (varNotifier.codec case BinaryQuantityCodec c) return c.numLimits;
      if (varNotifier.codec case NumFormat n) return n.valueRange;
    }
    return null;
  }

  @override
  List<V>? get valueEnumRange {
    if (varNotifier is VarNotifier<Enum>) {
      if (varNotifier.codec case EnumFormat e) return e.values as List<V>;
    }
    return null;
  }

  @override
  IOFieldBoolStyle get boolStyle => IOFieldBoolStyle.latchingSwitch;

  @override
  bool get useSwitchBorder => true;

  @override
  IOFieldConfig<V> copyWith({
    bool? isReadOnly,
    // derived from varNotifier
    InputDecoration? idDecoration,
    String? tip,
    Listenable? valueListenable,
    ValueGetter<V>? valueGetter,
    ValueSetter<V>? valueSetter,
    ValueGetter<bool>? errorGetter,
    Stringifier<V>? valueStringifier,
    List<V>? valueEnumRange,
    ValueChanged<V>? sliderChanged,
    bool? useSliderBorder,
    bool? useSwitchBorder,
    IOFieldBoolStyle? boolStyle,
  }) {
    return VarIOFieldConfig<V>(
      varNotifier,
      controller: controller,
      labelAlignment: labelAlignment,
      showLabel: showLabel,
      showPrefix: showPrefix,
      showSuffix: showSuffix,
      isDense: isDense,
      readOnly: isReadOnly ?? readOnly,
    );
  }
}
