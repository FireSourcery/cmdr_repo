// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'flyweight_menu_widgets.dart' show MenuAnchorButton, MenuAnchorOverlay;

/// The first flyweight menu design, kept for reference. Not exported; `flyweight_menu.dart` is the live one.
///
/// Build-time binding: the shared [FlyweightMenuItem] is a widget, and each press finds the menu it is rendered under
/// through [FlyweightMenuContext], an [InheritedNotifier] that every anchor wraps around its panel. Why this was
/// replaced by the init-time copy: `doc/decisions/0002_flyweight_menu_binds_at_creation.md`.
class const FlyweightMenuSource<T>({
  required final List<FlyweightMenuItem<T>> menuItems,
  final T? defaultKey,
}) {
  // defaultKey is required if T is not nullable. T must be nullable if defaultValue is not provided
  this : assert(defaultKey is T); // (null is T) || (defaultKey != null)

  FlyweightMenuSource.itemBuilder({required Iterable<T> itemKeys, required Widget Function(T) itemBuilder, T? defaultValue})
    : this(
        menuItems: itemsFrom<T>(itemKeys: itemKeys, itemBuilder: itemBuilder),
        defaultKey: defaultValue,
      );

  /// Call inside a stateful widget, which disposes the instance.
  FlyweightMenu<T> create({ValueSetter<T>? onPressed, T? initialValue}) => FlyweightMenu<T>(this, initialValue: initialValue, onPressed: onPressed);

  static List<FlyweightMenuItem<T>> itemsFrom<T>({required Iterable<T> itemKeys, required Widget Function(T) itemBuilder}) {
    return [for (final key in itemKeys) FlyweightMenuItem<T>(itemKey: key, child: itemBuilder(key))];
  }
}

/// A flyweight copy of the source: the same item widgets by reference, plus a unique [ValueNotifier] for the widgets
/// below the menu. Its [menuItems] find this instance through the build context and update the notifier and callbacks.
class FlyweightMenu<T>(
  FlyweightMenuSource<T> menuSource, {
  final ValueSetter<T>? onPressed, // additional onPressed
  T? initialValue,
}) extends FlyweightMenuSource<T> with ChangeNotifier implements ValueNotifier<T> {
  this
    : _value = (initialValue ?? menuSource.defaultKey) as T, // T is either nullable, or initialValue must be provided
      super(
        menuItems: menuSource.menuItems,
        defaultKey: menuSource.defaultKey,
      ) {
    if (onPressed != null) addListener(_onPressedAsListener);
  }

  T _value;
  @override
  T get value => _value;
  @override
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  void _onPressedAsListener() => onPressed!.call(_value);

  @override
  void dispose() {
    if (onPressed != null) removeListener(_onPressedAsListener);
    super.dispose();
  }
}

/// The shared item: a [MenuItemButton] whose `onPressed` resolves the enclosing [FlyweightMenu] at build time, so one
/// item widget serves every instance. A null [itemKey] renders a static entry.
class const FlyweightMenuItem<T>({
  super.key,
  required final Widget child,
  required final T? itemKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FlyweightMenu<T> menu = FlyweightMenuContext.of<T>(context);
    void onPressed() => menu.value = itemKey as T;
    return MenuItemButton(
      onPressed: (itemKey != null) ? onPressed : null,
      child: child,
    );
  }
}

/// The lookup key of the design: an [InheritedNotifier] matched by exact type, so `T` selects the menu as well as
/// typing its keys. Each [FlyweightMenu] controls one of these.
final class const FlyweightMenuContext<T>({super.key, required FlyweightMenu<T> super.notifier, required super.child}) extends InheritedNotifier<FlyweightMenu<T>> {
  static FlyweightMenuContext<T>? _maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FlyweightMenuContext<T>>();
  }

  static FlyweightMenu<T> of<T>(BuildContext context) {
    final FlyweightMenuContext<T>? result = _maybeOf<T>(context);
    assert(result != null, 'No ${FlyweightMenuContext<T>} found in context');
    return result!.notifier!;
  }
}

typedef MenuWidgetBuilder<T> = Widget Function(BuildContext context, FlyweightMenu<T> menu, Widget keyWidget);

/// Resolves a source to an instance and wraps the user's menu around the user's key widget, under the context the
/// items look up.
class const MenuAnchorBuilder<T>({
  super.key,
  required final FlyweightMenuSource<T> menuSource,
  final T? initialItem,
  required final MenuWidgetBuilder<T> menuAnchorBuilder, // builds the outer wrap
  required final ValueWidgetBuilder<T> keyBuilder, // builds the inner widget under the menu, passed to menuAnchorBuilder
  final Widget? child, // passed to keyBuilder
}) extends StatefulWidget {
  @override
  State<MenuAnchorBuilder<T>> createState() => _MenuAnchorBuilderState<T>();
}

class _MenuAnchorBuilderState<T>() extends State<MenuAnchorBuilder<T>> {
  late final FlyweightMenu<T> menu = widget.menuSource.create(initialValue: widget.initialItem);

  late final Widget keyListener = ValueListenableBuilder<T>(valueListenable: menu, builder: widget.keyBuilder, child: widget.child);

  @override
  Widget build(BuildContext context) {
    return FlyweightMenuContext<T>(notifier: menu, child: widget.menuAnchorBuilder(context, menu, keyListener));
  }

  @override
  void dispose() {
    menu.dispose();
    super.dispose();
  }
}

/// A child that depends on the menu without displaying it.
class const MenuListenableBuilder<T>({super.key, required super.builder, super.child, required FlyweightMenu<T> menu}) extends ValueListenableBuilder<T> {
  this : super(valueListenable: menu);
}

/// Menu hosts wrap the anchor under [FlyweightMenuContext], so the items can find the notifier.
class const FlyweightMenuOverlay<T>({
  super.key,
  required final FlyweightMenu<T> menu,
  final Widget? child,
  required final ValueWidgetBuilder<T> builder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlyweightMenuContext<T>(
      notifier: menu,
      child: MenuAnchorOverlay(
        menuItems: menu.menuItems,
        child: ValueListenableBuilder<T>(valueListenable: menu, builder: builder, child: child),
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
