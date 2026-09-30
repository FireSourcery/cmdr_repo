import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'var_notifier.dart';

/// Get [VarCacheController] via Context
/// For library side to include widgets find key type
///
// abstract class VarContext<T extends VarContext<dynamic>> extends InheritedWidget { //alternatively pass parameter type
abstract class const VarContext({super.key, required final VarCacheController repo, required super.child}) extends InheritedWidget {
  /// `T extends VarContext`
  static T? maybeOf<T extends VarContext>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<T>();
  }

  static T of<T extends VarContext>(BuildContext context) {
    final T? result = maybeOf<T>(context);
    assert(result != null, 'No $T found in context');
    return result!;
  }

  /// this method requires [VarKeyContext] to be provided
  /// Alternatively, caller can directly use [VarContext.of<G>(context)] to find the controller context by type
  static VarContext ofKey(BuildContext context, VarKey varKey) {
    return VarKeyContext.of(context).contextTypeOfVarKey(varKey).callWithRestrictedType(<G extends VarContext>() => VarContext.of<G>(context));
  }

  @override
  bool updateShouldNotify(covariant VarContext oldWidget) => repo != oldWidget.repo;
}

/// additional sub type containing [VarStreamController]
class const VarRealTimeContext({super.key, required VarStreamController super.repo, required super.child}) extends VarContext {
  @override
  VarStreamController get repo => super.repo as VarStreamController;
}

/// Maps VarKey to VarController or sub-VarContext which contains VarCacheController
/// For Library side interfaces: There can only be 1 KeyContext Type. Any number of instances can exist in the Widget tree.
///
/// this way VarKey does not need to include context as dependency
final class const VarKeyContext({super.key, 
  /// User provides function - using control type properties to determine the [VarContext] and [VarCacheController] type
  // effectively provides varKey.contextType, without directly including type in VarKey, as that results in dependency of view layer
  /// slight workaround for `T extends VarContext`
  required final TypeRestrictedKey<VarContext, VarContext> Function(VarKey) contextTypeOfVarKey, required super.child}) extends InheritedWidget {
  static VarKeyContext? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VarKeyContext>();
  }

  static VarKeyContext of(BuildContext context) {
    final VarKeyContext? result = maybeOf(context);
    assert(result != null, 'No $VarKeyContext found in context');
    return result!;
  }

  // Alternatively, controllers per keyContext, instead of search by context type
  // holds the cache allocations
  // VarCacheController Type to CacheController
  // final Map<Type, VarCacheController> controllers;
  // T? controller<T extends VarCacheController>() => controllers[T] as T?;

  @override
  bool updateShouldNotify(covariant VarKeyContext oldWidget) => false;
}

// extension VarKeyMapper on VarKey {
//   VarNotifier varFrom(BuildContext context) => VarContext.ofKey(context, this).repo.cache.resolve(this);
// }

// extension VarNotifierContext on BuildContext {
//   VarCacheController varController<T extends VarContext>() => VarContext.of<T>(this).repo;
// }
