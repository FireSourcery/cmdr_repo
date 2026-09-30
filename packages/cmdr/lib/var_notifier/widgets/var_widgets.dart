import 'package:flutter/material.dart';

import '../var_notifier.dart';

export 'var_io_field.dart';
export 'var_input_dialog.dart';
export 'var_widget.dart';

class const VarSwitch(final VarNotifier<bool> varNotifier, {super.key}) extends StatelessWidget {
  Widget builder(BuildContext context, Widget? child) => Switch.adaptive(value: varNotifier.value, onChanged: varNotifier.updateByView);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: varNotifier, builder: builder);
  }
}

class const VarSlider(final VarNotifier<num> varNotifier, {super.key}) extends StatelessWidget {
  Widget builder(BuildContext context, Widget? child) {
    // must be num defined if type is numeric
    final min = varNotifier.numLimits!.min.toDouble();
    final max = varNotifier.numLimits!.max.toDouble();
    // final onChangeEnd = (eventNotifier != null) ? (eventNotifier!.submitByViewAs<double>) : valueChanged;
    // final onChangeEnd = (eventNotifier != null) ? _submitWithCache : valueChanged;

    return Slider.adaptive(
      // divisions: ((max - min) ~/ 1).clamp(2, 100),
      value: varNotifier.value.toDouble(),
      onChanged: varNotifier.updateByView,
      onChangeEnd: varNotifier.updateByView,
      min: min,
      max: max,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
    if (!varNotifier.varKey.viewType.isSubtype<num>()) return const SizedBox.shrink();
    if (!varNotifier.varKey.viewType.isSubtype<num>() || varNotifier.varKey.isReadOnly || (varNotifier.numLimits!.max <= varNotifier.numLimits!.min)) return const SizedBox.shrink();
    return ListenableBuilder(listenable: varNotifier, builder: builder);
  }
}

/// A var button does not have a variable or view value.
/// This widget is only for convenience of mapping a VarKey to a button.
///
class const VarButton<V>(final VarNotifier<V> varNotifier, {required final V writeValue, final Widget? labelOverwrite, super.key}) extends StatelessWidget {
  void onPressed() => varNotifier.updateByView(writeValue);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: labelOverwrite ?? Text(varNotifier.varKey.label));
  }
}
