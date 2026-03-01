import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:binary_data/data/basic_types.dart';

import '../var_context.dart';
import '../var_notifier.dart';

/// Widget tools

class VarKeyBuilder extends StatelessWidget {
  const VarKeyBuilder(this.varKey, this.builder, {this.varCache, super.key});

  final Widget Function(VarNotifier) builder;
  final VarKey varKey;
  final VarCache? varCache;

  @override
  Widget build(BuildContext context) {
    final varNotifier = varCache?.resolve(varKey) ?? VarContext.ofKey(context, varKey).repo.cache.resolve(varKey);
    return builder(varNotifier);
  }
}

// alternatively caller handle get cache from context
/// Retrieves VarNotifier/Controller using VarKey via InheritedWidget/BuildContext
/// if the callers context/class does not directly contain the VarCache,
/// [VarContext] and [VarKeyContext] must be provided.
class VarKeyContextBuilder extends StatelessWidget {
  const VarKeyContextBuilder(this.varKey, this.builder, {super.key});
  // const VarKeyContextBuilder.typed(this.varKey, Widget Function<G>(VarNotifier) builder, {super.key}) : builder = builder;

  final VarKey varKey;
  final Widget Function(VarNotifier) builder;

  @override
  Widget build(BuildContext context) {
    final varNotifier = VarContext.ofKey(context, varKey).repo.cache.resolve(varKey);
    return builder(varNotifier);
  }
}

class VarKeyContextBuilderWithType extends StatelessWidget {
  const VarKeyContextBuilderWithType(this.varKey, this.builder, {super.key});

  final VarKey varKey;
  final Widget Function<G>(VarNotifier) builder;

  @override
  Widget build(BuildContext context) {
    final varNotifier = VarContext.ofKey(context, varKey).repo.cache.resolve(varKey);
    return varKey.viewType.callWithType(<G>() => builder<G>(varNotifier as VarNotifier<G>));
    // return VarBaseBuilderWithType(VarContext.ofKey(context, varKey).cacheController.cache.allocate(varKey), builder);
  }
}

// generialzed input dialog
// rebuild on event match, if not included in the target widget
// allocate Var Controller
// class VarEventBuilder extends StatelessWidget {
//   const VarEventBuilder({super.key, required this.eventNotifier, required this.builder, this.child, required this.eventMatch});

//   // final VarNotifier varNotifier;
//   // final VarCache varCache;
//   // final VarEventNotifier? eventNotifier; // make this required
//   // final ValueSetter<VarNotifier>? onSubmitted;

//   // final VarKey varKey;
//   final VarEventController eventNotifier;

//   // final Widget Function<G>(VarNotifier, child) builder;
//   final TransitionBuilder builder; // the wrapping widget, reactive to events, pass eventController to builder?
//   final Widget? child; // the var widget
//   final VarViewEvent eventMatch;

//   Widget _eventBuilder(BuildContext context, VarViewEvent? event, Widget? initialBuild) {
//     if (event == eventMatch) return builder(context, child); // also pass event back to builder?
//     return initialBuild!;
//   }

//   @override
//   Widget build(BuildContext context) {
//     // final varNotifier = cacheController.cache.allocate(varKey);
//     // final eventNotifier = VarEventController(cacheController: cacheController, varNotifier: varNotifier); // this is allocated in build. dispose will be passed onto ListenableBuilder

//     // return ListenableBuilder(listenable: eventNotifier.eventNotifier, builder: eventBuilder, child: child);
//     return ValueListenableBuilder<VarViewEvent?>(
//       valueListenable: eventNotifier,
//       builder: _eventBuilder,
//       child: builder(context, child), // initialBuild
//     );
//   }
// }

/// resolve if the builder is a generic builder
class VarBaseBuilder extends StatelessWidget {
  const VarBaseBuilder(this.varNotifier, this.builder, {super.key});
  const VarBaseBuilder.typed(this.varNotifier, Widget Function<G>(VarNotifier) builder, {super.key}) : builder = builder;

  final VarNotifier<dynamic> varNotifier;

