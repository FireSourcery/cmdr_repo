import 'package:flutter/material.dart';

import '../var_notifier.dart';
import 'var_widget.dart';

/// End Widgets using VarNotifier

/// A var button does not have a variable or view value.
/// This widget is only for convenience of mapping a VarKey to a button.
class VarButton extends StatelessWidget with VarNotifierViewer<int> {
  const VarButton(this.varNotifier, {this.writeValue = 1, this.labelOverwrite, super.key});

  @override
  final VarNotifier<dynamic> varNotifier;
  final int writeValue;
  final Widget? labelOverwrite;

  void onPressed() => varNotifier.updateByViewAs<int>(writeValue);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: labelOverwrite ?? Text(varNotifier.varKey.label),
    );
  }
}

class VarSwitch extends StatelessWidget with VarNotifierViewer<bool> {
  const VarSwitch(this.varNotifier, {super.key});

  @override
  final VarNotifier<dynamic> varNotifier;

  Widget builder(context, child) => Switch.adaptive(value: viewValue, onChanged: valueChanged);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: varNotifier, builder: builder);
  }
}

class VarSlider extends StatelessWidget with VarNotifierViewer<double> {
  const VarSlider(this.varNotifier, {super.key, this.eventNotifier});

  @override
  final VarNotifier<dynamic> varNotifier;
  final VarCacheNotifier? eventNotifier;

  void _submitWithCache(double value) => eventNotifier!.submitEntryAs<double>(varNotifier.varKey, value);

  Widget builder(BuildContext context, Widget? child) {
    // must be num defined if type is numeric
    final min = varNotifier.numLimits!.min.toDouble();
    final max = varNotifier.numLimits!.max.toDouble();
    // final onChangeEnd = (eventNotifier != null) ? (eventNotifier!.submitByViewAs<double>) : valueChanged;
    final onChangeEnd = (eventNotifier != null) ? _submitWithCache : valueChanged;

    return Slider.adaptive(
      // divisions: ((max - min) ~/ 1).clamp(2, 100),
      value: viewValue.clamp(min, max),
      onChanged: valueChanged,
      onChangeEnd: onChangeEnd,
      min: min,
      max: max,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!varNotifier.varKey.viewType.isSubtype<num>() || varNotifier.varKey.isReadOnly || (varNotifier.numLimits!.max <= varNotifier.numLimits!.min)) return const SizedBox.shrink();
    return ListenableBuilder(listenable: varNotifier, builder: builder);
  }
}
