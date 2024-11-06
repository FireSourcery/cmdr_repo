import 'package:flutter/material.dart';

import '../../widgets/dialog/dialog_widgets.dart';
import '../var_notifier.dart';
import '../var_widget.dart';

class VarEditDialog extends StatelessWidget {
  const VarEditDialog({
    super.key,
    required this.child,
    required this.varNotifier,
    required this.controller,
    this.beginEditMessage = initialMessageDefault,
    this.endEditMessage = finalMessageDefault,
    ValueGetter<bool>? displayCondition,
  });

  final VarNotifier varNotifier;
  final VarCacheController controller;
  final Widget child; // io field most cases

  final String? beginEditMessage;
  final String? endEditMessage;

  static const String initialMessageDefault = 'Are you sure you want to continue?';
  static const String finalMessageDefault = 'You have completed editing this field.';

  // optionally include onpop

  Widget initialDialog(context) {
    return AlertDialog(
      title: Text('Edit ${varNotifier.varKey.label}'),
      content: Column(
        children: [
          Text(beginEditMessage ?? ''),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
    );
  }

  // if (value == VarViewEvent.submit) matching handled by DialogAnchor
  Widget eventDialog(context, value) {
    return AlertDialog(
      title: Text('Completed Editing ${varNotifier.varKey.label}'),
      content: Column(
        children: [
          Text(endEditMessage ?? ''),

          /// list dependent values
          if (varNotifier.varKey.dependents != null) Text(controller.cache.dependentsString(varNotifier.varKey)),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
    );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final VarEventController eventController = VarEventController(cacheController: controller, varNotifier: varNotifier); // remove listener handled by DialogAnchor

    // change to conditional
    return DialogAnchor<VarViewEvent>(
      eventNotifier: eventController.eventNotifier,
      initialDialogBuilder: initialDialog,
      eventDialogBuilder: eventDialog, // todo need to trigger using childs submit, or decendent notifier
      child: child,
    );
  }
}
