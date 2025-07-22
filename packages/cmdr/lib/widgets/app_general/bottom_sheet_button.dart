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
  late final Color color = Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).colorScheme.surface;

  late final ShapeBorder? shape = widget.shape ?? theme.shape ?? const BeveledRectangleBorder();

  // late final Color shadowClosed = theme.shadowColor ?? Colors.black;
  // late final Color shadowOpen = theme.shadowColor ?? Colors.black;
  // late final double elevationOpen = theme.elevation ?? 10;
  // late final double elevationClosed = theme.elevation ?? 10;

  late final FloatingActionButton fabOpen = FloatingActionButton(onPressed: expand, child: widget.iconOpen);
  late final FloatingActionButton fabClose = FloatingActionButton(onPressed: collapse, child: widget.iconClose); // null to hide
  late final FloatingActionButton fabNull = FloatingActionButton(onPressed: _fabNullPress, child: widget.iconInactive); // null to hide

  PersistentBottomSheetController? bottomSheetController;
  // mutable
  late Widget? selectedBottomSheet = widget.child;
  // late Widget? fab = fabOpen;

  bool get isClosed => bottomSheetController == null;

  Widget? get fab {
    if (selectedBottomSheet == null) return fabNull;
    return isClosed ? fabOpen : fabClose;
  }

  /// call from Flutter top level showBottomSheet to maintain button consistency
  // void onShow() {
  //   if (mounted) setState(() => fab = fabClose);
  // }

  void _fabNullPress() {}

  Widget _bottomSheetBuilder(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: (widget.iconClose.size ?? 0) / 2),
    child: selectedBottomSheet ?? widget.child,
  );

  void _onClosed() {
    // if (mounted) setState(() => fab = fabOpen);
    if (mounted) {
      setState(() {
        bottomSheetController = null;
      });
    }
  }

  void expand([Widget? child]) {
    late final sheetHeight = MediaQuery.of(context).size.height * widget.heightScale + appBarHeight; // repeat in case of screen size change
    if (child != null) selectedBottomSheet = child;
    if (selectedBottomSheet == null) return;
    // setState(() {
    //   fab = fabClose;
    // });
    setState(() {});
    bottomSheetController = Scaffold.of(context).showBottomSheet(_bottomSheetBuilder, enableDrag: true, constraints: BoxConstraints.expand(height: sheetHeight));
    bottomSheetController?.closed.whenComplete(_onClosed); // for drag close
  }

  void collapse() {
    bottomSheetController?.close();
    bottomSheetController?.closed.whenComplete(_onClosed);
  }

  /// call from global state
  void _show([Widget? child]) {
    // if (child != null) selectedBottomSheet = child;
    expand(child);
    // bottomSheetController?.closed.whenComplete(_onExit);
  }

  // close and detach, on closed will still run
  void _onExit() {
    if (mounted) {
      setState(() {
        // fab = fabNull ?? fabOpen;
        bottomSheetController = null;
        selectedBottomSheet = null;
      });
    }
  }

  void _exit() {
    bottomSheetController?.close();
    bottomSheetController?.closed.whenComplete(_onExit);
  }

  void show([Widget? child]) => WidgetsBinding.instance.addPostFrameCallback((_) => _show(child));

  void exit() => WidgetsBinding.instance.addPostFrameCallback((_) => _exit());

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      height: appBarHeight,
      decoration: BoxDecoration(
        image: DecorationImage(image: widget.backgroundImage, fit: BoxFit.fill),
      ),
      child: _MaterialWrap(color: color, theme: theme, shape: shape, child: fab),
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
