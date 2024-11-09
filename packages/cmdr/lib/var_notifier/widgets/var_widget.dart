import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:cmdr_common/basic_types.dart';

import '../var_context.dart';
import '../var_notifier.dart';

/// Widget tools

////////////////////////////////////////////////////////////////////////////////
/// Widget Interface
/// convenience interface for mapping widget callbacks
////////////////////////////////////////////////////////////////////////////////
/// implicitly casts the VarNotifier
///
/// getters preferred over config object, as the widget can select which callbacks are retained
/// as a mixin allows for use as interface
abstract mixin class VarNotifierViewer<V> {
  const VarNotifierViewer();
//   _VarWidgetSource.assertType(this.eventNotifier) : assert(eventNotifier.varNotifier.varKey.viewType.isExactType<T>());

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

  VarEventController get eventController;
  @protected
  ValueNotifier<VarViewEvent?> get eventNotifier => eventController; // for UI triggered updates
  ValueSetter<V> get valueSubmitted => eventController.submitByViewAs<V>; // onSubmit. only for updates requesting write and/or indicating user confirmation. using scheduled write

  // directly return response
  // ValueSetter<V> get valueSetter => isConnected ? submitAndWrite : submitByView; // non scheduled
  // Future<Null> _asyncSubmitByView(V value) async {
  //   submitByView(value);
  //   return null;
  // }
  // // AsyncValueSetter<V> get asyncValueSetter => isConnected ? setAndSend : _setAsFuture;
  // Future<S?> Function(V value) get valueResponseSetter => isConnected ? submitAndWrite : _asyncSubmitByView;
}

/// Retrieves VarNotifier/Controller using VarKey via InheritedWidget/BuildContext
/// if the callers context/class does not directly contain the VarCache,
/// [VarContext] and [VarKeyContext] must be provided.
class VarKeyBuilder extends StatelessWidget implements VarBuilder {
  const VarKeyBuilder(this.varKey, this.builder, {super.key});
  const VarKeyBuilder.typed(this.varKey, Widget Function<G>(VarNotifier) builder, {super.key}) : builder = builder;

  final VarKey varKey;
  final Widget Function(VarNotifier) builder;

  // handle union of Function<G>(VarNotifier) and Function(VarNotifier)
  Widget effectiveBuilder<G>(VarNotifier varNotifier) {
    if (builder case Widget Function<G>(VarNotifier<G>) genericBuilder) {
      return genericBuilder<G>(varNotifier as VarNotifier<G>);
    } else {
      return builder(varNotifier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cacheController = VarContext.ofKey(context, varKey).cacheController;
    final varNotifier = cacheController.cache.allocate(varKey);
    return varKey.viewType.callWithType(<G>() => effectiveBuilder<G>(varNotifier));
  }

  // Widget buildWithKey(BuildContext context, VarKey value, Widget? child) {
  //   return VarKeyBuilder(value, builder);
  //   return builder(eventNotifier);
  // }

  // ValueWidgetBuilder<VarKey> asValueWidgetBuilder() => buildWithKey;
}

// combining logic by deferring until build
// alternatively, use a interface Widget.
// class VarBuilder extends StatelessWidget {
//   const VarBuilder({super.key, required this.varNotifier, required this.builder}) : varKey = null;
//   const VarBuilder.byKey({super.key, required this.varKey, required this.builder}) : varNotifier = null;

//   final VarKey? varKey;
//   final VarNotifier? varNotifier;
//   final Widget Function(VarNotifier) builder;

//   @override
//   Widget build(BuildContext context) {
//     final varNotifier_ = switch ((varKey, varNotifier)) {
//       (VarKey key, null) => VarContext.ofKey(context, key).controller.cache.allocate(key),
//       (null, VarNotifier notifier) => notifier,
//       (null, null) => throw StateError('VarKey and VarNotifier cannot be both null'),
//       (VarKey(), VarNotifier()) => throw StateError('VarKey and VarNotifier cannot be both defined'),
//     };

//     return builder(varNotifier_);
//   }
// }

abstract mixin class VarBuilder implements StatelessWidget {
  factory VarBuilder(VarNotifier varNotifier, Widget Function(VarNotifier) builder) = _VarBuilder;
  factory VarBuilder.byKey(VarKey varKey, Widget Function(VarNotifier) builder) = VarKeyBuilder;
}

class _VarBuilder extends StatelessWidget implements VarBuilder {
  const _VarBuilder(this.varNotifier, this.builder, {super.key});
  const _VarBuilder.typed(this.varNotifier, Widget Function<G>(VarNotifier<G>) builder, {super.key}) : builder = builder;

  final VarNotifier<dynamic> varNotifier;
  final Widget Function(VarNotifier) builder;

  // late final Widget Function() _effectiveBuilder = switch (builder) {
  //   Widget Function<G>(VarNotifier<G>) _ => _buildGeneric,
  //   Widget Function(VarNotifier) _ => _build,
  // };
  // Widget _buildGeneric() => varNotifier.varKey.viewType.callWithType(<G>() => builder<G>(varNotifier as VarNotifier<G>));
  // Widget _build() => builder(varNotifier);

  @override
  Widget build(BuildContext context) {
    // handle union of Function<G>(VarNotifier) and Function(VarNotifier)
    if (builder case Widget Function<G>(VarNotifier) genericBuilder) {
      return varNotifier.varKey.viewType.callWithType(<G>() => genericBuilder<G>(varNotifier as VarNotifier<G>));
    } else {
      return builder(varNotifier);
    }
  }
}

// rebuild on event match, if not included in the target widget
// allocate Var Controller
class VarEventBuilder extends StatelessWidget {
  const VarEventBuilder({super.key, required this.eventNotifier, required this.builder, this.child, required this.eventMatch});

  // final VarKey varKey;
  final VarEventController eventNotifier;

  // final Widget Function<G>(VarNotifier, child) builder;
  final TransitionBuilder builder; // the wrapping widget, reactive to events, pass eventController to builder?
  final Widget? child; // the var widget
  final VarViewEvent eventMatch;

  Widget _eventBuilder(BuildContext context, VarViewEvent? event, Widget? initialBuild) {
    if (event == eventMatch) return builder(context, child); // also pass event back to builder?
    return initialBuild!;
  }

  @override
  Widget build(BuildContext context) {
    // final cacheController = VarContext.ofKey(context, varKey).controller;
    // final varNotifier = cacheController.cache.allocate(varKey);
    // final eventNotifier = VarEventController(cacheController: cacheController, varNotifier: varNotifier); // this is allocated in build. dispose will be passed onto ListenableBuilder

    // return ListenableBuilder(listenable: eventNotifier.eventNotifier, builder: eventBuilder, child: child);
    return ValueListenableBuilder<VarViewEvent?>(
      valueListenable: eventNotifier,
      builder: _eventBuilder,
      child: builder(context, child), // initialBuild
    );
  }
}

/// creates the ValueWidgetBuilder<VarKey> using a widget constructor 'Widget Function(VarNotifier)'
// extension type VarKeyWidgetBuilder._(ValueWidgetBuilder<VarKey?> _builder) {
//   VarKeyWidgetBuilder(Widget Function(VarNotifier) constructor) : this._((context, value, child) => VarKeyBuilder(value! /* ?? VarKey.undefined */, <G>(varNotifier) => constructor(varNotifier)));
//   VarKeyWidgetBuilder.withType(Widget Function<G>(VarNotifier) constructor) : this._((context, value, child) => VarKeyBuilder(value! /* ?? VarKey.undefined */, constructor));
// }
