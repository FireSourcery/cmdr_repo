import 'package:flutter/material.dart';

class BottomSheetButton extends StatefulWidget {
  const BottomSheetButton({
    required this.backgroundImage,
    this.shape,
    this.heightScale = .33,
    required this.child,
    this.iconOpen = const Icon(Icons.keyboard_arrow_up, size: 50),
    this.iconClose = const Icon(Icons.keyboard_arrow_down, size: 50),
    // this.iconInactive = const Icon(Icons.circle_outlined, size: 50),
    this.iconInactive,
    super.key,
  });

  final ImageProvider backgroundImage;
  final OutlinedBorder? shape;
  final Icon iconOpen;
  final Icon iconClose;
  final Icon? iconInactive;

  // final Color shadowClosed =  Colors.black;
  // final Color shadowOpen = Colors.black;
  // final double elevationOpen =  10;
  // final double elevationClosed =  10;
  final double heightScale;
  final Widget? child; // initial bottom sheet

  @override
  State<BottomSheetButton> createState() => BottomSheetButtonState();
}

/// Public. [selectedBottomSheet] can be set to a new widget to change the bottom sheet.
class BottomSheetButtonState extends State<BottomSheetButton> {
  late final double appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 137;
  late final BottomSheetThemeData theme = Theme.of(context).bottomSheetTheme;
  late final Color color = Theme.of(context).colorScheme.surface;

  late final ShapeBorder? shape = widget.shape ?? theme.shape ?? const BeveledRectangleBorder();

  // late final Color shadowClosed = theme.shadowColor ?? Colors.black;
  // late final Color shadowOpen = theme.shadowColor ?? Colors.black;
  // late final double elevationOpen = theme.elevation ?? 10;
  // late final double elevationClosed = theme.elevation ?? 10;

  late final FloatingActionButton fabOpen = FloatingActionButton(onPressed: expand, child: widget.iconOpen);
  late final FloatingActionButton fabClose = FloatingActionButton(onPressed: collapse, child: widget.iconClose); // null to hide
  late final FloatingActionButton fabNull = FloatingActionButton(onPressed: collapse, child: widget.iconInactive); // null to hide

  late PersistentBottomSheetController bottomSheetController;
  // mutable
  late Widget? fab = fabOpen;
  late Widget? selectedBottomSheet = widget.child;

  // Future<void> get closed => bottomSheetController.closed;

  /// call from Flutter top level showBottomSheet to maintain button consistency
  void onShow() {
    if (mounted) setState(() => fab = fabClose);
  }

  void onClosed() {
    if (mounted) setState(() => fab = fabOpen);
  }

  // close and detach, on closed will still run
  void onExit() {
    if (mounted) setState(() {});
    fab = fabNull ?? fabOpen;
    selectedBottomSheet = null;
  }

  Widget _bottomSheetBuilder(BuildContext context) => Padding(padding: EdgeInsets.only(top: (widget.iconClose.size ?? 0) / 2), child: selectedBottomSheet ?? widget.child);

  void expand([Widget? child]) {
    late final sheetHeight = MediaQuery.of(context).size.height * widget.heightScale + appBarHeight; // repeat in case of screen size change
    if (child != null) selectedBottomSheet = child;
    if (selectedBottomSheet == null) return;
    setState(() {
      fab = fabClose;
    });
    bottomSheetController = Scaffold.of(context).showBottomSheet(_bottomSheetBuilder, enableDrag: true, constraints: BoxConstraints.expand(height: sheetHeight));
    bottomSheetController.closed.whenComplete(onClosed); // on drag close
  }

  void collapse() {
    bottomSheetController.close();
    bottomSheetController.closed.whenComplete(onClosed);
  }

  void exit() {
    if (selectedBottomSheet == null) return;
    bottomSheetController.close();
    bottomSheetController.closed.whenComplete(onExit);
  }

  // Material? materialWrapOpen(Widget child) => Material(type: MaterialType.card, shadowColor: shadowOpen, elevation: elevationOpen, shape: shape, child: Center(child: child));
  // Material? materialWrapClose(Widget child) => Material(type: MaterialType.card, shadowColor: shadowClosed, elevation: elevationClosed, shape: shape, child: Center(child: child));
  Material materialWrap(Widget? child) =>
      Material(type: MaterialType.canvas, color: color, shadowColor: theme.shadowColor, elevation: theme.elevation ?? 10, shape: shape, child: Center(child: child));

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      height: appBarHeight,
      decoration: BoxDecoration(image: DecorationImage(image: widget.backgroundImage, fit: BoxFit.fill)),
      child: materialWrap(fab),
    );
  }
}

// late Color color1 = Theme.of(context).colorScheme.outline;
// late Color color2 = Theme.of(context).colorScheme.outlineVariant;
// late Color animatedColor = color1;
// late Timer _timer;

// Widget borderWrap(Widget child) {
//   return AnimatedContainer(
//     alignment: Alignment.bottomCenter,
//     duration: Duration(seconds: 1),
//     // decoration: ShapeDecoration(shape: widget.shape.copyWith(side: BorderSide(color: animatedColor))),
//     curve: Curves.linear,
//     color: animatedColor,
//     // onEnd: setColor,
//     child: child,
//   );
// }

// @override
// void initState() {
//   super.initState();
//   _timer = Timer.periodic(Duration(seconds: 4), (timer) => setColor());
// }

// void setColor() {
//   setState(() {
//     (animatedColor == color1) ? color2 : color1;
//     // if (animatedColor == color1) animatedColor = color2;
//     // if (animatedColor == color2) animatedColor = color1;
//   });
// }
