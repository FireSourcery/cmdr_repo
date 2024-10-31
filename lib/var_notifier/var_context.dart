import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../common/basic_types.dart';
import '../common/service_io.dart';
import 'var_notifier.dart';

/// Maps VarKey to VarController or sub-VarContext which contains VarCacheController
/// There can only be 1 KeyContext Type. Any number of instances can exist in the Widget tree.
///
/// this way VarKey does not need to include context as dependency
final class VarKeyContext extends InheritedWidget {
  const VarKeyContext({super.key, required this.contextTypeOfVarKey, required super.child});

  static VarKeyContext? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VarKeyContext>();
  }

  static VarKeyContext of(BuildContext context) {
    final VarKeyContext? result = maybeOf(context);
    assert(result != null, 'No $VarKeyContext found in context');
    return result!;
  }

  /// Control type properties
  // effectively provides varKey.contextType
  // without directly including type in VarKey, as that results in dependency of view layer
  final TypeKey<VarContext> Function(VarKey) contextTypeOfVarKey;

  // controllers per keycontext, no search by context type
  // // holds the cache allocations
  // // CacheControllerType to CacheController
  // final Map<Type, VarCacheController> controllers;

  // // although its possible to map from key to controller, this way enforces a condensed map
  // // as well as provide an additional way of accessing the controller via `controller<T extends VarCacheController>()`
  // final TypeKey<VarCacheController> Function(VarKey) controllerTypeOfVarKey;

  // T? controller<T extends VarCacheController>() => controllers[T] as T?;
  // // returned controller is the type determined by the varKey. caller cast to sub type for subtype methods
  // VarCacheController? controllerOf(VarKey varKey) => controllerTypeOfVarKey(varKey).callWithRestrictedType(controller);

  @override
  bool updateShouldNotify(covariant VarKeyContext oldWidget) => false;
}

/// For additional sub contexts
abstract class VarContext extends InheritedWidget {
  const VarContext({super.key, required this.controller, required super.child});

  static T? maybeOf<T extends VarContext>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<T>();
  }

  static T of<T extends VarContext>(BuildContext context) {
    final T? result = maybeOf<T>(context);
    assert(result != null, 'No $T found in context');
    return result!;
  }

  /// this method requires [VarKeyContext] to be provided
  static VarContext ofKey(BuildContext context, VarKey varKey) {
    return VarKeyContext.of(context).contextTypeOfVarKey(varKey).callWithRestrictedType(<G extends VarContext>() => VarContext.of<G>(context) as VarContext);
  }

  final VarCacheController controller;

  @override
  bool updateShouldNotify(covariant VarContext oldWidget) => controller != oldWidget.controller;
}

// /// 2 types by default. RealTime and Settings
// // Real-Time Vars use VarRealTimeController
class VarRealTimeContext extends VarContext {
  const VarRealTimeContext({super.key, required VarRealTimeController super.controller, required super.child});

  // static T of<T extends VarRealTimeContext>(BuildContext context) => VarContext.of<T>(context);

  @override
  VarRealTimeController get controller => super.controller as VarRealTimeController;
}

// // Configuration Vars use base VarCacheController
// class VarConfigContext extends VarContext {
//   const VarConfigContext({super.key, required super.controller, required super.child});

//   static T of<T extends VarConfigContext>(BuildContext context) => VarContext.of<T>(context);
// }

// extension type const VarMapper(VarKey key) {
//   // todo derive context type from key
//   VarNotifier varFrom(BuildContext context) {
//     return switch (key) {
//       VarKey(isRealTime: true) => VarRealTimeContext.of(context).controller.cache.allocate(key),
//       VarKey(isConfig: true) => VarConfigContext.of(context).controller.cache.allocate(key),
//       VarKey(isConfig: false, isRealTime: false) => throw TypeError(),
//     };
//   }
// }

// extension VarKeyMapper on VarKey {
//   VarNotifier varFrom(BuildContext context) {
//     return contextType.callWithRestrictedType(<G extends VarContext>() => VarContext.of<G>(context) as VarContext).controller.cache.allocate(this);
//   }
// }

// extension VarNotifierContext on BuildContext {
//   VarRealTimeViewer get realTimeViewer => VarRealTimeContext.of(this).controller;
//   VarSettingsViewer get settingsViewer => VarSettingsContext.of(this).controller;
// }
