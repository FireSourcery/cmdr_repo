import 'package:flutter/material.dart';

import '../../widgets/dialog/dialog_anchor.dart';
import '../var_notifier.dart';

/// [VarInputDialog] - Wraps [child] with dialogs shown on first focus and/or on submit.
///
/// The message parameters control whether each dialog appears:
///  - [beginEditMessage] resolving non-null shows a dialog the first time [child] gains focus.
///  - [endEditMessage] resolving non-null shows a dialog when [eventNotifier] fires (submit).
///
/// A getter that resolves to null opts that [VarNotifier] out of the corresponding dialog. When
/// both resolve null, [child] is returned unwrapped. [DialogAnchor] supplies the focus/event plumbing.
///
/// [eventNotifier] is only needed for the submit ([endEditMessage]) dialog; the focus dialog is
/// driven by [child]'s focus.
class VarInputDialog extends StatelessWidget {
  const VarInputDialog({
    super.key,
    required this.child,
    required this.varNotifier,
    this.eventNotifier,
    this.beginEditMessage,
    this.endEditMessage,
  });

  final VarNotifier varNotifier;
  final VarEventNotifier? eventNotifier; // notifies on submit; only needed for the submit dialog
  final Widget child; // caller may map child callbacks to the same event controller

  final ValueGetter<String?>? beginEditMessage; // shown on first focus when it resolves non-null
  final ValueGetter<String?>? endEditMessage; // shown on submit when it resolves non-null

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
    return DialogAnchor<void>(
      eventNotifier: eventNotifier,
      initialDialogBuilder: beginMessage == null ? null : (context) => _dialog(context, beginMessage),
      eventDialogBuilder: endMessage == null ? null : (context, _, _) => _dialog(context, endMessage),
      child: child,
    );
  }
}

///
/// [VarEventNotifier]
/// Optional wrapper around a [VarNotifier] providing a separate notifier for UI submit events.
///   - associated with a UI component, instead of the [VarNotifier] value
///   - not triggered by value changes
///   - listeners to the [VarNotifier] value on another UI component are not notified of submit
/// Used by [VarInputDialog] to show a dialog on submit.
class VarEventNotifier<V> extends ChangeNotifier {
  VarEventNotifier({required this.varNotifier, required this.onSubmit});
  final VarNotifier<V> varNotifier; // typed by Key. returning as dynamic.
  final ValueSetter<VarNotifier<V>> onSubmit; // handle additional logic on submit

  void submitByView(V varValue) {
    varNotifier.updateByView(varValue);
    onSubmit(varNotifier);
    notifyListeners();
  }

  void call(Function(VarNotifier<V>) submitAction) {
    submitAction(varNotifier);
    notifyListeners();
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
