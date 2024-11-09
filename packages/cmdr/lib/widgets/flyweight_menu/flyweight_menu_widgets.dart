import 'package:flutter/material.dart';
import 'flyweight_menu.dart';
import 'menu_anchor_widgets.dart';

// Widgets not fully parameterized, defaults/examples, are denoted as _widgets.dart

class FlyweightMenuButton<T> extends StatelessWidget {
  const FlyweightMenuButton({super.key, required this.menu});

  final FlyweightMenu<T> menu;

  @override
  Widget build(BuildContext context) {
    return FlyweightMenuContext<T>(
      notifier: menu,
      child: MenuAnchorButton(menuItems: menu.menuItems),
    );
  }
}

// Menu 'hosts' must wrap MenuAnchor under MenuSourceContext, to allow for the notifier to be accessed by the menu items
class FlyweightMenuAnchor<T> extends StatelessWidget {
  const FlyweightMenuAnchor({super.key, required this.menu, this.child, required this.builder});

  final FlyweightMenu<T> menu; // menuItems onPressed will find the notifier from MenuSourceInstance
  final ValueWidgetBuilder<T> builder;
  final Widget? child;

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

// case where child depends on menu without displaying the menu
class FlyweightMenuListenableBuilder<T> extends StatelessWidget {
  const FlyweightMenuListenableBuilder({super.key, required this.builder, required this.menu, this.child});

  final FlyweightMenu<T> menu;
  final ValueWidgetBuilder<T> builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(valueListenable: menu, builder: builder, child: child);
  }
}
