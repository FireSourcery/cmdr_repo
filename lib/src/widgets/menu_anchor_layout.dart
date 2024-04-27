import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Layouts
class MenuAnchorButton extends StatelessWidget {
  const MenuAnchorButton(this.items, {this.icon = const Icon(Icons.more_horiz), super.key});

  final List<MenuItemButton> items;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    Widget builder(BuildContext context, MenuController controller, Widget? child) {
      return IconButton(onPressed: () => (controller.isOpen) ? controller.close() : controller.open(), icon: icon);
    }

    return MenuAnchor(
      menuChildren: items,
      builder: builder,
      crossAxisUnconstrained: true,
      consumeOutsideTap: true,
    );
  }
}

class MenuAnchorOverlay extends StatelessWidget {
  const MenuAnchorOverlay(this.items, this.child, {this.menuController, super.key});

  final List<MenuItemButton> items;
  final Widget child;
  final MenuController? menuController;

  @override
  Widget build(BuildContext context) {
    final MenuController controller = menuController ?? MenuController();

    void onSecondaryTapDown(TapDownDetails details) => controller.open(position: details.localPosition);
    void onLongPress() => controller.open();

    return GestureDetector(
      onSecondaryTapDown: onSecondaryTapDown,
      onLongPress: onLongPress,
      child: MenuAnchor(
        menuChildren: items,
        controller: controller,
        crossAxisUnconstrained: true,
        consumeOutsideTap: true,
        // child: InkWell(onTap: () {}, child: child),
        child: child,
      ),
    );
  }
}

// class MenuAnchorWrap<T> with ChangeNotifier {
//   MenuAnchorWrap({required this.onPressed, required this.builder, this.selectionFilter, this.context});
//   MenuAnchorWrap.keys({required Iterable<T> keys, required this.onPressed, required this.builder, this.selectionFilter, this.context}) {
//     menuItems = menuItemsOf(keys);
//   }

//   static late final ImageProvider<Object> trailingImage;

//   final ValueSetter<T> onPressed;
//   final Widget Function(T) builder;
//   final IterableFilter<T>? selectionFilter;
//   final BuildContext? context; // if need display variations
//   final Widget? trailingIcon = ImageIcon(trailingImage);

//   late List<MenuItemButton> menuItems; //set from outside

//   // cannot use common instance if onPressed refers to instance
//   // menu must be built per widget so update ref controller instance
//   List<MenuItemButton> menuItemsOf(Iterable<T> keys, [IterableFilter<T>? filter]) {
//     filter ??= selectionFilter;
//     keys = filter?.call(keys) ?? keys;
//     return [
//       for (final key in keys)
//         MenuItemButton(
//           onPressed: () {
//             onPressed(key);
//             notifyListeners();
//           },
//           child: builder(key),
//         )
//     ];
//   }

//   Widget toButton() => ListenableBuilder(listenable: this, builder: (_, __) => MenuAnchorButton(menuItems));
//   Widget contain(Widget child) => ListenableBuilder(listenable: this, builder: (_, __) => child);
//   Widget toOverlay(Widget child) => ListenableBuilder(listenable: this, builder: (_, __) => MenuAnchorOverlay(menuItems, child));
// }
