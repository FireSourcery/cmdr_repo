import 'package:flutter/material.dart';

import 'io_field.dart';

/// connected widget using same config

class IOFieldSlider<T extends num> extends StatelessWidget implements IOField<T> {
  const IOFieldSlider(this.config, {super.key});

  final IOFieldConfig<T> config;

  void onChanged(double value) => config.valueChanged?.call(value.to<T>());
  void onChangeEnd(double value) => config.valueSetter?.call(value.to<T>());

  Widget builder(BuildContext context, Widget? child) {
    final min = config.valueNumLimits!.min.toDouble();
    final max = config.valueNumLimits!.max.toDouble();
    final value = config.valueGetter()?.toDouble().clamp(min, max);
    if (value == null) return const Text('Error');

    return Slider.adaptive(label: config.idDecoration.labelText, min: min, max: max, value: value, onChanged: onChanged, onChangeEnd: onChangeEnd);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: config.valueListenable, builder: builder);
}

// Composites
// convenience for attaching the same config
class IOFieldWithSlider<T extends num> extends StatelessWidget {
  const IOFieldWithSlider(this.config, {this.breakWidth = 400, super.key});

  factory IOFieldWithSlider.of(IOFieldConfig config, {Key? key}) {
    assert(config.valueNumLimits != null);
    return switch (config) {
          IOFieldConfig<int>() => IOFieldWithSlider<int>(config),
          IOFieldConfig<double>() => IOFieldWithSlider<double>(config),
          IOFieldConfig<num>() => IOFieldWithSlider<num>(config),
          _ => throw TypeError(),
        }
        as IOFieldWithSlider<T>;
  }

  final IOFieldConfig<T> config;
  final int breakWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return (constraints.maxWidth > breakWidth)
            ? Row(
                children: [
                  Expanded(child: IOFieldText<T>.config(config)),
                  Expanded(flex: 2, child: IOFieldSlider<T>(config)),
                ],
              )
            : OverflowBar(children: [IOFieldText<T>.config(config), IOFieldSlider<T>(config)]);
      },
    );
  }
}
