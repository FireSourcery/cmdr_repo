import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'dialog_widgets.dart';

abstract mixin class InputDialog<T> implements Widget {
  // const ConfirmationDialog({super.key, this.onCancel, this.onConfirm, this.title, this.icon, this.iconColor, this.content});
  // final ValueGetter<T>? onCancel;
  // final Widget? title;
  // final Widget? icon;
  // final Color? iconColor;
  // final Widget? content;

  BuildContext get context;
}

class EditWarningDialog extends StatefulWidget {
  const EditWarningDialog({super.key, required this.child, this.warningMessage, this.finalMessage, this.editCompleted, this.userSubmitNotifier});

  // const factory EditWarningDialog._conditional({
  //   required Widget child,
  //   required ValueGetter<bool> displayCondition,
  //   String? warningMessage,
  //   String? finalMessage,
  //   Future? editCompleted,
  //   Key? key,
  // }) = _ConditionalEditWarningDialog;

  factory EditWarningDialog.conditional({
    Key? key,
    ValueGetter<bool>? displayCondition,
    String? warningMessage,
    String? finalMessage,
    Future? editCompleted,
    required Widget child,
  }) {
    if (displayCondition == null) {
      return EditWarningDialog(warningMessage: warningMessage, finalMessage: finalMessage, editCompleted: editCompleted, userSubmitNotifier: null, child: child);
    } else {
      return _ConditionalEditWarningDialog(displayCondition: displayCondition, warningMessage: warningMessage, finalMessage: finalMessage, editCompleted: editCompleted, child: child);
    }
  }

  final Listenable? userSubmitNotifier;

  final Widget child;

  final String? warningMessage;
  final String? finalMessage;

  final Future? editCompleted; // as 1 time listenable

  static const String warningMessageDefault = 'Are you sure you want to continue?';

//   ValueGetter<T>? get onConfirm;

  @override
  State<EditWarningDialog> createState() => _EditWarningDialogState();
}

class _EditWarningDialogState extends State<EditWarningDialog> {
  late final FocusNode _focusNode = FocusNode(); //..addListener(_handleFocusChange);
  bool _focused = false;
  // late FocusAttachment _nodeAttachment;
  // late final Future<void>? _editCompleted = widget.editCompleted?.then((_) => _showEditCompleteDialog());

  // late final Listenable _lostFocus = widget.updated ?? ChangeNotifier();
  // late final Listenable _updated  = Listenable.merge([_updated, _focusNode]);

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _focused) {
      if (!_focused && _focusNode.hasFocus) {
        _showWarningDialog();
        _focused = true;
      } else {
        print('focus lost');
      }
      // _focused = _focusNode.hasFocus;
      // setState(() {});
    }
    // else {
    // complete future if not provided
    // }
  }

  @override
  void initState() {
    super.initState();
    // widget.editCompleted?.then((_) => _showEditCompleteDialog());
    _focusNode.addListener(_handleFocusChange);
    widget.userSubmitNotifier?.addListener(_showEditCompleteDialog);
  }

  @override
  void dispose() {
    widget.userSubmitNotifier?.removeListener(_showEditCompleteDialog);
    _focusNode.dispose();
    super.dispose();
  }

//   Widget get warningDialog {
//     return ConfirmationDialog(
//       title: const Text('Warning'),
//       content: Text(warningMessage ?? warningMessageDefault),
//     );
//   }
  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text('You are about to edit this field.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

//   Widget get finalDialog {
//     return AlertDialog(
//       title: const Text('Complete'),
//       content: Text(finalMessage ?? 'Operation completed successfully'),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop<T>(),
//           child: const Text('OK'),
//         ),
//       ],
//     );
//   }
  void _showEditCompleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Complete'),
          content: const Text('You have completed editing this field.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainWidget = Focus(focusNode: _focusNode, child: widget.child);

    // if (widget.updated != null) {
    //   return ListenableBuilder(
    //     builder: (context, child) {
    //       // _showEditCompleteDialog();
    //       return child!;
    //     },
    //     listenable: widget.updated!,
    //     child: mainWidget,
    //   );
    // }

    return mainWidget;

    // true show warning
    // null show warning
    // false show child
    // if (widget.displayCondition?.call() ?? true) {
    // } else {
    // return widget.child;
    // }
  }
}

class _ConditionalEditWarningDialog extends EditWarningDialog {
  const _ConditionalEditWarningDialog({super.key, required super.child, required this.displayCondition, super.warningMessage, super.finalMessage, super.editCompleted}) : super();

  final ValueGetter<bool> displayCondition;

  @override
  State<_ConditionalEditWarningDialog> createState() => _ConditionalEditWarningDialogState();
}

class _ConditionalEditWarningDialogState extends State<_ConditionalEditWarningDialog> {
  @override
  Widget build(BuildContext context) {
    if (widget.displayCondition.call()) {
      return EditWarningDialog(
        warningMessage: widget.warningMessage,
        finalMessage: widget.finalMessage,
        editCompleted: widget.editCompleted,
        child: widget.child,
      );
    } else {
      return widget.child;
    }
  }
}
