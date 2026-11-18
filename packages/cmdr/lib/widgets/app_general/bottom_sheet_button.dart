import 'dart:async';

import 'package:flutter/material.dart';

class const BottomSheetButton({
  final ImageProvider? backgroundImage,
  final Widget? backdrop, // painted over the bar surface and its border, under the button; taps pass through
  final OutlinedBorder? shape,
  final double heightScale = .33, // default
  required final Widget? child, // initial and default bottom sheet
  final Icon iconOpen = const Icon(Icons.keyboard_arrow_up, size: 50),
  final Icon iconClose = const Icon(Icons.keyboard_arrow_down, size: 50),
  // this.iconInactive = const Icon(Icons.circle_outlined, size: 50),
  final Icon? iconInactive,
  super.key,
}) extends StatefulWidget {
  // final Color shadowClosed =  Colors.black;
  // final Color shadowOpen = Colors.black;
  // final double elevationOpen =  10;
  // final double elevationClosed =  10;

  @override
  State<BottomSheetButton> createState() => BottomSheetButtonState();
}

/// Public. [selectedBottomSheet] can be set to a new widget to change the bottom sheet.
class BottomSheetButtonState() extends State<BottomSheetButton> {
  late final BottomSheetThemeData theme = Theme.of(context).bottomSheetTheme;
  late final Color color = Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).colorScheme.surface;
  late final double buttonBarHeight = Scaffold.of(context).appBarMaxHeight ?? 137;
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
  late double selectedHeight = MediaQuery.of(context).size.height * widget.heightScale;
  // Widget? fabActive  = fabOpen;

  Future<void> get closed async => await bottomSheetController?.closed;
  bool get isClosed => bottomSheetController == null;

  // fab = fabClose;
  void expand([Widget? child, double? height]) {
    late final sheetHeight = (height ?? (MediaQuery.of(context).size.height * widget.heightScale)) + buttonBarHeight; // repeat in case of screen size change
    if (child != null) {
      selectedBottomSheet = child;
      selectedHeight = sheetHeight;
    }
    if (selectedBottomSheet == null) return;
    bottomSheetController = Scaffold.of(context).showBottomSheet(_bottomSheetBuilder, enableDrag: true, constraints: BoxConstraints.expand(height: selectedHeight));
    bottomSheetController?.closed.whenComplete(_onClosed); // for drag close
    setState(() {});
    // setColor();
  }

  void collapse() => bottomSheetController?.close();

  /// call from global state
  void show({Widget? child, double? height}) => WidgetsBinding.instance.addPostFrameCallback((_) => expand(child, height));
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
      height: buttonBarHeight,
      decoration: switch (widget.backgroundImage) {
        ImageProvider image => BoxDecoration(
          image: DecorationImage(image: image, fit: BoxFit.fill),
        ),
        null => null,
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _MaterialWrap(color: color, theme: theme, shape: shape, child: null), // the bar's surface and border, under the backdrop
          ?switch (widget.backdrop) {
            Widget backdrop => Positioned.fill(child: IgnorePointer(child: backdrop)),
            null => null,
          },
          Positioned.fill(child: Center(child: _fab)),
        ],
      ),
    );
  }
}

class const _MaterialWrap({required final Color color, required final BottomSheetThemeData theme, required final ShapeBorder? shape, required final Widget? child}) extends StatelessWidget {
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
