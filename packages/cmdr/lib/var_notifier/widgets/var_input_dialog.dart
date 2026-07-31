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
          if (varNotifier.varKey.dependents != null) ...[
            const Text('The following values have been updated:\n'),
            Text(dependentsString(varNotifier.varKey), textAlign: TextAlign.left),
          ],
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
