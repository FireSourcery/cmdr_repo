import 'package:flutter/material.dart';

/// [MenuSource<T>] is a flyweight factory, where the menu items are shared across instances
/// Implementation - [MenuItemButton] callback indirection via context - build time
//  Alternatively, instances use shallow copy - init time
//  change T to ItemKey or ObjectKey?
class FlyweightMenuSource<T> {
  FlyweightMenuSource._ofBase(FlyweightMenuSource<T> menuSource) : this(menuItems: menuSource.menuItems, defaultKey: menuSource.defaultKey);

  // defaultKey is required if T is not nullable. T must be nullable if defaultValue is not provided
  FlyweightMenuSource({required this.menuItems, this.defaultKey}) : assert(defaultKey is T); // (null is T) || (defaultKey != null)

  FlyweightMenuSource.itemBuilder({
    required Iterable<T> itemKeys,
    required Widget Function(T) itemBuilder,
    T? defaultValue,
  }) : this(menuItems: itemsFrom<T>(itemKeys: itemKeys, itemBuilder: itemBuilder), defaultKey: defaultValue);

  final List<FlyweightMenuItem> menuItems; // keep as MenuSourceItem in case implementation changes
  final T? defaultKey;

  // createFlyweight()
  // should be called inside stateful widget, to allow dispose
  FlyweightMenu<T> create({ValueSetter<T>? onPressed, T? initialValue}) => FlyweightMenu<T>(this, onPressed: onPressed);
  // ValueSetter<({T newValue, T oldValue})>? onPressedExt,

  // if this class holds state for dispose
  // final List<FlyweightMenu> _menuInstances = [];
  // void dispose() {
  //   for (var menu in _menuInstances) {
  //     menu.dispose();
  //   }
  // }

  static List<FlyweightMenuItem<T>> itemsFrom<T>({required Iterable<T> itemKeys, required Widget Function(T) itemBuilder}) {
    return [for (final key in itemKeys) FlyweightMenuItem<T>(itemKey: key, child: itemBuilder(key))];
  }
}

/// A `Flyweight copy` of the source.
///    - Original values by reference, including the view widgets
///    - A unique [ValueNotifier<T>], for widgets below the menu
///    - original values, including callbacks can be overridden
/// its [menuItems] will find itself via context, and update the notifier + any other callbacks
class FlyweightMenu<T> extends FlyweightMenuSource<T> with ChangeNotifier implements ValueNotifier<T> {
  //maybe make this private

  FlyweightMenu(
    super.menuSource, {
    this.onPressed,
    T? initialValue,
    // ValueSetter<({T newValue, T oldValue})>? onPressedExt,
    // IterableFilter<T>? filter,
    // ValueNotifier<T>? notifier,
  })  : _value = (initialValue ?? menuSource.defaultKey) as T, // T is either nullable, or initialValue must be provided
        super._ofBase() {
    if (onPressed != null) addListener(_callbacks);
  }

  final ValueSetter<T>? onPressed; // additional onPressed

  T _value;
  @override
  T get value => _value;
  @override
  set value(T newValue) {
    if (_value == newValue) {
      return;
    }
    //onPressedExt?.call(newValue, value);
    _value = newValue;
    notifyListeners();
  }

  void _callbacks() {
    onPressed!.call(_value);
    // onPressedExt?.call(context, _value, notifier.value);
  }

  @override
  void dispose() {
    if (onPressed != null) removeListener(_callbacks); // should be removed by super.dispose
    super.dispose();
  }

  // @protected
  // @override
  // Never create({ValueSetter<T>? onPressed, ValueSetter<({T newValue, T oldValue})>? onPressedExt}) => throw UnsupportedError('FlyweightMenu cannot be copied');
}

/// [FlyweightMenuItem<T>] - Wrapper around MenuItemButton, replacing onPressed with a callback to the notifier
/// The callback is unique to each [FlyweightMenu] instance, while the view contents are shared.
/// Implemented as build time build copy, retrieving intrinsic state from the context
///   => a single shared [List<FlyweightMenuItem>] across all [FlyweightMenu] instances.
/// Alternatively, init time shallow copy.
///   each [FlyweightMenu] contains a unique [List<FlyweightMenuItem>] instance, with a number of references to the same source
class FlyweightMenuItem<T> extends StatelessWidget {
  const FlyweightMenuItem({super.key, required this.child, required this.itemKey});

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

  final Widget child; // the already built MenuItem
  final T? itemKey; // if key is null, the item appears as a static image

  @override
  Widget build(BuildContext context) {
    final FlyweightMenu<T> notifier = FlyweightMenuContext.of<T>(context);
    void onPressed() => notifier.value = itemKey as T; // calls attached callbacks

    // use MenuItemButton as a simple button wih callback around the MenuItem already built
    return MenuItemButton(
      onPressed: (itemKey != null) ? onPressed : null,
      child: child,
    );
  }
}

// MenuSource generally controls only 1 MenuListenableWidget, maps 1:1,
// InheritedNotifier simplifies implementation.
final class FlyweightMenuContext<T> extends InheritedNotifier<FlyweightMenu<T>> {
  const FlyweightMenuContext({super.key, required FlyweightMenu<T> super.notifier, required super.child});
  // FlyweightMenuContext.bySource({super.key, required FlyweightMenuSource<T> source, required super.child}) : super(notifier: source.create());

  static FlyweightMenuContext<T>? _maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FlyweightMenuContext<T>>();
  }

  static FlyweightMenu<T> of<T>(BuildContext context) {
    final FlyweightMenuContext<T>? result = _maybeOf<T>(context);
    assert(result != null, 'No ${FlyweightMenuContext<T>} found in context');
    return result!.notifier!;
    // return context.dependOnInheritedWidgetOfExactType<FlyweightMenuContext<T>>()!.notifier!;
  }

  // @override
  // bool updateShouldNotify(covariant FlyweightMenuContext<T> oldWidget) {
  //   return notifier!.value != oldWidget.notifier!.value;
  // }
}

/// a context for MenuSource. Does not hold a notifier.
/// use cases where a number of view widgets do not need to recreate a MenuSource.
// class FlyweightMenuSourceContext<T> extends InheritedWidget {
//   const FlyweightMenuSourceContext({super.key, required this.menuSource, required super.child});

//   final FlyweightMenuSource<T> menuSource;

//   static FlyweightMenuSourceContext<T> of<T>(BuildContext context) {
//     return context.dependOnInheritedWidgetOfExactType<FlyweightMenuSourceContext<T>>()!;
//   }

//   @override
//   bool updateShouldNotify(covariant FlyweightMenuSourceContext<T> oldWidget) {
//     return oldWidget.menuSource != menuSource;
//   }
// }

class FlyweightMenuTheme extends ThemeExtension<FlyweightMenuTheme> {
  const FlyweightMenuTheme({this.trailingImage});

  final ImageProvider? trailingImage;

  @override
  ThemeExtension<FlyweightMenuTheme> copyWith() {
    throw UnimplementedError();
  }

  @override
  ThemeExtension<FlyweightMenuTheme> lerp(covariant ThemeExtension<FlyweightMenuTheme>? other, double t) {
    throw UnimplementedError();
  }
}
