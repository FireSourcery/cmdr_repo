// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'flyweight_menu.dart';
import 'menu_anchor_widgets.dart';

// Widgets not fully parameterized, defaults/examples, are denoted as _widgets.dart

// Menu 'hosts' must wrap MenuAnchor (with menu.menuItems) under MenuSourceContext -> menuItems access menu and its notifier via context
class FlyweightMenuOverlay<T> extends StatelessWidget {
  const FlyweightMenuOverlay({super.key, required this.menu, this.child, required this.builder});

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



// /// build from source
// class FlyweightMenuContainer<T> extends StatefulWidget {
//   const FlyweightMenuContainer({
//     super.key,
//     required this.menuSource,
//     required this.builder,
//     this.anchorMenu = true,
//   });

//   final FlyweightMenuSource<T> menuSource;
//   final ValueWidgetBuilder<T> builder;
//   final bool anchorMenu;

//   final Function(BuildContext context, FlyweightMenu menu, T menuKey) menufulWidgetBuild;

//   final T? initialValue = null;
//   final ValueSetter<T>? onPressed = null;

//   @override
//   State<FlyweightMenuContainer<T>> createState() => _FlyweightMenuContainerState<T>();
// }

// class _FlyweightMenuContainerState<T> extends State<FlyweightMenuContainer<T>> {
//   late final FlyweightMenu<T> menu = widget.menuSource.create(initialValue: widget.initialValue, onPressed: widget.onPressed);

//   @override
//   void dispose() {
//     menu.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return widget.menufulWidgetBuild(context, menu, menu.value);
//   }
// }
