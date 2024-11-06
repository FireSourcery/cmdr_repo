import 'package:flutter/material.dart';

import '../var_notifier.dart';
import '../var_widget.dart';

/// End Widgets using VarNotifier

/// A var button does not have a variable or view value.
/// This widget is only for convenience of mapping a VarKey to a button.
class VarButton extends StatelessWidget with VarNotifierViewer<int> {
  const VarButton(this.varNotifier, {this.writeValue = 1, this.labelOverwrite, super.key});

  @override
  final VarNotifier<dynamic> varNotifier;
  final String? labelOverwrite;
  final int writeValue;

  void onPressed() => varNotifier.updateByView(writeValue);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(labelOverwrite ?? varNotifier.varKey.label),
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
  const VarSlider(this.varNotifier, {super.key});

  final VarNotifier<dynamic> varNotifier;

  Widget builder(BuildContext context, Widget? child) {
    // must be defined if type is numeric
    final min = varNotifier.viewMin!.toDouble();
    final max = varNotifier.viewMax!.toDouble();

    return Slider.adaptive(
      // label: varNotifier.varKey.label,
      // divisions: varNotifier.varKey.tag.unitViewMax - min ~/ 1,
      value: viewValue.clamp(min, max),
      onChanged: valueChanged,
      onChangeEnd: valueChanged,
      min: min,
      max: max,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!varNotifier.varKey.viewType.isSubtype<num>() || varNotifier.varKey.isReadOnly) return const SizedBox.shrink();
    return ListenableBuilder(listenable: varNotifier, builder: builder);
  }
}
// only when widget directly depends on notifer
// class VarListenablBuilder extends ListenableBuilder {
//   final VarNotifier varNotifier;
//   final Widget Function(VarNotifier) varBuilder;

//   VarBuilder({super.key, required this.varNotifier, required this.varBuilder, super.child})
//       : super(
//           listenable: varNotifier,
//           builder: (context, child) => varBuilder(varNotifier),
//         );
// }