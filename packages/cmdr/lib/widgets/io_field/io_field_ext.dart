import 'package:flutter/material.dart';

import 'io_field.dart';

/// Convert to a specific num subtype [R] (int/double/num). [IOFieldSlider] works in double and
/// converts to its value type. [R] is non-nullable here ([IOFieldSlider] is `<T extends num>`),
/// so the plain type switch is sufficient.
extension IOFieldNumTo on num {
  R to<R>() =>
      switch (R) {
            const (int) => toInt(),
            const (double) => toDouble(),
            const (num) => this,
            _ => throw TypeError(),
          }
          as R;
}

/// connected widget using same config

class const IOFieldSlider<T extends num>(final IOFieldConfig<T> config, {super.key}) extends StatelessWidget implements IOField<T> {
  void onChanged(double value) => config.valueChanged?.call(value.to<T>());
  void onChangeEnd(double value) => config.valueSetter?.call(value.to<T>());

  Widget builder(BuildContext context, Widget? child) {
    final min = config.valueNumLimits!.min.toDouble();
    final max = config.valueNumLimits!.max.toDouble();
    final value = config.valueGetter().toDouble().clamp(min, max);

    return Slider.adaptive(label: config.idDecoration.labelText, min: min, max: max, value: value, onChanged: onChanged, onChangeEnd: onChangeEnd);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: config.valueListenable, builder: builder);
}

