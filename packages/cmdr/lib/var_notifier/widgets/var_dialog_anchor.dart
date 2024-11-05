import 'package:flutter/material.dart';

import '../../widgets/dialog/dialog_widgets.dart';
import '../var_notifier.dart';
import '../var_widget.dart';

// class VarNotifierEditDialog extends StatelessWidget {
//   const VarNotifierEditDialog({super.key, required this.child, required this.varNotifier, required this.controller});

//   final VarNotifier varNotifier;
//   final VarCacheController controller;
//   final Widget child; // io field most cases

//   @override
//   Widget build(BuildContext context) {
//     final VarEventController eventController = VarEventController(cacheController: controller, varNotifier: varNotifier);

//     return DialogAnchor<VarViewEvent>(
//       eventNotifier: eventController.eventNotifier,
//       initialSelectDialog: AlertDialog(
//         title: Text('Edit ${varNotifier.varKey.label}'),
//         content: Column(
//           children: [
//             Text(varNotifier.varKey.warningOnSet ?? ''), // todo move to config or include edit message as part of varKey common interface
//           ],
//         ),
//         actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
//       ),
//       eventDialogBuilder: (context, value) {
//         // if (value == VarViewEvent.submit) {
//         return AlertDialog(
//           title: Text('Edit ${varNotifier.varKey.label}'),
//           content: Column(
//             children: [
//               Text(varNotifier.varKey.warningOnComplete ?? ''),

//               /// list dependent values
//             ],
//           ),
//           actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
//         );
//         // }
//       },
//       eventGetter: () => eventController.eventNotifier.value,
//       child: child,
//     );
//   }
// }
