import 'package:flutter/material.dart';

import '../../widgets/dialog/dialog_anchor.dart';
import '../var_notifier.dart';

// dependents dialog
class VarInputDialog extends StatelessWidget {
  const VarInputDialog({
    super.key,
    required this.child,
    required this.varNotifier,
    required this.varCache,
    required this.eventNotifier,
    this.beginEditMessage = initialMessageDefault,
    this.endEditMessage = finalMessageDefault,
    this.onSubmitted,
    // this.displayCondition,
  });

  final VarNotifier varNotifier;
  final VarCache varCache;
  final VarEventNotifier eventNotifier;
  final ValueSetter<VarNotifier>? onSubmitted;

  final Widget child; // caller may map child callbacks to the same event controller

  final String? beginEditMessage;
  final String? endEditMessage;

  static const String initialMessageDefault = 'Are you sure you want to continue?';
  static const String finalMessageDefault = 'You have completed editing this field.';

  // ValueGetter<bool>? displayCondition;
  // Widget? title,
  // Widget? content,
  // optionally include onpop

  String dependentsString(VarKey varKey, [String prefix = '', String divider = ': ', String separator = '\n']) {
    return (StringBuffer(prefix)
          ..writeAll(varCache.dependentsOf(varNotifier.varKey).namedValues.map((e) => '${e.$1}$divider${e.$2}'), separator)
          ..writeln(''))
        .toString();
  }

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
          // Text(beginEditMessage ?? ''),
          if (varNotifier.varKey.dependents != null) ...[
            const Text('The following values will be updated:\n'),
            // Text(varCache.dependentsString(varNotifier.varKey), textAlign: TextAlign.left),
            Text(dependentsString(varNotifier.varKey), textAlign: TextAlign.left),
          ],
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
    );
  }

  // on submit
  // if (value == VarViewEvent.submit) matching handled by DialogAnchor
  Widget eventDialog(BuildContext context, void _, Widget? child) {
    final theme = Theme.of(context);
    return AlertDialog(
      // title: const Text('Completed Editing'),
      title: Text(varNotifier.varKey.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          // Text(endEditMessage ?? ''),
          if (varNotifier.varKey.dependents != null) ...[const Text('The following values have been updated:\n'), Text(dependentsString(varNotifier.varKey), textAlign: TextAlign.left)],
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
    );
  }

  @override
  Widget build(BuildContext context) {
    // final effectiveEventNotifier = eventNotifier ?? VarEventNotifier(onSubmitted: onSubmitted!, varNotifier: varNotifier); // DialogAnchor handles dispose / remove listener

    if (varNotifier.varKey.dependents != null) {
      // change to conditional
      return DialogAnchor<void>(
        // displayCondition: displayCondition,
        eventNotifier: eventNotifier,
        initialDialogBuilder: initialDialog,
        eventDialogBuilder: eventDialog,
        // eventMatch: VarViewEvent.submit,
        child: child,
      );
    }
    return child;
  }
}
