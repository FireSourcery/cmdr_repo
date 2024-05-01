import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'layouts/menu_anchor_layout.dart';

class MenuSourceButton<T> extends StatelessWidget {
  const MenuSourceButton({super.key, required this.source});
  final MenuSource source;

  //also need wrap
  @override
  Widget build(BuildContext context) => MenuAnchorButton(items: source.menuItems);
}

class MenuSourceWidget<T> extends StatelessWidget {
  const MenuSourceWidget({super.key, required this.source, this.child, required this.builder});
  final MenuSource<T> source;
  final ValueWidgetBuilder<T?> builder;
  final Widget? child;

  // Widget overlay(BuildContext context, T? value, Widget? child) {
  //   // assert(source is MenuSourceInstance<T>);
  //   return MenuAnchorOverlay(source.menuItems, builder(context, value, child));
  // }

  @override
  Widget build(BuildContext context) {
    return MenuSourceNotifier<T>(
      child: MenuAnchorOverlay(items: source.menuItems, child: _MenuListenableBuilder(builder: builder)),
    );

    // return MenuAnchorOverlay(source.menuItems, MenuListenableBuilder<T>(source: source, builder: builder, child: child));

    // switch (source) {
    //   case MenuSourceInstance<T>():
    //     // must wrap MenuAnchor under Listenable, menu items need to effectively rebuild List<MenuItemButton>, as flyweight,
    //     return MenuListenableBuilder<T>(source: source, builder: overlay, valueNotifier: source.notifier!, child: child);
    //   case MenuSource<T>():
    //     final effectiveNotifier = ValueNotifier<T?>(null);
    //     final instance = MenuSourceInstance(effectiveNotifier, source);
    //     return MenuSourceWidget<T>(builder: builder, source: instance, child: child);
    // }
  }
}

// case where child depends on item selected
class MenuListenableBuilder<T> extends StatelessWidget {
  const MenuListenableBuilder({super.key, required this.builder, required this.source, this.valueNotifier, this.child});

  final MenuSource<T> source; // source or instance
  final ValueWidgetBuilder<T?> builder;
  final Widget? child;

  // optional notifier, if not provided, create a new one
  final ValueNotifier<T?>? valueNotifier; // callback notifier, when menu item is selected

  @override
  Widget build(BuildContext context) {
    return MenuSourceNotifier<T>(child: _MenuListenableBuilder(builder: builder));

    // switch (source) {
    //   case MenuSourceInstance<T>():
    //     return ValueListenableBuilder<T?>(valueListenable: source.notifier!, builder: builder, child: child);
    //   case MenuSource<T>():
    //     final effectiveNotifier = valueNotifier ?? ValueNotifier<T?>(null);
    //     final instance = MenuSourceInstance(effectiveNotifier, source);
    //     return MenuListenableBuilder<T>(builder: builder, source: instance, valueNotifier: effectiveNotifier, child: child);
    // }
  }
}

class _MenuListenableBuilder<T> extends StatelessWidget {
  const _MenuListenableBuilder({super.key, required this.builder, /* required this.notifier, */ this.child});

  // final MenuSource<T> source; // source or instance
  final ValueWidgetBuilder<T?> builder;
  final Widget? child;
  // final ValueNotifier<T?> notifier;

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<T?> notifier = MenuSourceNotifier.of<T>(context);
    return builder(context, notifier.value, child);
  }
}

class MenuSourceNotifier<T> extends InheritedNotifier<ValueNotifier<T?>> {
  MenuSourceNotifier({super.key, ValueNotifier<T?>? notifier, required super.child}) : super(notifier: notifier ?? ValueNotifier(null));

  static ValueNotifier<R?> of<R>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MenuSourceNotifier<R>>()!.notifier!;
  }
}

// associates each VoidCallback to a valueNotifier so the List<MenuItemButton> can be shared across instances
// both the flyweight factory and object, in lieu of splitting MenuItemButton
// Although MenuSource generally contains only 1 MenuListenableWidget, maps 1:1, InheritedNotifier simplifies implementation.

/// either source copy takes in context, or instances use wrapper
/// late final ValueSetter<T>? _onPressed = ((T itemKey) => (notifier?.value = itemKey));  // cant create a layer of indirection
/// late final ValueGetter<ValueNotifier?> _notifierGetter;
/// via context to onPressedAbsolute, since redirection will not work
class MenuSource<T> {
  // MenuSource._copyWith({required MenuSource<T> menuSource}) : menuItems = menuSource.menuItems;

  MenuSource({required Iterable<T> itemKeys, required Widget Function(T) itemBuilder, ValueNotifier<T?>? defaultNotifier})
      : menuItems = [
          for (final key in itemKeys)
            Builder(
              builder: (context) => MenuItemButton(
                onPressed: () => onPressedAbsolute(key, context),
                child: itemBuilder(key),
              ),
            ),
        ];

  final List<Widget> menuItems;
  // final T defaultValue; removes null check
  // final ValueNotifier<T?>? notifier;

  // final ObserverList<ValueNotifier<T?>> onPressedMap; onPressedMap = ObserverList<ValueNotifier<T>>(),

  // static List<Widget> buildMenuItems<T>({required Iterable<T> itemKeys, required Widget Function(T) itemBuilder}) {
  //   // return List.generate(itemKeys.length, (index) {
  //   //   void onPressed() => onPressedAbsolute(itemKeys.elementAt(index));
  //   //   return MenuItemButton(onPressed: onPressed, child: itemBuilder(itemKeys.elementAt(index)));
  //   // });
  // }

  static void onPressedAbsolute<T>(T itemKey, BuildContext context) {
    try {
      MenuSourceNotifier.of<T>(context).value = itemKey;
    } catch (e) {
      print(e);
    }
    // _onPressed?.call(itemKey);
    // (notifier?.value = itemKey);
  }

  // MenuSourceInstance<T> instance([ValueNotifier<T?>? instanceNotifier]) => MenuSourceInstance(notifier: instanceNotifier ?? ValueNotifier(null), menuSource: this);
}

// a different type label for clarity
// class MenuSourceInstance<T> extends MenuSource<T> {
//   MenuSourceInstance({required super.notifier, required super.menuSource}) : super._copyWith() {
//     // onPressedMap.add(notifier!);
//   }
// }

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
