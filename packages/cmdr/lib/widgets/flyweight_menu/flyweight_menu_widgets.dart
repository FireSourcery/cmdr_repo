import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'flyweight_menu.dart';

/// General
class const FlyweightMenuButton<T>({super.key, required final FlyweightMenu<T> menu}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MenuAnchorButton(menuItems: menu.menuItems);
  }
}

/// Default Widgets
class const MenuAnchorButton({
  required final List<Widget> menuItems, // MenuItemButton
  final Widget icon = const Icon(Icons.more_horiz),
  super.key,
}) extends StatelessWidget {
  Widget builder(BuildContext context, MenuController controller, Widget? child) {
    return IconButton(onPressed: () => (controller.isOpen) ? controller.close() : controller.open(), tooltip: MaterialLocalizations.of(context).showMenuTooltip, icon: icon);
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

class const MenuAnchorOverlay({
  required final List<Widget> menuItems, // MenuItemButton
  required final Widget child,
  super.key,
}) extends StatefulWidget {
  // MenuAnchorOverlay.asBuilder(BuildContext context, FlyweightMenu menu, Widget keyWidget) : this._(menuItems: menu.menuItems, child: keyWidget, menuController: MenuController());

  // final VoidCallback? onOpen;
  // final VoidCallback? onClose;

  @override
  State<MenuAnchorOverlay> createState() => _MenuAnchorOverlayState();
}

// owns the [MenuController]: one made per widget would be replaced on every parent rebuild
class _MenuAnchorOverlayState() extends State<MenuAnchorOverlay> {
  final MenuController menuController = MenuController();

  void onSecondaryTapDown(TapDownDetails details) => menuController.open(position: details.localPosition);
  void onLongPress() => menuController.open();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: onSecondaryTapDown,
      onLongPress: onLongPress,
      child: MenuAnchor(
        menuChildren: widget.menuItems,
        controller: menuController,
        crossAxisUnconstrained: true,
        consumeOutsideTap: true,
        // onClose: ,
        // onOpen: ,
        child: Semantics(
          button: true,
          tooltip: MaterialLocalizations.of(context).showMenuTooltip,
          onTap: menuController.open,
          // Enter/Space on the focused anchor, and the context-menu keys; a primary tap does not open the menu.
          // A child that takes text input would lose Enter and Space to these.
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): menuController.open,
              const SingleActivator(LogicalKeyboardKey.numpadEnter): menuController.open,
              const SingleActivator(LogicalKeyboardKey.space): menuController.open,
              const SingleActivator(LogicalKeyboardKey.contextMenu): menuController.open,
              const SingleActivator(LogicalKeyboardKey.f10, shift: true): menuController.open,
            },
            child: InkWell(onTap: () {}, excludeFromSemantics: true, child: widget.child),
          ),
        ),
        // child: child,
      ),
    );
  }
}
