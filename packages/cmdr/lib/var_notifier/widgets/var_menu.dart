import 'package:flutter/material.dart';

import '../../widgets/flyweight_menu/flyweight_menu.dart';
import '../../widgets/flyweight_menu/flyweight_menu_widgets.dart';
import '../../widgets/flyweight_menu/menu_anchor_widgets.dart';
import '../var_notifier.dart';
import 'var_widget.dart';

export '../../widgets/flyweight_menu/flyweight_menu.dart';
export '../../widgets/flyweight_menu/flyweight_menu_widgets.dart';

/// creates the ValueWidgetBuilder<VarKey> using a widget constructor 'Widget Function(VarNotifier)'
class VarKeyWidgetBuilder {
  const VarKeyWidgetBuilder({required this.builder, this.varCache});

  final Widget Function(VarNotifier) builder; // May be of type Widget Function<G>(VarNotifier)
  final VarCache? varCache;

  // builder optionally includes a eventController
  // if an varEventController is provided, retrieving through context is not necessary.
  // Widget buildByController(BuildContext _, VarKey value, Widget? __) => VarBaseBuilder(varCache!.allocate(value), builder);
  Widget buildByController(BuildContext _, VarKey value, Widget? __) => builder(varCache!.allocate(value));
  Widget buildByContext(BuildContext _, VarKey value, Widget? __) => VarKeyContextBuilder(value, builder);

  ValueWidgetBuilder<VarKey> get asValueWidgetBuilder => (varCache != null) ? buildByController : buildByContext;
}

// wraps widget under, select with right click
// convenience for combining build logic
// use build on VarKey instead of VarNotifier. This way FlyweightMenuSource can be prebuilt, without VarCache state.
// T used to match FlyweightMenuContext<T>
@immutable
class VarSelectableBuilder<T extends VarKey> extends StatelessWidget {
  const VarSelectableBuilder({
    required this.menuSource,
    required this.builder,
    this.initialVarKey,
    this.varCache,
    this.onPressed,
    // this.anchorMenu = true,
    this.menuWidgetBuilder = _menuWidgetBuilder, // builds a MenuAnchorOverlay by default
    super.key,
  });

  static Widget _menuWidgetBuilder(BuildContext context, FlyweightMenu menu, Widget keyWidget) => MenuAnchorOverlay(menuItems: menu.menuItems, child: keyWidget);

  final FlyweightMenuSource<T> menuSource; // add after
  final T? initialVarKey;
  final ValueSetter<T>? onPressed;
  final Widget Function(VarNotifier) builder; // May be of type Widget Function<G>(VarNotifier)
  final VarCache? varCache; // builder optionally includes a event controller. menu notification included with FlyweightMenu
  final MenuWidgetBuilder<T> menuWidgetBuilder;

  @override
  Widget build(BuildContext context) {
    final keyBuilder = VarKeyWidgetBuilder(builder: builder, varCache: varCache); // Retrieve VarCache through context if not provided.
    return MenuAnchorBuilder(
      menuSource: menuSource,
      initialItem: initialVarKey,
      menuAnchorBuilder: _menuWidgetBuilder,
      keyBuilder: keyBuilder.asValueWidgetBuilder,
    );
  }
}
