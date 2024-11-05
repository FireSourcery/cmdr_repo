import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:cmdr_common/basic_types.dart';

import 'var_context.dart';
import 'var_notifier.dart';

/// Widget tools

////////////////////////////////////////////////////////////////////////////////
/// Widget Interface
/// convenience interface for mapping widget callbacks
////////////////////////////////////////////////////////////////////////////////
/// implicitly casts the VarNotifier
///
/// getters preferred over configObject, as the widget can select which callbacks are retained
/// as a mixin allows for use as interface
abstract mixin class VarNotifierViewer<V> {
  const VarNotifierViewer();
//   _VarWidgetSource.assertType(this.varController) : assert(varController.varNotifier.varKey.viewType.isExactType<T>());

  @protected
  VarNotifier<dynamic> get varNotifier;

  ValueNotifier<dynamic> get valueNotifier => varNotifier; // for value updates
  ValueChanged<V> get valueChanged => varNotifier.updateByViewAs<V>; // onChange. call for all updates to update UI

  // Anonymous functions defined this way should not be reallocated
  ValueGetter<V> get valueGetter => varNotifier.valueAs<V>;
  ValueGetter<String> get valueStringGetter => varNotifier.valueStringAs<V>; // default valueStringifier
  ValueGetter<bool> get statusErrorGetter => () => varNotifier.statusIsError;
  ValueGetter<Enum?> get statusEnumGetter => () => varNotifier.status.enumId;
  ValueGetter<VarStatus> get statusGetter => () => varNotifier.status;

  V get viewValue => varNotifier.valueAs<V>();
  num? get valueMin => varNotifier.viewMin;
  num? get valueMax => varNotifier.viewMax;
  ({num max, num min})? get valueNumLimits => varNotifier.varKey.valueNumLimits;

  Stringifier<V> get valueStringifier => varNotifier.varKey.stringify<V>; // can be used to generate value labels for values other than the current value
  bool get isReadOnly => varNotifier.varKey.isReadOnly;
  String? get tip => varNotifier.varKey.tip;
}

abstract mixin class VarEventViewer<V> {
  const VarEventViewer();

  VarEventController get varController;
  @protected
  ValueNotifier<VarViewEvent?> get eventNotifier => varController.eventNotifier; // for UI triggered updates
  ValueSetter<V> get valueSubmitted => varController.submitByViewAs<V>; // onSubmit. only for updates requesting write and/or indicating user confirmation. using scheduled write

  // directly return response
  // ValueSetter<V> get valueSetter => isConnected ? submitAndWrite : submitByView; // non scheduled
  // Future<Null> _asyncSubmitByView(V value) async {
  //   submitByView(value);
  //   return null;
  // }
  // // AsyncValueSetter<V> get asyncValueSetter => isConnected ? setAndSend : _setAsFuture;
  // Future<S?> Function(V value) get valueResponseSetter => isConnected ? submitAndWrite : _asyncSubmitByView;
}

// alternatively extend ListenableBuilder directly
// class VarBuilder extends StatelessWidget {
//   const VarBuilder({required this.varNotifier, required this.valueBuilder, super.key});

//   // VarBuilder.byKey({required this.varNotifierKey, required this.builder, varController, super.key});
//   final VarNotifier varNotifier;
//  final Widget Function(VarNotifier) varBuilder;

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(listenable: varNotifier, builder: valueBuilder, child: const Text('Placeholder'));
//   }
// }

// class VarEventBuilder extends StatelessWidget {
//   const VarEventBuilder({super.key, required this.varController, required this.eventBuilder, this.child});

//   final VarEventController varController;
//   final TransitionBuilder eventBuilder; // the wrapping widget, reactive to events
//   final Widget? child; // the var widget

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(listenable: varController.eventNotifier, builder: eventBuilder, child: child);
//   }
// }

/// Retrieves VarNotifier/Controller using VarKey via InheritedWidget/BuildContext
/// if the callers context/class does not directly contain the VarCache,
/// [VarContext] and [VarKeyContext] must be provided.
class VarKeyBuilder extends StatelessWidget {
  const VarKeyBuilder(this.varKey, this.builder, {super.key});
  const VarKeyBuilder.withType(this.varKey, Widget Function<G>(VarNotifier<G>) builder, {super.key}) : builder = builder;

  final VarKey varKey;
  final Widget Function(VarNotifier) builder;

  // handle union of Function<G>(VarNotifier) and Function(VarNotifier)
  Widget effectiveBuilder<G>(VarNotifier varNotifier) {
    if (builder case Widget Function<G>(VarNotifier) genericBuilder) {
      return genericBuilder<G>(varNotifier);
    } else {
      return builder(varNotifier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cacheController = VarContext.ofKey(context, varKey).controller;
    final varNotifier = cacheController.cache.allocate(varKey);
    return varKey.viewType.callWithType(<G>() => effectiveBuilder<G>(varNotifier));
  }

  // Widget buildWithKey(BuildContext context, VarKey value, Widget? child) {
  //   return VarKeyBuilder(value, builder);
  //   return builder(varController);
  // }

  // ValueWidgetBuilder<VarKey> asValueWidgetBuilder() => buildWithKey;
}

// allocate Var and Controller
class VarKeyEventBuilder extends StatelessWidget {
  const VarKeyEventBuilder({super.key, required this.varKey, required this.eventBuilder, this.child});

  final VarKey varKey;
  // final Widget Function<G>(VarNotifier, Child) builder;
  final TransitionBuilder eventBuilder; // the wrapping widget, reactive to events
  final Widget? child; // the var widget
  // final T eventMatch;

  @override
  Widget build(BuildContext context) {
    final cacheController = VarContext.ofKey(context, varKey).controller;
    final varNotifier = cacheController.cache.allocate(varKey);
    final varController = VarEventController(cacheController: cacheController, varNotifier: varNotifier); // this is allocated in build. dispose will be passed onto ListenableBuilder

    return ListenableBuilder(listenable: varController.eventNotifier, builder: eventBuilder, child: child);
  }
}

/// creates the ValueWidgetBuilder<VarKey> using a widget constructor 'Widget Function(VarNotifier)'
// extension type VarKeyWidgetBuilder._(ValueWidgetBuilder<VarKey?> _builder) {
//   VarKeyWidgetBuilder(Widget Function(VarNotifier) constructor) : this._((context, value, child) => VarKeyBuilder(value! /* ?? VarKey.undefined */, <G>(varNotifier) => constructor(varNotifier)));
//   VarKeyWidgetBuilder.withType(Widget Function<G>(VarNotifier) constructor) : this._((context, value, child) => VarKeyBuilder(value! /* ?? VarKey.undefined */, constructor));
// }
