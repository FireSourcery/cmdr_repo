import 'package:flutter/material.dart';

import '../../widgets/flyweight_menu/flyweight_menu.dart';
import '../../widgets/flyweight_menu/flyweight_menu_widgets.dart';
import '../var_notifier.dart';
import 'var_widget.dart';

export '../../widgets/flyweight_menu/flyweight_menu.dart';
export '../../widgets/flyweight_menu/flyweight_menu_widgets.dart';

// wraps widget under, select with right click
// convenience for combining build logic
// T used to match FlyweightMenuContext<T>
class VarSelectableBuilder<T extends VarKey> extends StatefulWidget {
  const VarSelectableBuilder({required this.builder, this.initialVarKey, super.key, required this.menuSource, this.varEventController, this.onPressed});

  // use build on VarKey instead of VarNotifier. This way FlyweightMenuSource can be prebuilt, without VarCache state.
  final FlyweightMenuSource<T> menuSource;
  final Widget Function(VarNotifier value) builder; // May be of type Widget Function<G>(VarNotifier value)
  final T? initialVarKey;
  final ValueSetter<T>? onPressed;

  // For additional control options, may include stream
  // Retrieve VarCache through context if not provided. VarCache is preallocated, VarKeyContext is set
  // Stream control implemented separately
  final VarEventController? varEventController;

  Widget buildByContext(BuildContext context, T value, Widget? child) {
    return VarKeyBuilder(value, builder);
  }

  // if an varEventController is provided, retrieving through context is not necessary.
  Widget buildByController(BuildContext context, T value, Widget? child) {
    return VarBuilder(varEventController!.varCache.allocate(value), builder); // builder optionally includes the same eventController
  }

  @override
  State<VarSelectableBuilder<T>> createState() => _VarSelectableBuilderState<T>();
}

class _VarSelectableBuilderState<T extends VarKey> extends State<VarSelectableBuilder<T>> {
  late final ValueWidgetBuilder<T> effectiveBuilder = (widget.varEventController != null) ? widget.buildByController : widget.buildByContext;
  late final FlyweightMenu<T> menu = widget.menuSource.create(initialValue: widget.initialVarKey, onPressed: widget.onPressed);

  @override
  void dispose() {
    menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlyweightMenuAnchor<T>(menu: menu, builder: effectiveBuilder);
  }
}

typedef VarMenuButton<T extends VarKey> = FlyweightMenuButton<T>;
//   button builder?



