// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dialog_anchor.dart';

/// "Subtypes"

class const ConfirmationDialog<T>({
  super.key,
  final ValueGetter<T>? onCancel,
  final ValueGetter<T>? onConfirm,
  final Widget? title,
  final Widget? icon,
  final Color? iconColor,
  final Widget? content,
  final DialogButtonStyle? styleId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      icon: icon ?? styleId.icon,
      iconColor: iconColor ?? styleId.iconColorOf(context),
      content: content,
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop<T>(onCancel?.call()), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop<T>(onConfirm?.call()), style: styleId.confirmStyleOf(context), child: const Text('Confirm')),
      ],
    );
  }
}

/// [AsyncConfirmationDialog] is a dialog that performs an async operation on confirm.
///   It displays a loading indicator, and cannot be popped, while the operation is in progress.
///   On completion, 'Ok' closes the dialog with the result.
///   T is the return type of the async operation, and is passed to the onConfirmContent builder.
class const AsyncConfirmationDialog<T>({
  super.key,
  required final AsyncValueGetter<T> onConfirm, // process on confirm, asyncProcess
  required final Widget initialContent,
  required final AsyncWidgetBuilder<T> onConfirmContent, // onConfirm, pending completion, asyncProcessContent
  final Widget? title,
  final Widget? icon,
  final Color? iconColor,
  final DialogButtonStyle? styleId,
}) extends StatefulWidget {
  @override
  State<AsyncConfirmationDialog<T>> createState() => _AsyncConfirmationDialogState<T>();
}

class _AsyncConfirmationDialogState<T>() extends State<AsyncConfirmationDialog<T>> {
  Future<T>? process; // null until the user confirms

  // @override
  // void initState() {
  //   super.initState();
  // }

  // @override
  // void dispose() {
  //   super.dispose();
  // }

  void onPressedConfirm() => setState(() {
    process = widget.onConfirm()..ignore(); // the builder shows its error once it subscribes, a frame later
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: process,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        return AlertDialog(
          icon: widget.icon ?? widget.styleId.icon,
          iconColor: widget.iconColor ?? widget.styleId.iconColorOf(context),
          title: widget.title,
          content: switch (snapshot.connectionState) {
            ConnectionState.none => widget.initialContent,
            _ => widget.onConfirmContent(context, snapshot),
          },
          actions: switch (snapshot.connectionState) {
            ConnectionState.none => [
              TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
              TextButton(onPressed: onPressedConfirm, style: widget.styleId.confirmStyleOf(context), child: const Text('Confirm')),
            ],
            ConnectionState.done => [TextButton(onPressed: () => Navigator.of(context).pop(snapshot.data), child: const Text('Ok'))], // with or without error
            _ => [const PopScope(canPop: false, child: CircularProgressIndicator())],
          },
        );
      },
    );
  }
}

/// [DialogButtonStyle.warning] on a confirmation: the warning icon in the [DialogButtonTheme] warning colour, and Confirm in its warning button style.
extension on DialogButtonStyle? {
  bool get isWarning => (this == DialogButtonStyle.warning);
  Widget? get icon => isWarning ? const Icon(Icons.warning, size: 50) : null;
  Color? iconColorOf(BuildContext context) => isWarning ? Theme.of(context).extension<DialogButtonTheme>()?.warningColor : null;
  ButtonStyle? confirmStyleOf(BuildContext context) => isWarning ? Theme.of(context).extension<DialogButtonTheme>()?.warningButtonStyle : null;
}
