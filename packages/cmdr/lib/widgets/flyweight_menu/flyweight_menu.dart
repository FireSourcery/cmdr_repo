// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

/// A flyweight factory: one list of [FlyweightMenuItem] views shared by every [FlyweightMenu] created from it.
///
/// Init-time binding: `create()` gives each instance its own [MenuItemButton]s, bound to that instance's notifier,
/// around the shared item views. The earlier build-time design is kept in `flyweight_menu_v0.dart`.
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

/// One menu: a [ValueNotifier] of the selected key, plus [menuItems], the [MenuItemButton]s bound to it at creation
/// around the [source]'s shared item views. [onPressed] is an extra callback on every change.
class FlyweightMenu<T>(
  final FlyweightMenuSource<T> source, {
  final ValueSetter<T>? onPressed, // additional onPressed
  T? initialValue,
  // IterableFilter<T>? filter,
  // ValueSetter<({T newValue, T oldValue})>? onPressedExt,
}) with ChangeNotifier implements ValueNotifier<T> {
  // T is either nullable, or initialValue must be provided
  this : _value = (initialValue ?? source.defaultKey) as T {
    if (onPressed != null) addListener(_onPressedAsListener);
  }

  late final List<Widget> menuItems = [for (final item in source.menuItems) MenuItemButton(onPressed: item.itemKey != null ? () => value = item.itemKey as T : null, child: item.child)];

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
}

/// The intrinsic state of a menu item, its key and its view, shared by every [FlyweightMenu] of the source. Each
/// instance wraps [child] in its own [MenuItemButton]; a null [itemKey] renders a static entry.
class const FlyweightMenuItem<T>({
  required final Widget child,
  required final T? itemKey,
}) {
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
}

/// Builders
typedef MenuWidgetBuilder<T> = Widget Function(BuildContext context, FlyweightMenu<T> menu, Widget keyWidget);

/// Resolves a [FlyweightMenuSource] to an instance it owns and wraps the user's menu around the user's key widget.
class const MenuAnchorBuilder<T>({
  super.key,
  required final FlyweightMenuSource<T> menuSource,
  // required this.menuInstance,
  final T? initialItem,
  required final MenuWidgetBuilder<T> menuAnchorBuilder, // builds the outer wrap
  required final ValueWidgetBuilder<T> keyBuilder, // itemBuilder builds the inner widget under the menu, passed to menuAnchorBuilder
  final Widget? child, // passed to keyBuilder
}) extends StatefulWidget {
  // final FlyweightMenu<T> menuInstance;  // provide one of either

  @override
  State<MenuAnchorBuilder<T>> createState() => _MenuAnchorBuilderState<T>();
}

class _MenuAnchorBuilderState<T>() extends State<MenuAnchorBuilder<T>> {
  late final FlyweightMenu<T> menu = widget.menuSource.create(initialValue: widget.initialItem /*  onPressed: widget.onPressed */);

  // listens to menu for changes
  late final Widget keyListener = ValueListenableBuilder<T>(valueListenable: menu, builder: widget.keyBuilder, child: widget.child);

  @override
  Widget build(BuildContext context) {
    return widget.menuAnchorBuilder(context, menu, keyListener);
  }

  @override
  void dispose() {
    menu.dispose(); // dispose notifier
    super.dispose();
  }
}
