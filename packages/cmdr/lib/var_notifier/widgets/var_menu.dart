import 'package:flutter/material.dart';

import '../../widgets/flyweight_menu/flyweight_menu.dart';
import '../../widgets/flyweight_menu/flyweight_menu_widgets.dart';
import '../var_notifier.dart';
import 'var_widget.dart';

export '../../widgets/flyweight_menu/flyweight_menu.dart';
export '../../widgets/flyweight_menu/flyweight_menu_widgets.dart';

/// creates the `ValueWidgetBuilder<VarKey>` using a widget constructor 'Widget Function(VarNotifier)'
class const VarKeyWidgetBuilder({required final Widget Function(VarNotifier) builder, final VarCache? varCache}) {
// May be of type Widget Function<G>(VarNotifier)
// if an varCache is provided, retrieving through context is not necessary.

  // builder optionally handle eventController
  Widget buildByCache(BuildContext _, VarKey value, Widget? _) => builder(varCache!.resolve(value));
  Widget buildByContext(BuildContext _, VarKey value, Widget? _) => VarKeyContextBuilder(value, builder);

  ValueWidgetBuilder<VarKey> get asValueWidgetBuilder => (varCache != null) ? buildByCache : buildByContext;

  // Widget asValueWidgetBuilder(BuildContext _, VarKey value, Widget? __) => VarKeyBuilder(value, builder, varCache: varCache);
}

// wraps widget under, select with right click
// convenience for combining build logic
// use build on VarKey instead of VarNotifier. This way FlyweightMenuSource can be prebuilt, without VarCache state.
// T used to match FlyweightMenuContext<T>
@immutable
class const VarSelectableBuilder<T extends VarKey>({
    required final FlyweightMenuSource<T> menuSource,
    required final Widget Function(VarNotifier) builder, // builder optionally includes a event controller. menu notification included with FlyweightMenu
    final T? initialVarKey,
    final VarCache? varCache,
    final ValueSetter<T>? onPressed,
    final MenuWidgetBuilder<T> menuWidgetBuilder = _menuWidgetBuilder, // builds a MenuAnchorOverlay by default
    super.key,
  }) extends StatelessWidget {
  static Widget _menuWidgetBuilder(BuildContext context, FlyweightMenu menu, Widget keyWidget) => MenuAnchorOverlay(menuItems: menu.menuItems, child: keyWidget);

  Widget keyWidgetBuilder(BuildContext _, VarKey value, Widget? _) => VarKeyBuilder(value, builder, varCache: varCache);

// May be of type Widget Function<G>(VarNotifier)
//alternatively, let caller handle retrieval from context.

  @override
  Widget build(BuildContext context) {
    final keyBuilder = VarKeyWidgetBuilder(builder: builder, varCache: varCache); // Retrieve VarCache through context if not provided.
    return MenuAnchorBuilder(
      menuSource: menuSource,
      initialItem: initialVarKey,
      menuAnchorBuilder: menuWidgetBuilder,
      keyBuilder: keyBuilder.asValueWidgetBuilder,
    );
  }
}
