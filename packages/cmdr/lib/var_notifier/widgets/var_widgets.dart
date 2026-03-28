import 'package:struct_data/binary_format/quantity_format.dart';
import 'package:flutter/material.dart';

import '../var_notifier.dart';
import 'var_widget.dart';

/// End Widgets using VarNotifier
///
// Type-specific extensions — only visible with correct type
extension VarValueNumExt on VarValue<num> {
  ({num min, num max})? get numLimits {
    if (codec is NumFormat) return (codec as NumFormat?)?.valueRange;
    if (codec is BinaryQuantityCodec) return (codec as BinaryQuantityCodec).numLimits;
  }

  /// assert(V is num);
  // bool get isOverLimit => (numView > codec.numLimits!.max);
  // bool get isUnderLimit => (numView < codec.numLimits!.min);
}

extension VarValueIntExt on VarValue<int> {
  ({int min, int max})? get intLimits => (codec as IntFormat?)?.binaryRange;
}

extension VarValueEnumExt<E extends Enum> on VarValue<E> {
  List<E> get enumRange => (codec as EnumFormat<dynamic, E>).values;
  Enum get valueAsEnum => codec.decode(data);
}

extension VarValueBitsExt on VarValue<BitStruct> {
  List<BitField> get bitsKeys => (codec as BitStructFormat).fields;
  BitStruct get valueAsBitFields => codec.decode(data);
}

class VarSwitch extends StatelessWidget {
  const VarSwitch(this.varNotifier, {super.key});

  final VarNotifier<bool> varNotifier;

  Widget builder(BuildContext context, Widget? child) => Switch.adaptive(value: varNotifier.value, onChanged: varNotifier.updateByView);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: varNotifier, builder: builder);
  }
}

class VarSlider extends StatelessWidget {
  const VarSlider(this.varNotifier, {super.key, this.eventNotifier});

  final VarNotifier<num> varNotifier;
  final VarEventNotifier? eventNotifier;

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
class VarButton<V> extends StatelessWidget {
  const VarButton(this.varNotifier, {required this.writeValue, this.labelOverwrite, super.key});

  final VarNotifier<V> varNotifier;
  final V writeValue;
  final Widget? labelOverwrite;

  void onPressed() => varNotifier.updateByView(writeValue);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: labelOverwrite ?? Text(varNotifier.varKey.label));
  }
}
