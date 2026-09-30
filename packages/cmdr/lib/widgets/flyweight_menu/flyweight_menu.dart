// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

/// [MenuSource<T>] is a flyweight factory, where the menu items are shared across instances
/// Implementation - [MenuItemButton] callback indirection via context - build time
//  Alternatively, instances use shallow copy - init time
//  change T to ItemKey or ObjectKey?, generic is only useful for subtypes InheritedNotifier
class const FlyweightMenuSource<T>({required final List<FlyweightMenuItem<T>> menuItems, final T? defaultKey}) {
  FlyweightMenuSource._ofBase(FlyweightMenuSource<T> menuSource) : this(menuItems: menuSource.menuItems, defaultKey: menuSource.defaultKey);

  // defaultKey is required if T is not nullable. T must be nullable if defaultValue is not provided
  this : assert(defaultKey is T); // (null is T) || (defaultKey != null)

  FlyweightMenuSource.itemBuilder({required Iterable<T> itemKeys, required Widget Function(T) itemBuilder, T? defaultValue})
    : this(
        menuItems: itemsFrom<T>(itemKeys: itemKeys, itemBuilder: itemBuilder),
        defaultKey: defaultValue,
      );

// keep as MenuSourceItem in case implementation changes
  //todo split model and builder
  // final Widget Function(T) itemBuilder; or just keep the builder
  // createFlyweight()
  // call inside stateful widget, to allow dispose, in most cases
  FlyweightMenu<T> create({ValueSetter<T>? onPressed, T? initialValue}) => FlyweightMenu<T>(this, initialValue: initialValue, onPressed: onPressed);
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

/// [FlyweightMenuInstance]
/// A `Flyweight copy` of the source.
///    - Original values by reference, including the view widgets
///    - A unique [ValueNotifier<T>], for widgets below the menu
///    - original values, including callbacks can be overridden
/// its [menuItems] will find itself via context, and update the notifier + any other callbacks
class FlyweightMenu<T>(
    FlyweightMenuSource<T> menuSource, {
    final ValueSetter<T>? onPressed,
    T? initialValue,
    // IterableFilter<T>? filter,
    // ValueSetter<({T newValue, T oldValue})>? onPressedExt,
  }) extends FlyweightMenuSource<T> with ChangeNotifier implements ValueNotifier<T> {
  //maybe make this private

  this : _value = (initialValue ?? menuSource.defaultKey) as T, // T is either nullable, or initialValue must be provided
       super(
         menuItems: menuSource.menuItems,
         defaultKey: menuSource.defaultKey,
       ) {
    if (onPressed != null) addListener(_onPressedAsListener);
  }

// additional onPressed

  //  final List<FlyweightMenuContextItem<T>> keyItems;
  //  final List<widget> showItems = builder(keyItems._onPressed, keyItems.itemkey  )
  //  final List<widget> showItems = [MenuItemButton(keyItems._onPressed, keyItems.itemkey  )]

  T _value;
  @override
  T get value => _value;
  @override
  set value(T newValue) {
    if (_value == newValue) return;
    //onPressedExt?.call(newValue, value);
    _value = newValue;
    notifyListeners();
  }

  void _onPressedAsListener() => onPressed!.call(_value);
  // onPressedExt?.call(context, _value, notifier.value);

  @override
  void dispose() {
    if (onPressed != null) removeListener(_onPressedAsListener); // should be removed by super.dispose
    super.dispose();
  }

  // @protected
  // @override
  // Never create({ValueSetter<T>? onPressed, ValueSetter<({T newValue, T oldValue})>? onPressedExt}) => throw UnsupportedError('FlyweightMenu cannot be copied');
}

// class FlyweightMenuContextItem<T> {
//   const FlyweightMenuContextItem({
//     required this.context,
//     required this.itemKey,
//   });

//   final BuildContext context;
//   final T? itemKey;
//   void _onPressed() => FlyweightMenuContext.of<T>(context).value = itemKey as T; // calls attached callbacks
//   // FlyweightMenu<S> findMenu(BuildContext context) => FlyweightMenuContext.of<T>(context);
//   // void onPressed(BuildContext context) => findMenu(context).value = this as T; // calls attached callbacks
// }

/// [FlyweightMenuItem<T>] - Wrapper around MenuItemButton, replacing onPressed with a callback to the notifier
/// The callback is unique to each [FlyweightMenu] instance, while the view contents are shared.
/// Implemented as build time build copy, retrieving intrinsic state from the context
///   => a single shared [List<FlyweightMenuItem>] across all [FlyweightMenu] instances.
/// Alternatively, init time shallow copy.
///   each [FlyweightMenu] contains a unique [List<FlyweightMenuItem>] instance, with a number of references to the same source
class const FlyweightMenuItem<T>({super.key, required final Widget child, required final T? itemKey}) extends StatelessWidget {
// if key is null, the item appears as a static image
// the itemBuilder MenuItem from FlyweightMenuSource<T>

