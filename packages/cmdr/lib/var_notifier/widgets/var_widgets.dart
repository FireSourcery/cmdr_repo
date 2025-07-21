import 'package:flutter/material.dart';

import '../var_notifier.dart';
import 'var_widget.dart';

/// End Widgets using VarNotifier

class VarSwitch extends StatelessWidget {
  const VarSwitch(this.varNotifier, {super.key});

  final VarNotifier<dynamic> varNotifier;

  Widget builder(BuildContext context, Widget? child) => Switch.adaptive(value: varNotifier.valueAs<bool>(), onChanged: varNotifier.updateByViewAs<bool>);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: varNotifier, builder: builder);
  }
}

class VarSlider extends StatelessWidget {
  const VarSlider(this.varNotifier, {super.key, this.eventNotifier});

  final VarNotifier<dynamic> varNotifier;
  final VarEventNotifier? eventNotifier;

  Widget builder(BuildContext context, Widget? child) {
    // must be num defined if type is numeric
    final min = varNotifier.numLimits!.min.toDouble();
    final max = varNotifier.numLimits!.max.toDouble();
    // final onChangeEnd = (eventNotifier != null) ? (eventNotifier!.submitByViewAs<double>) : valueChanged;
    // final onChangeEnd = (eventNotifier != null) ? _submitWithCache : valueChanged;
    final onChangeEnd = varNotifier.updateByViewAs<double>;

    return Slider.adaptive(
      // divisions: ((max - min) ~/ 1).clamp(2, 100),
      value: varNotifier.valueAs<double>().clamp(min, max),
      onChanged: varNotifier.updateByViewAs<double>,
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

/// A var button does not have a variable or view value.
/// This widget is only for convenience of mapping a VarKey to a button.
class VarButton extends StatelessWidget {
  const VarButton(this.varNotifier, {this.writeValue = 1, this.labelOverwrite, super.key});

  final VarNotifier<dynamic> varNotifier;
  final int writeValue;
  final Widget? labelOverwrite;

  void onPressed() => varNotifier.updateByViewAs<int>(writeValue);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: labelOverwrite ?? Text(varNotifier.varKey.label));
  }
}
