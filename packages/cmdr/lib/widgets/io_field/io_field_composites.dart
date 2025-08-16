import 'package:flutter/widgets.dart';

import 'io_field.dart';

////////////////////////////////////////////////////////////////////////////////
/// Composites
////////////////////////////////////////////////////////////////////////////////

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

  // Widget Function(BuildContext, Widget, Widget) builder;

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
