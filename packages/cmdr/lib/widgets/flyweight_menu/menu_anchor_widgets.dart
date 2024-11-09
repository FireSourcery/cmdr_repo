import 'package:flutter/material.dart';

// Widgets not fully parameterized, defaults/examples, are denoted as _widgets.dart

class MenuAnchorButton extends StatelessWidget {
  const MenuAnchorButton({required this.menuItems, this.icon = const Icon(Icons.more_horiz), super.key});

  final List<Widget> menuItems; // MenuItemButton
  final Widget icon;

  Widget builder(BuildContext context, MenuController controller, Widget? child) {
    return IconButton(onPressed: () => (controller.isOpen) ? controller.close() : controller.open(), icon: icon);
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: menuItems,
      builder: builder,
      crossAxisUnconstrained: true,
      consumeOutsideTap: true,
    );
  }
}

class MenuAnchorOverlay extends StatelessWidget {
  const MenuAnchorOverlay._({required this.menuItems, required this.child, this.menuController, super.key});

  MenuAnchorOverlay({required this.menuItems, required this.child, MenuController? menuController, super.key}) : menuController = menuController ?? MenuController();

  final List<Widget> menuItems; // MenuItemButton
  final Widget child;
  final MenuController? menuController; // pass null disables GestureDetector
  // final VoidCallback? onOpen;
  // final VoidCallback? onClose;

  void onSecondaryTapDown(TapDownDetails details) => menuController!.open(position: details.localPosition);
  void onLongPress() => menuController!.open();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (menuController != null) ? onSecondaryTapDown : null,
      onLongPress: (menuController != null) ? onLongPress : null,
      child: MenuAnchor(
        menuChildren: menuItems,
        controller: menuController,
        crossAxisUnconstrained: true,
        consumeOutsideTap: true,
        // onClose: ,
        // onOpen: ,
        child: InkWell(onTap: () {}, child: child),
        // child: child,
      ),
    );
  }
}
