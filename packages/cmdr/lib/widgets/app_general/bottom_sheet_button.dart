import 'dart:async';

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
  final double heightScale;
  final Widget? child; // initial bottom sheet
  // final Color shadowClosed =  Colors.black;
  // final Color shadowOpen = Colors.black;
  // final double elevationOpen =  10;
  // final double elevationClosed =  10;

  @override
  State<BottomSheetButton> createState() => BottomSheetButtonState();
}

/// Public. [selectedBottomSheet] can be set to a new widget to change the bottom sheet.
class BottomSheetButtonState extends State<BottomSheetButton> {
  late final BottomSheetThemeData theme = Theme.of(context).bottomSheetTheme;
  late final Color color = Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).colorScheme.surface;
  late final double appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 137;
  late final ShapeBorder? shape = widget.shape ?? theme.shape ?? const BeveledRectangleBorder();
  // late final Color shadowClosed = theme.shadowColor ?? Colors.black;
  // late final Color shadowOpen = theme.shadowColor ?? Colors.black;
  // late final double elevationOpen = theme.elevation ?? 10;
  // late final double elevationClosed = theme.elevation ?? 10;

  late final FloatingActionButton fabOpen = FloatingActionButton(onPressed: expand, child: widget.iconOpen);
  late final FloatingActionButton fabClose = FloatingActionButton(onPressed: collapse, child: widget.iconClose);
  late final FloatingActionButton fabNull = FloatingActionButton(onPressed: null, child: widget.iconInactive);

  // mutable
  PersistentBottomSheetController? bottomSheetController;
  late Widget? selectedBottomSheet = widget.child;
  // Widget? fabActive  = fabOpen;

  Future<void> get closed async => await bottomSheetController?.closed;
  bool get isClosed => bottomSheetController == null;

  // fab = fabClose;
  void expand([Widget? child, double? height]) {
    late final sheetHeight = height ?? MediaQuery.of(context).size.height * widget.heightScale + appBarHeight; // repeat in case of screen size change
    if (child != null) selectedBottomSheet = child;
    if (selectedBottomSheet == null) return;
    bottomSheetController = Scaffold.of(context).showBottomSheet(_bottomSheetBuilder, enableDrag: true, constraints: BoxConstraints.expand(height: sheetHeight));
    bottomSheetController?.closed.whenComplete(_onClosed); // for drag close
    setState(() {});
    // setColor();
  }

  void collapse() => bottomSheetController?.close();

  /// call from global state
  void show([Widget? child, double? height]) => WidgetsBinding.instance.addPostFrameCallback((_) => expand(child, height));
  void set(Widget child) => setState(() => selectedBottomSheet = child);
  void exit() => WidgetsBinding.instance.addPostFrameCallback((_) => _exit());

  /// private
  Widget _bottomSheetBuilder(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: (widget.iconClose.size ?? 0) / 2),
    child: selectedBottomSheet ?? widget.child,
  );

  // fab = fabOpen
  void _onClosed() {
    if (mounted) setState(() => bottomSheetController = null);
  }

  /// close and detach. on closed will still run
  void _onExit() {
    if (mounted) setState(() => selectedBottomSheet = null);
  }

  void _exit() {
    if (bottomSheetController case PersistentBottomSheetController controller) {
      (controller..close()).closed.whenComplete(_onExit);
    } else {
      _onExit(); // Directly call if already closed to ensure state updates
    }
  }

  Widget? get _fab => (selectedBottomSheet == null) ? fabNull : (isClosed ? fabOpen : fabClose);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      height: appBarHeight,
      decoration: BoxDecoration(
        image: DecorationImage(image: widget.backgroundImage, fit: BoxFit.fill),
      ),
      child: _MaterialWrap(color: color, theme: theme, shape: shape, child: _fab),
    );
  }
}

class _MaterialWrap extends StatelessWidget {
  const _MaterialWrap({super.key, required this.color, required this.theme, required this.shape, required this.child});

  final Color color;
  final BottomSheetThemeData theme;
  final ShapeBorder? shape;
  final Widget? child;
  // Material? materialWrapOpen(Widget child) => Material(type: MaterialType.card, shadowColor: shadowOpen, elevation: elevationOpen, shape: shape, child: Center(child: child));
  // Material? materialWrapClose(Widget child) => Material(type: MaterialType.card, shadowColor: shadowClosed, elevation: elevationClosed, shape: shape, child: Center(child: child));

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.canvas,
      color: color,
      shadowColor: theme.shadowColor,
      elevation: theme.elevation ?? 10,
      shape: shape,
      child: Center(child: child),
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