  // void _onPressed(BuildContext context) => FlyweightMenuContext.of<T>(context).value = itemKey as T; // calls attached callbacks

  @override
  Widget build(BuildContext context) {
    //todo
    final FlyweightMenu<T> menu = FlyweightMenuContext.of<T>(context);
    void onPressed() => menu.value = itemKey as T; // calls attached callbacks
    // use MenuItemButton as a simple button wih callback around the MenuItem already defined
    return MenuItemButton(
      onPressed: (itemKey != null) ? onPressed : null,
      child: child,
    );
  }
}

// Each FlyweightMenu generally controls only 1 MenuListener, maps 1:1,
// InheritedNotifier simplifies implementation.
final class const FlyweightMenuContext<T>({super.key, required FlyweightMenu<T> super.notifier, required super.child}) extends InheritedNotifier<FlyweightMenu<T>> {
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

class const FlyweightMenuTheme({final ImageProvider? trailingImage}) extends ThemeExtension<FlyweightMenuTheme> {
  @override
  ThemeExtension<FlyweightMenuTheme> copyWith() {
    throw UnimplementedError();
  }

  @override
  ThemeExtension<FlyweightMenuTheme> lerp(covariant ThemeExtension<FlyweightMenuTheme>? other, double t) {
    throw UnimplementedError();
  }
}

/// Builders
typedef MenuWidgetBuilder<T> = Widget Function(BuildContext context, FlyweightMenu<T> menu, Widget keyWidget);

// resolves source to instance notifier
/// wraps user provided menu around user provided key widget
/// FlyweightMenuContainer<T>
class const MenuAnchorBuilder<T>({
    super.key,
    required final FlyweightMenuSource<T> menuSource,
    // required this.menuInstance,
    final T? initialItem,
    required final MenuWidgetBuilder<T> menuAnchorBuilder,
    required final ValueWidgetBuilder<T> keyBuilder,
    final Widget? child,
  }) extends StatefulWidget {
  // final FlyweightMenu<T> menuInstance;  // provide one of either
// builds the outer wrap
// itemBuilder builds the inner widget under the menu, passed to menuAnchorBuilder
// passed to keyBuilder

  @override
  State<MenuAnchorBuilder<T>> createState() => _MenuAnchorBuilderState<T>();
}

class _MenuAnchorBuilderState<T>() extends State<MenuAnchorBuilder<T>> {
  // late final FlyweightMenuSource<T> menuSource = widget.menuSource ?? FlyweightMenuSourceContext<T>.of(context).menuSource; // if including find by context
  late final FlyweightMenu<T> menu = widget.menuSource.create(initialValue: widget.initialItem /*  onPressed: widget.onPressed */);

  // listens to menu for changes
  late final Widget keyListener = ValueListenableBuilder<T>(valueListenable: menu, builder: widget.keyBuilder, child: widget.child);

  @override
  Widget build(BuildContext context) {
    return FlyweightMenuContext<T>(notifier: menu, child: widget.menuAnchorBuilder(context, menu, keyListener));
  }

  @override
  void dispose() {
    menu.dispose(); // dispose notifier
    super.dispose();
  }
}

// case where child depends on menu without displaying the menu
// requires FlyweightMenu Instance
class const MenuListenableBuilder<T>({super.key, required super.builder, super.child, required FlyweightMenu<T> menu}) extends ValueListenableBuilder<T> {
  this : super(valueListenable: menu);
}


////
/// not used by library layer
/// a context for MenuSource. Does not hold a notifier.
/// use cases where a number of view widgets do not need to recreate a MenuSource.
// class FlyweightMenuSourceContext<T extends FlyweightMenuSourceContext<dynamic>> extends InheritedWidget {
//   const FlyweightMenuSourceContext({super.key, required this.menuSource, required super.child});

//   final FlyweightMenuSource menuSource;

//   static FlyweightMenuSourceContext of<T extends FlyweightMenuSourceContext<dynamic>>(BuildContext context) {
//     return context.dependOnInheritedWidgetOfExactType<T>()! as FlyweightMenuSourceContext;
//   }

//   @override
//   bool updateShouldNotify(covariant FlyweightMenuSourceContext<T> oldWidget) {
//     return oldWidget.menuSource != menuSource;
//   }
// }