import 'package:flutter/material.dart';

import '../../widgets/dialog/dialog_anchor.dart';
import '../var_notifier.dart';

class VarNoticeDialog extends StatelessWidget {
  const VarNoticeDialog({
    super.key,
    required this.child,
    required this.varNotifier,
    required this.varCache,
    required this.eventNotifier,
    this.beginEditMessage,
    this.endEditMessage,
    this.onSubmitted,
    // this.displayCondition,
  });

  final VarNotifier varNotifier;
  final VarCache varCache;
  final VarEventNotifier eventNotifier; // notify on submit
  final ValueSetter<VarNotifier>? onSubmitted;

  final Widget child; // caller may map child callbacks to the same event controller

  final ValueGetter<String?>? beginEditMessage;
  final ValueGetter<String?>? endEditMessage;

  static const String initialMessageDefault = 'Are you sure you want to continue?';
  static const String finalMessageDefault = 'You have completed editing this field.';

  // ValueGetter<bool>? displayCondition;
  // Widget? title,
  // Widget? content,
  // optionally include onpop

  // on first time focus
  Widget initialDialog(BuildContext context) {
    // final theme = Theme.of(context);
    return AlertDialog(
      // title: const Text('Edit'),
      title: Text(varNotifier.varKey.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          Text(beginEditMessage?.call() ?? initialMessageDefault),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
    );
  }

  // on submit
  // if (value == VarViewEvent.submit) matching handled by DialogAnchor
  Widget eventDialog(BuildContext context, void _, Widget? child) {
    return AlertDialog(
      // title: const Text('Completed Editing'),
      title: Text(varNotifier.varKey.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          Text(endEditMessage?.call() ?? finalMessageDefault),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (beginEditMessage == null && endEditMessage == null) return child;

    // DialogAnchor handles dispose / remove listener
    return DialogAnchor<void>(
      // displayCondition: displayCondition,
      eventNotifier: eventNotifier,
      initialDialogBuilder: initialDialog,
      eventDialogBuilder: eventDialog,
      // eventMatch: VarViewEvent.submit,
      child: child,
    );
  }
}
