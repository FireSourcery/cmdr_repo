// ignore_for_file: public_member_api_docs, sort_constructors_first
import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class const DriveShift({
  super.key,
  final AsyncValueSetter<Enum>? onSelect,
  final AsyncValueGetter<Enum?>? confirmSelected,

  /// The gear the device reports, rendered as selected. A request shows pending until [onSelect], then [confirmSelected], answers.
  required final ValueListenable<Enum?> actual,
  // directly return users type
  required final Enum enumF,
  required final Enum enumN,
  required final Enum enumR,
  required final Enum enumP,
}) extends StatefulWidget {
  // final ValueNotifier<Enum>? valueNotifier;
  final Radius radius = const Radius.circular(10.0);
  final double size = 25;

  @override
  State<DriveShift> createState() => _DriveShiftState();
}

class _DriveShiftState() extends State<DriveShift> {
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

  late final WidgetStatesController controllerF = WidgetStatesController();
  late final WidgetStatesController controllerN = WidgetStatesController();
  late final WidgetStatesController controllerR = WidgetStatesController();
  late final WidgetStatesController controllerP = WidgetStatesController();

  // late DriveShiftSelect _selected = widget.initialSelect;

  Enum? pending; // requested, until [DriveShift.onSelect], then [DriveShift.confirmSelected], answers

  void mark(WidgetState state, Enum? select) {
    controllerF.update(state, (select == widget.enumF));
    controllerN.update(state, (select == widget.enumN));
    controllerR.update(state, (select == widget.enumR));
    controllerP.update(state, (select == widget.enumP));
  }

  Future<void> handleSelect(Enum select) async {
    setState(() => pending = select);
    await widget.onSelect?.call(select);

    // handle returning null result as null, null function leaves the request unconfirmed
    if (widget.confirmSelected case AsyncValueGetter<Enum?> confirmed) {
      Enum? errorSelect = (await confirmed() == select) ? null : select;
      if (!mounted) return;
      mark(WidgetState.error, errorSelect);
    }
    if (mounted && pending == select) setState(() => pending = null);
  }

  // short hand wrapper
  ElevatedButton button(Enum id, String label, ButtonStyle style, WidgetStatesController controller) {
    return ElevatedButton(
      onPressed: () => handleSelect(id),
      style: style,
      statesController: controller,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(label, textAlign: TextAlign.center, style: letterStyle),
          if (id == pending) const CircularProgressIndicator(),
        ],
      ),
    );
  }

  ElevatedButton get forward => button(widget.enumF, "F", styleForward, controllerF);
  ElevatedButton get neutral => button(widget.enumN, "N", styleSeed, controllerN);
  ElevatedButton get reverse => button(widget.enumR, "R", styleReverse, controllerR);
  ElevatedButton get park => button(widget.enumP, "P", styleSeed, controllerP);

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
        child: ValueListenableBuilder(
          valueListenable: widget.actual,
          builder: (context, actual, child) {
            mark(WidgetState.selected, actual);
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                park,
                const Divider(height: 0, color: Colors.transparent),
                forward,
                neutral,
                reverse,
              ],
            );
          },
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

class const _ButtonBackgroundColor(final Color baseColor, final Color errorColor) implements WidgetStateProperty<Color?> {
  @override
  Color? resolve(Set<WidgetState> states) {
    Color selectedColor = baseColor.withAlpha(100);
    Color unselectedColor = baseColor.withAlpha(25);

    if (states.contains(WidgetState.selected)) return selectedColor;
    if (states.contains(WidgetState.error)) return errorColor;
    return unselectedColor;
  }
}

// OutlinedBorder
// abstract class _ButtonBorder implements MaterialStateProperty<OutlinedBorder?> {
//   const _ButtonBorder();

//   @override
//   OutlinedBorder? resolve(Set<MaterialState> states);
// }

class const _ButtonBorderSide(final Color borderColor) implements WidgetStateProperty<BorderSide?> {
  @override
  BorderSide? resolve(Set<WidgetState> states) {
    BorderSide borderSide1 = BorderSide(color: borderColor, width: 1, strokeAlign: BorderSide.strokeAlignOutside);
    BorderSide borderSide2 = BorderSide(color: borderColor, width: 2, strokeAlign: BorderSide.strokeAlignOutside);
    if (states.contains(WidgetState.selected) || states.contains(WidgetState.error)) return borderSide2;
    return borderSide1;
  }
}
