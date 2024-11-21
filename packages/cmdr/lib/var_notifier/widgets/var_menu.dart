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
  const VarKeyWidgetBuilder({required this.builder, this.eventController});

  final Widget Function(VarNotifier) builder; // May be of type Widget Function<G>(VarNotifier)
  final VarEventController? eventController;

  // builder optionally includes the same eventController
  // if an varEventController is provided, retrieving through context is not necessary.
  Widget buildByController(BuildContext _, VarKey value, Widget? __) => VarBaseBuilder(eventController!.varCache.allocate(value), builder);
  Widget buildByContext(BuildContext _, VarKey value, Widget? __) => VarKeyContextBuilder(value, builder);

  ValueWidgetBuilder<VarKey> get asValueWidgetBuilder => (eventController != null) ? buildByController : buildByContext;
}

// wraps widget under, select with right click
// convenience for combining build logic
// use build on VarKey instead of VarNotifier. This way FlyweightMenuSource can be prebuilt, without VarCache state.
// T used to match FlyweightMenuContext<T>
class VarSelectableBuilder<T extends VarKey> extends StatelessWidget {
  VarSelectableBuilder({
    required this.menuSource,
    required this.builder,
    this.initialVarKey,
    this.eventController,
    this.onPressed,
    // this.anchorMenu = true,
    this.menuWidgetBuilder = _menuWidgetBuilder, // builds a MenuAnchorOverlay by default
    super.key,
  }) : _keyBuilder = VarKeyWidgetBuilder(builder: builder, eventController: eventController);

  final FlyweightMenuSource<T> menuSource; //add after
  final T? initialVarKey;
  final ValueSetter<T>? onPressed;

  final Widget Function(VarNotifier) builder; // May be of type Widget Function<G>(VarNotifier)
  // For additional control options, may include stream
  // Retrieve VarCache through context if not provided. VarCache is preallocated, VarKeyContext is set
  // Stream control implemented separately
  final VarEventController? eventController;

  Widget Function(BuildContext context, List<FlyweightMenuItem<T>> menuItems, Widget keyWidget) menuWidgetBuilder;

  final VarKeyWidgetBuilder _keyBuilder;

  static Widget _menuWidgetBuilder(context, menuItems, keyWidget) => MenuAnchorOverlay(menuItems: menuItems, child: keyWidget);

  @override
  Widget build(BuildContext context) {
    return MenuAnchorBuilder(
      menuSource: menuSource,
      initialItem: initialVarKey,
      menuWidgetBuilder: _menuWidgetBuilder,
      menuKeyBuilder: _keyBuilder.asValueWidgetBuilder,
    );

    // return FlyweightMenuOverlay<T>(menu: menu, builder: _builder.asValueWidgetBuilder);
  }
}

// class _VarSelectableBuilderState<T extends VarKey> extends State<VarSelectableBuilder<T>> {
//   // late final FlyweightMenuSource<T> menuSource = widget.menuSource ?? FlyweightMenuSourceContext<T>.of(context).menuSource; // if including find by context

//   late final FlyweightMenu<T> menu = widget.menuSource.create(initialValue: widget.initialVarKey, onPressed: widget.onPressed);

//   @override
//   void dispose() {
//     menu.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) => FlyweightMenuOverlay<T>(menu: menu, builder: _builder.asValueWidgetBuilder);
// }

// typedef VarMenuButton<T extends VarKey> = FlyweightMenuButton<T>;

//   button builder?
