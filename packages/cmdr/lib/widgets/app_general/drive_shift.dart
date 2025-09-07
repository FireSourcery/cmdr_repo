// ignore_for_file: public_member_api_docs, sort_constructors_first
import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class DriveShift extends StatefulWidget {
  const DriveShift({super.key, this.onSelect, this.confirmSelected, this.initialSelect, required this.enumF, required this.enumN, required this.enumR, required this.enumP});

  final ValueSetter<Enum>? onSelect;
  // final ValueNotifier<Enum>? valueNotifier;
  final AsyncValueGetter<Enum?>? confirmSelected;
  final Enum? initialSelect;
  // directly return users type
  final Enum enumF;
  final Enum enumN;
  final Enum enumR;
  final Enum enumP;

  final Radius radius = const Radius.circular(10.0);
  final double size = 25;

  @override
  State<DriveShift> createState() => _DriveShiftState();
}

class _DriveShiftState extends State<DriveShift> {
  _DriveShiftState();

  late final Color errorColor = Theme.of(context).colorScheme.error;
  late final Color borderColor = Theme.of(context).colorScheme.outline;
  late final ButtonStyle buttonStyle = Theme.of(context).elevatedButtonTheme.style ?? const ButtonStyle();
  late final TextStyle? letterStyle = Theme.of(context).textTheme.displaySmall;

  // Theme buttonStyle/OutlineBorder does not contain shape with radius
  Radius get radius => widget.radius;
  late final BorderRadius borderRadiusSeed = BorderRadius.all(widget.radius);
  late final BeveledRectangleBorder shapeSeed = BeveledRectangleBorder(borderRadius: borderRadiusSeed);
  late final ButtonStyle styleSeed = buttonStyle.copyWith(
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 0)),
    minimumSize: const WidgetStatePropertyAll(Size(50, 50)),
    shape: WidgetStatePropertyAll(shapeSeed),
    backgroundColor: _ButtonBackgroundColor(borderColor, errorColor),
    side: _ButtonBorderSide(borderColor),
  );

  // BorderRadius.vertical(top: radius * 2, bottom: radius)
  // BorderRadius.vertical(top: radius, bottom: radius * 2)
  late final BorderRadius borderRadiusForward = borderRadiusSeed.copyWith(topLeft: borderRadiusSeed.topLeft * 2, topRight: borderRadiusSeed.topRight * 2);
  late final BorderRadius borderRadiusReverse = borderRadiusSeed.copyWith(bottomLeft: borderRadiusSeed.bottomLeft * 2, bottomRight: borderRadiusSeed.bottomRight * 2);
  late final ButtonStyle styleReverse = styleSeed.copyWith(shape: WidgetStatePropertyAll(shapeSeed.copyWith(borderRadius: borderRadiusReverse)));
  late final ButtonStyle styleForward = styleSeed.copyWith(shape: WidgetStatePropertyAll(shapeSeed.copyWith(borderRadius: borderRadiusForward)));

  late final BorderSide baseBorderSide = BorderSide(color: borderColor, width: 2, strokeAlign: BorderSide.strokeAlignInside);
  late final OutlinedBorder baseBorder = BeveledRectangleBorder(borderRadius: BorderRadius.all(radius * 2.5), side: baseBorderSide);

  late final WidgetStatesController controllerF = WidgetStatesController({if (widget.initialSelect == widget.enumF) WidgetState.selected});
  late final WidgetStatesController controllerN = WidgetStatesController({if (widget.initialSelect == widget.enumN) WidgetState.selected});
  late final WidgetStatesController controllerR = WidgetStatesController({if (widget.initialSelect == widget.enumR) WidgetState.selected});
  late final WidgetStatesController controllerP = WidgetStatesController({if (widget.initialSelect == widget.enumP) WidgetState.selected});

  // late DriveShiftSelect _selected = widget.initialSelect;

  Future<void> handleSelect(Enum select) async {
    widget.onSelect?.call(select);
    controllerF.update(WidgetState.selected, (select == widget.enumF));
    controllerN.update(WidgetState.selected, (select == widget.enumN));
    controllerR.update(WidgetState.selected, (select == widget.enumR));
    controllerP.update(WidgetState.selected, (select == widget.enumP));

    // handle returning null result as null, null function use the selected value directly
    if (widget.confirmSelected case AsyncValueGetter<Enum?> confirmed) {
      Enum? errorSelect = (await confirmed() == select) ? null : select;
      if (!mounted) return;
      controllerF.update(WidgetState.error, (errorSelect == widget.enumF));
      controllerN.update(WidgetState.error, (errorSelect == widget.enumN));
      controllerR.update(WidgetState.error, (errorSelect == widget.enumR));
      controllerP.update(WidgetState.error, (errorSelect == widget.enumP));
    }
  }

  // short hand wrapper
  ElevatedButton button(Enum id, String label, ButtonStyle style, WidgetStatesController controller) {
    return ElevatedButton(
      onPressed: () => handleSelect(id),
      style: style,
      statesController: controller,
      child: Text(label, textAlign: TextAlign.center, style: letterStyle),
    );
  }

  late final ElevatedButton forward = button(widget.enumF, "F", styleForward, controllerF);
  late final ElevatedButton neutral = button(widget.enumN, "N", styleSeed, controllerN);
  late final ElevatedButton reverse = button(widget.enumR, "R", styleReverse, controllerR);
  late final ElevatedButton park = button(widget.enumP, "P", styleSeed, controllerP);

  // if material3 == false
  // Widget wrapTheme(Widget child) => Theme(data: ThemeData(useMaterial3: true, colorSchemeSeed: borderColor, brightness: Brightness.dark), child: child);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: baseBorder,
      child: Container(
        padding: const EdgeInsets.all(15),
        height: 250,
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            park,
            const Divider(height: 0, color: Colors.transparent),
            forward,
            neutral,
            reverse,
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controllerF.dispose();
    controllerN.dispose();
    controllerR.dispose();
    controllerP.dispose();
    super.dispose();
  }
}

// enum DriveShiftSelect { forward, neutral, reverse, park }

class _ButtonBackgroundColor implements WidgetStateProperty<Color?> {
  const _ButtonBackgroundColor(this.baseColor, this.errorColor);

  final Color baseColor;
  final Color errorColor;

  @override
  Color? resolve(Set<WidgetState> states) {
    Color selectedColor = baseColor.withAlpha(100);
    Color unselectedColor = baseColor.withAlpha(25);

    if (states.contains(WidgetState.error)) return errorColor;
    if (states.contains(WidgetState.selected)) return selectedColor;
    return unselectedColor;
  }
}

// OutlinedBorder
// abstract class _ButtonBorder implements MaterialStateProperty<OutlinedBorder?> {
//   const _ButtonBorder();

//   @override
//   OutlinedBorder? resolve(Set<MaterialState> states);
// }

class _ButtonBorderSide implements WidgetStateProperty<BorderSide?> {
  const _ButtonBorderSide(this.borderColor);

  final Color borderColor;

  @override
  BorderSide? resolve(Set<WidgetState> states) {
    BorderSide borderSide1 = BorderSide(color: borderColor, width: 1, strokeAlign: BorderSide.strokeAlignOutside);
    BorderSide borderSide2 = BorderSide(color: borderColor, width: 2, strokeAlign: BorderSide.strokeAlignOutside);
    if (states.contains(WidgetState.selected) || states.contains(WidgetState.error)) return borderSide2;
    return borderSide1;
  }
}
