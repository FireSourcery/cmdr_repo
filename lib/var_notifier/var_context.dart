// import 'package:flutter/widgets.dart';

// import '../model/mot_var_key.dart';
// import 'mot_var_parameters_controller.dart';
// import 'mot_var_real_time_controller.dart';

// // extension MotVarKeyMapper on MotVarKey {
// //   MotVar allocateMotVar(BuildContext context) {
// //     return switch (varName) {
// //       MotVarName(isRealTime: true) => VarContext.of(context).controller.allocate(this),
// //       MotVarName(isParameter: true) => MotVarParametersContext.of(context).controller.allocate(this),
// //       MotVarName(isParameter: false, isRealTime: false) => throw TypeError(),
// //     };
// //   }
// // }

// abstract class VarContext extends InheritedWidget {
//   const VarContext({super.key, required this.controller, required super.child});

//   final VarCache controller;

//   // static VarContext? maybeOf(BuildContext context) {
//   //   return context.dependOnInheritedWidgetOfExactType<VarContext>();
//   // }

//   // factory VarContext.of(BuildContext context) {
//   //   final VarContext? result = maybeOf(context);
//   //   assert(result != null, 'No VarContext found in context');
//   //   return result!;
//   // }

//   @override
//   bool updateShouldNotify(covariant VarContext oldWidget) => controller != oldWidget.controller;
// }
