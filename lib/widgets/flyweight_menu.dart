import 'package:flutter/material.dart';
import 'layouts/menu_anchor_layout.dart';

class MenuSourceButton<T> extends StatelessWidget {
  const MenuSourceButton({super.key, required this.source});

  final MenuSourceInstance<T> source;

  @override
  Widget build(BuildContext context) {
    return MenuSourceContext<T>(
      source: source,
      child: MenuAnchorButton(items: source.menuItems),
    );
  }
}

// Menu 'hosts' must wrap MenuAnchor under MenuSourceContext, to allow for the notifier to be accessed by the menu items
class MenuSourceWidget<T> extends StatelessWidget {
  const MenuSourceWidget({super.key, required this.source, this.child, required this.builder});

  final MenuSourceInstance<T> source;
  final ValueWidgetBuilder<T?> builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // menuItems onPressed will find the notifier from MenuSourceInstance
    return MenuSourceContext<T>(
      source: source,
      // "Dependents are notified whenever the notifier sends notifications, or whenever the identity of the notifier changes."
      // not working without ValueListenableBuilder?
      child: MenuAnchorOverlay(
        items: source.menuItems,
        child: ValueListenableBuilder<T?>(valueListenable: source.notifier, builder: builder, child: child),
      ),
    );
  }
}

// case where child depends on menu without displaying the menu
class MenuListenableBuilder<T> extends StatelessWidget {
  const MenuListenableBuilder({super.key, required this.builder, required this.source, this.child});

  final MenuSourceInstance<T> source;
  final ValueWidgetBuilder<T?> builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T?>(valueListenable: source.notifier, builder: builder, child: child);
  }
}

// MenuSource<T> is a flyweight factory, where the menu items are shared across instances
//  either MenuItemButton callback layer indirection via context - build time
//  or instances use shallow copy - init time
class MenuSource<T> {
  MenuSource._({required this.menuItems});
  MenuSource._instance(MenuSource<T> menuSource) : menuItems = menuSource.menuItems;

  const MenuSource.items(List<MenuSourceItem> this.menuItems);

  // this can be made const if use chang menuItemButton to model
  MenuSource.itemBuilder({
    required Iterable<T> itemKeys,
    required Widget Function(T) itemBuilder,
    ValueSetter<T>? onPressed,
    // ValueSetter<(T, T)>? onPressedWithCurrent,
    void Function(BuildContext context, T newValue, T oldValue)? onPressedExt,
  }) : menuItems = [
          for (final key in itemKeys)
            MenuSourceItem<T>(
              itemKey: key,
              onPressed: onPressed,
              // onPressedWithCurrent: onPressedWithCurrent,
              onPressedExt: onPressedExt,
              menuItemButton: MenuItemButton(child: itemBuilder(key)),
            ),
        ];

  final List<Widget> menuItems;

  MenuSourceInstance<T> instance() => MenuSourceInstance(this);

  static List<MenuSourceItem> itemsFrom<T>({required Iterable<T> itemKeys, required Widget Function(T) itemBuilder, ValueSetter<T>? onPressed}) {
    return [
      for (final key in itemKeys)
        MenuSourceItem<T>(
          itemKey: key,
          menuItemButton: MenuItemButton(child: itemBuilder(key)),
        ),
    ];
  }
  // MenuSource.from(List<MenuItemButton> menuItems) : menuItems = [for (final item in menuItems) MenuSourceItem<T>(itemKey: item.represents, menuItemButton: item)];
}

// alternatively shallow copy
// alternatively implement ValueNotifier
class MenuSourceInstance<T> extends MenuSource<T> {
  MenuSourceInstance(super.menuSource) : super._instance();

  ValueNotifier<T?> notifier = ValueNotifier<T?>(null);
  // final T defaultValue; removes null check
}

// wrapper around MenuItemButton, to allow for a shared List<MenuItemButton> across instances
// use the same data as MenuItemButton, replacing onPressed with a callback to the notifier
// build time copy allows menuItemButton to be shared, alternatively use copyWith to create a shallow copy per instance
class MenuSourceItem<T> extends StatelessWidget {
  const MenuSourceItem({super.key, required this.menuItemButton, required this.itemKey, this.onPressed, /* this.onPressedWithCurrent, */ this.onPressedExt});

  // static List<MenuSourceItem> listFrom<T>({required Iterable<T> itemKeys, required Widget Function(T) itemBuilder, ValueSetter<T>? onPressed});

  // const MenuSourceItem.components({
  //   super.key,
  //   this.onPressed,
  //   this.onHover,
  //   this.requestFocusOnHover = true,
  //   this.onFocusChange,
  //   this.focusNode,
  //   this.shortcut,
  //   this.style,
  //   this.statesController,
  //   this.clipBehavior = Clip.none,
  //   this.leadingIcon,
  //   this.trailingIcon,
  //   this.closeOnActivate = true,
  //   required this.child,
  // });

  final MenuItemButton menuItemButton;
  final ValueSetter<T>? onPressed;
  // final ValueSetter<(T newValue, T oldValue)>? onPressedWithCurrent;
  final void Function(BuildContext context, T newValue, T oldValue)? onPressedExt;
  final T itemKey;

  @override
  Widget build(BuildContext context) {
    final notifier = MenuSourceContext.of<T>(context);
    return MenuItemButton(
      onPressed: () {
        onPressed?.call(itemKey);
        // onPressedWithCurrent?.call((itemKey, notifier.value!));
        notifier.value = itemKey;
      },
      child: menuItemButton.child,
    );
  }
}

// Although MenuSource generally controls only 1 MenuListenableWidget, maps 1:1, InheritedNotifier simplifies implementation.
class MenuSourceContext<T> extends InheritedNotifier<ValueNotifier<T?>> {
  // MenuSourceNotifier({super.key, ValueNotifier<T?>? notifier, required super.child}) : super(notifier: notifier ?? ValueNotifier(null));
  const MenuSourceContext._({super.key, required ValueNotifier<T?> super.notifier, required super.child});
  MenuSourceContext({super.key, required MenuSourceInstance<T?> source, required super.child}) : super(notifier: source.notifier);

  static ValueNotifier<T?> of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MenuSourceContext<T>>()!.notifier!;
  }
}

class MenuSourceTheme extends ThemeExtension<MenuSourceTheme> {
  const MenuSourceTheme({this.trailingImage});

  final ImageProvider? trailingImage;

  @override
  ThemeExtension<MenuSourceTheme> copyWith() {
    throw UnimplementedError();
  }

  @override
  ThemeExtension<MenuSourceTheme> lerp(covariant ThemeExtension<MenuSourceTheme>? other, double t) {
    throw UnimplementedError();
  }
}
