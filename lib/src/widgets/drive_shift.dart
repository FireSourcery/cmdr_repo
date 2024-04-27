import "package:flutter/material.dart";

typedef AsyncValueSetterWithStatus<T> = Future<bool> Function(T value);

class DriveShift extends StatefulWidget {
  const DriveShift({this.onSelect, this.onSelectWithConfirmation, this.initialSelect = DriveShiftSelect.park, super.key});

  final ValueSetter? onSelect;
  final AsyncValueSetterWithStatus<DriveShiftSelect>? onSelectWithConfirmation;
  // final AsyncValueSetter<DriveShiftSelect>? asyncOnSelect;
  // final AsyncValueGetter<bool>? onSelectConfirmation;
  final DriveShiftSelect initialSelect;
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
  // late final TextStyle letterStyle = GoogleFonts.audiowide(fontWeight: FontWeight.bold, fontSize: size);

  // Theme buttonStyle/OutlineBorder does not contain shape with radius
  Radius get radius => widget.radius;
  late final BorderRadius borderRadiusSeed = BorderRadius.all(widget.radius);
  late final BeveledRectangleBorder shapeSeed = BeveledRectangleBorder(borderRadius: borderRadiusSeed);
  late final ButtonStyle styleSeed = buttonStyle.copyWith(
    padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 0)),
    minimumSize: const MaterialStatePropertyAll(Size(50, 50)),
    shape: MaterialStatePropertyAll(shapeSeed),
    backgroundColor: _ButtonBackgroundColor(borderColor, errorColor),
    side: _ButtonBorderSide(borderColor),
  );

  // BorderRadius.vertical(top: radius * 2, bottom: radius)
  // BorderRadius.vertical(top: radius, bottom: radius * 2)
  late final BorderRadius borderRadiusForward = borderRadiusSeed.copyWith(topLeft: borderRadiusSeed.topLeft * 2, topRight: borderRadiusSeed.topRight * 2);
  late final BorderRadius borderRadiusReverse = borderRadiusSeed.copyWith(bottomLeft: borderRadiusSeed.bottomLeft * 2, bottomRight: borderRadiusSeed.bottomRight * 2);
  late final ButtonStyle styleReverse = styleSeed.copyWith(shape: MaterialStatePropertyAll(shapeSeed.copyWith(borderRadius: borderRadiusReverse)));
  late final ButtonStyle styleForward = styleSeed.copyWith(shape: MaterialStatePropertyAll(shapeSeed.copyWith(borderRadius: borderRadiusForward)));

  late final BorderSide baseBorderSide = BorderSide(color: borderColor, width: 2, strokeAlign: BorderSide.strokeAlignInside);
  late final OutlinedBorder baseBorder = BeveledRectangleBorder(borderRadius: BorderRadius.all(radius * 2.5), side: baseBorderSide);

  late final MaterialStatesController controllerF = MaterialStatesController({if (widget.initialSelect == DriveShiftSelect.forward) MaterialState.selected});
  late final MaterialStatesController controllerN = MaterialStatesController({if (widget.initialSelect == DriveShiftSelect.neutral) MaterialState.selected});
  late final MaterialStatesController controllerR = MaterialStatesController({if (widget.initialSelect == DriveShiftSelect.reverse) MaterialState.selected});
  late final MaterialStatesController controllerP = MaterialStatesController({if (widget.initialSelect == DriveShiftSelect.park) MaterialState.selected});

  Future<void> handleSelect(DriveShiftSelect select) async {
    DriveShiftSelect? errorSelect;
    if (await widget.onSelectWithConfirmation?.call(select).timeout(const Duration(milliseconds: 500), onTimeout: () => false) ?? true) {
      widget.onSelect?.call(select);
      if (mounted) {
        controllerF.update(MaterialState.selected, (select == DriveShiftSelect.forward));
        controllerN.update(MaterialState.selected, (select == DriveShiftSelect.neutral));
        controllerR.update(MaterialState.selected, (select == DriveShiftSelect.reverse));
        controllerP.update(MaterialState.selected, (select == DriveShiftSelect.park));
      }
    } else {
      errorSelect = select;
    }
    if (mounted) {
      controllerF.update(MaterialState.error, (errorSelect == DriveShiftSelect.forward));
      controllerN.update(MaterialState.error, (errorSelect == DriveShiftSelect.neutral));
      controllerR.update(MaterialState.error, (errorSelect == DriveShiftSelect.reverse));
      controllerP.update(MaterialState.error, (errorSelect == DriveShiftSelect.park));
    }
    // setState(() {});
  }

  // short hand wrapper
  ElevatedButton button(DriveShiftSelect id, String label, ButtonStyle style, MaterialStatesController controller) {
    return ElevatedButton(onPressed: () => handleSelect(id), style: style, statesController: controller, child: Text(label, textAlign: TextAlign.center, style: letterStyle));
  }

  late final ElevatedButton forward = button(DriveShiftSelect.forward, "F", styleForward, controllerF);
  late final ElevatedButton neutral = button(DriveShiftSelect.neutral, "N", styleSeed, controllerN);
  late final ElevatedButton reverse = button(DriveShiftSelect.reverse, "R", styleReverse, controllerR);
  late final ElevatedButton park = button(DriveShiftSelect.park, "P", styleSeed, controllerP);

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
          children: [park, const Divider(height: 0, color: Colors.transparent), forward, neutral, reverse],
        ),
      ),
    );
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

