import 'package:flutter/material.dart';

import '../../widgets/dialog/dialog_anchor.dart';
import '../var_notifier.dart';

/// [VarInputDialog] - Wraps [child] with dialogs shown on first focus and/or on submit.
///
/// The message parameters control whether each dialog appears:
///  - [beginEditMessage] resolving non-null shows a dialog the first time [child] gains focus.
///  - [endEditMessage] resolving non-null shows a dialog when [varNotifier] is submitted by the view.
///
/// A getter that resolves to null opts that [VarNotifier] out of the corresponding dialog. When
/// both resolve null, [child] is returned unwrapped. [DialogAnchor] supplies the focus/event plumbing.
///
/// Both dialogs are driven by state already on [varNotifier]: the focus dialog by [child]'s focus,
/// the submit dialog by [VarValueNotifier.isLastUpdateByView].
class VarInputDialog extends StatelessWidget {
  const VarInputDialog({
    super.key,
    required this.child,
    required this.varNotifier,
    this.beginEditMessage,
    this.endEditMessage,
    // final ValueSetter<VarNotifier<V>> onEvent
  });

  final VarNotifier varNotifier;
  final Widget child;

  final ValueGetter<String?>? beginEditMessage; // shown on first focus when it resolves non-null
  final ValueGetter<String?>? endEditMessage; // shown on submit when it resolves non-null

  // final ValueSetter<VarNotifier<V>> onSubmit;

  Widget _dialog(BuildContext context, String message) {
    return AlertDialog(
      title: Text(varNotifier.varKey.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const Divider(), Text(message)],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? beginMessage = beginEditMessage?.call();
    final String? endMessage = endEditMessage?.call();
    if (beginMessage == null && endMessage == null) return child;

    // DialogAnchor handles focus tracking and listener dispose/removal.
    // [varNotifier] notifies on both a view submit and a server update; a pending view value is what
    // distinguishes the submit, as [updateByData] does not notify while one is pending. Matching on
    // the transition keeps the status ack that follows a submit from reopening the dialog.
    return DialogAnchor<bool>(
      eventNotifier: varNotifier,
      eventGetter: () => varNotifier.isLastUpdateByView,
      eventMatch: true,
      initialDialogBuilder: beginMessage == null ? null : (context) => _dialog(context, beginMessage),
      eventDialogBuilder: endMessage == null ? null : (context, _, _) => _dialog(context, endMessage),
      child: child,
    );
  }
}