  /// May be of type Widget Function<G>(VarNotifier value)
  final Widget Function(VarNotifier) builder;

  @override
  Widget build(BuildContext context) {
    if (builder case Widget Function<G>(VarNotifier) builder) {
      return varNotifier.varKey.viewType.callWithType(<G>() => builder<G>(varNotifier));
    } else {
      return builder(varNotifier);
    }
  }
}

// class VarBaseBuilder extends StatelessWidget {
//   VarBaseBuilder(this.varNotifier, this.builder, {super.key});

//   final VarNotifier<dynamic> varNotifier;
//   final Widget Function(VarNotifier) builder;
//   @override
//   Widget build(BuildContext context) => builder(varNotifier);
// }

// class VarBaseBuilderWithType extends StatelessWidget {
//   const VarBaseBuilderWithType(this.varNotifier, this.builder, {super.key});

//   final VarNotifier<dynamic> varNotifier;
//   final Widget Function<G>(VarNotifier value) builder;

//   @override
//   Widget build(BuildContext context) {
//     return varNotifier.varKey.viewType.callWithType(<G>() => builder<G>(varNotifier as VarNotifier<G>));
//   }
// }

// combining logic by deferring until build
// alternatively, use a interface Widget.
// class VarSuperBuilder extends StatelessWidget {
//   const VarSuperBuilder({super.key, required this.varNotifier, required this.builder}) : varKey = null;
//   const VarSuperBuilder.byKey({super.key, required this.varKey, required this.builder}) : varNotifier = null;
//   const VarSuperBuilder.resolve({super.key, required this.varKey, required this.builder}) : varNotifier = null;

//   final VarKey? varKey;
//   final VarNotifier<dynamic>? varNotifier;
//   final Widget Function(VarNotifier) builder;
// //   final VarEventController? eventController;

//   @override
//   Widget build(BuildContext context) {
//     final effectiveVarNotifier = varNotifier ?? VarContext.ofKey(context, varKey!).cacheController.cache.allocate(varKey!);
//     return VarBaseBuilder(effectiveVarNotifier, builder);
//   }
// }

////////////////////////////////////////////////////////////////////////////////
/// convenience interface for mapping widget callbacks
////////////////////////////////////////////////////////////////////////////////
/// implicitly casts the VarNotifier
/// getters preferred over config object, as the widget can select which callbacks are retained
// extension VarNotifierViewer<V> on VarNotifier {
//   // const VarNotifierViewer();
//   //   _VarWidgetSource.assertType(this.eventNotifier) : assert(eventNotifier.varNotifier.varKey.viewType.isExactType<T>());

//   @protected
//   VarNotifier<dynamic> get varNotifier => this;
//   // VarEventController? get eventController;

//   ValueNotifier<dynamic> get valueNotifier => varNotifier; // for value updates
//   ValueChanged<V> get valueChanged => varNotifier.updateByViewAs<V>; // onChange. call for all updates to update UI

//   // Anonymous functions defined this way should not be reallocated
//   ValueGetter<V> get valueGetter => varNotifier.valueAs<V>;
//   ValueGetter<String> get valueStringGetter => varNotifier.valueStringAs<V>; // default valueStringifier
//   ValueGetter<bool> get statusErrorGetter => (() => varNotifier.statusIsError);
//   ValueGetter<Enum?> get statusEnumGetter => (() => varNotifier.status.enumId);
//   ValueGetter<VarStatus> get statusGetter => (() => varNotifier.status);

//   V get viewValue => varNotifier.valueAs<V>();
//   ({num max, num min})? get valueNumLimits => varNotifier.varKey.valueNumLimits;

//   Stringifier<V> get valueStringifier => varNotifier.varKey.stringify<V>; // can be used to generate value labels for values other than the current value
//   bool get isReadOnly => varNotifier.varKey.isReadOnly;
//   String? get tip => varNotifier.varKey.tip;

//   // ValueSetter<V> get valueSubmitted => cache.eventController.submitByViewAs<V>; // onSubmit. only for updates requesting write and/or indicating user confirmation. using scheduled write
// }