enum DriveShiftSelect { forward, neutral, reverse, park }

class _ButtonBackgroundColor implements MaterialStateProperty<Color?> {
  const _ButtonBackgroundColor(this.baseColor, this.errorColor);

  final Color baseColor;
  final Color errorColor;

  @override
  Color? resolve(Set<MaterialState> states) {
    Color selectedColor = baseColor.withAlpha(100);
    Color unselectedColor = baseColor.withAlpha(25);

    Color color = unselectedColor;
    if (states.contains(MaterialState.selected)) {
      color = selectedColor;
    } else if (states.contains(MaterialState.error)) {
      color = errorColor;
    } else {
      color = unselectedColor;
    }
    return color;
  }
}

// OutlinedBorder
// abstract class _ButtonBorder implements MaterialStateProperty<OutlinedBorder?> {
//   const _ButtonBorder();

//   @override
//   OutlinedBorder? resolve(Set<MaterialState> states);
// }

class _ButtonBorderSide implements MaterialStateProperty<BorderSide?> {
  const _ButtonBorderSide(this.borderColor);

  final Color borderColor;

  @override
  BorderSide? resolve(Set<MaterialState> states) {
    BorderSide borderSide1 = BorderSide(color: borderColor, width: 1, strokeAlign: BorderSide.strokeAlignOutside);
    BorderSide borderSide2 = BorderSide(color: borderColor, width: 2, strokeAlign: BorderSide.strokeAlignOutside);
    BorderSide border = borderSide1;
    if (states.contains(MaterialState.selected) || states.contains(MaterialState.error)) border = borderSide2;
    return border;
  }
}

// extension MaterialStateSet on Set<MaterialState> {
//   bool get isHovered => contains(MaterialState.hovered);
//   bool get isFocused => contains(MaterialState.focused);
//   bool get isPressed => contains(MaterialState.pressed);
// }

// ElevatedButton button(DriveShiftSelect direction, String label, ButtonStyle style) {
//   final isSelect = (driveSelect == direction);
//   final isErrorSelect = (errorSelect == direction);
//   final color = isSelect ? (selectedColor) : (isErrorSelect ? errorColor : unselectedColor);
//   final borderSide = (isSelect || isErrorSelect) ? borderSide2 : borderSide1;
//   return ElevatedButton(
//     onPressed: () => handleSelect(direction),
//     style: style.copyWith(side: MaterialStatePropertyAll(borderSide), backgroundColor: MaterialStatePropertyAll(color)),
//     child: Text(label, textAlign: TextAlign.center, style: widget.letterStyle),
//   );
// }
