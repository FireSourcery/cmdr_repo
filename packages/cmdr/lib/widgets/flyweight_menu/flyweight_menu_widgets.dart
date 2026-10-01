import 'package:flutter/material.dart';

import 'flyweight_menu.dart';

/// General
// Menu 'hosts' must wrap MenuAnchor (with menu.menuItems) under MenuSourceContext -> menuItems access menu and its notifier via context
class const FlyweightMenuOverlay<T>({
  super.key,
  required final FlyweightMenu<T> menu, // menuItems onPressed will find the notifier from MenuSourceInstance
  final Widget? child,
  required final ValueWidgetBuilder<T> builder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlyweightMenuContext<T>(
      notifier: menu,
      child: MenuAnchorOverlay(
        menuItems: menu.menuItems,
        // 'Dependents are notified whenever the notifier sends notifications, or whenever the identity of the notifier changes.'
        // Does not appear to rebuild without ValueListenableBuilder
        child: ValueListenableBuilder<T>(valueListenable: menu, builder: builder, child: child),
        // child: builder(context, menu.value, child),
      ),
    );
  }
}

class const FlyweightMenuButton<T>({super.key, required final FlyweightMenu<T> menu}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlyweightMenuContext<T>(
      notifier: menu,
      child: MenuAnchorButton(menuItems: menu.menuItems),
    );
  }
}

/// Default Widgets
class const MenuAnchorButton({
  required final List<Widget> menuItems, // MenuItemButton
  final Widget icon = const Icon(Icons.more_horiz),
  super.key,
}) extends StatelessWidget {
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

  // MenuAnchorOverlay.asBuilder(BuildContext context, FlyweightMenu menu, Widget keyWidget) : this._(menuItems: menu.menuItems, child: keyWidget, menuController: MenuController());

  final List<Widget> menuItems; // MenuItemButton
  final Widget child;
  final MenuController? menuController; // null disables GestureDetector
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
