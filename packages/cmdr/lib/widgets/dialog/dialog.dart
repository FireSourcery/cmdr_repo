// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


/// "Subtypes"

class const ConfirmationDialog<T>({super.key, final ValueGetter<T>? onCancel, final ValueGetter<T>? onConfirm, final Widget? title, final Widget? icon, final Color? iconColor, final Widget? content}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      icon: icon,
      iconColor: iconColor,
      content: content,
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop<T>(onCancel?.call()), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop<T>(onConfirm?.call()), child: const Text('Confirm')),
      ],
    );
  }
}

/// [AsyncConfirmationDialog] is a dialog that performs an async operation on confirm.
///   It displays a loading indicator while the operation is in progress.
///   The dialog closes when the operation is complete.
///   T is the return type of the async operation, and is passed to the onConfirmContent builder.
class const AsyncConfirmationDialog<T>({
  super.key,
  required final AsyncValueGetter<T> onConfirm, // process on confirm, asyncProcess
  required final Widget initialContent,
  required final AsyncWidgetBuilder<T> onConfirmContent, // onConfirm, pending completion, asyncProcessContent
  final Widget? title,
  final Widget? icon,
  final Color? iconColor,
}) extends StatefulWidget {
  @override
  State<AsyncConfirmationDialog<T>> createState() => _AsyncConfirmationDialogState<T>();
}

class _AsyncConfirmationDialogState<T>() extends State<AsyncConfirmationDialog<T>> {
  final Completer<void> userConfirmation = Completer(); // results of 'Confirm' button, held by widget
  Future<T>? onConfirmProcess; // process onConfirm. Connect after user confirmation

  // @override
  // void initState() {
  //   super.initState();
  // }

  // @override
  // void dispose() {
  //   super.dispose();
  // }

  void onPressedConfirm() {
    userConfirmation.complete();
    onConfirmProcess = widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: widget.icon,
      iconColor: widget.iconColor,
      title: widget.title,
      content: FutureBuilder(
        future: userConfirmation.future,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          return switch (snapshot.connectionState) {
            ConnectionState.waiting => widget.initialContent,
            ConnectionState.done => FutureBuilder(future: onConfirmProcess, builder: widget.onConfirmContent),
            ConnectionState.none || ConnectionState.active => const SizedBox.shrink(),
          };
        },
      ),

      // Buttons
      actions: [
        // /// Cancel Button
        // FutureBuilder(
        //   future: userConfirmation.future,
        //   builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        //     return switch (snapshot.connectionState) {
        //       ConnectionState.waiting => TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
        //       ConnectionState.none || ConnectionState.active || ConnectionState.done => const SizedBox.shrink(),
        //     };
        //   },
        // ),

        /// Progress Indicator - replacing buttons after user confirmation
        FutureBuilder(
          future: onConfirmProcess,
          builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
            return switch (snapshot.connectionState) {
              ConnectionState.none || ConnectionState.waiting => TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
              ConnectionState.active => const CircularProgressIndicator(),
              ConnectionState.done => TextButton(onPressed: () => Navigator.of(context).pop(snapshot.data), child: const Text('Ok')), // with or without error
            };
          },
        ),

        /// Confirm Button
        FutureBuilder(
          future: userConfirmation.future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return switch (snapshot.connectionState) {
              ConnectionState.waiting => TextButton(onPressed: onPressedConfirm, child: const Text('Confirm')),
              ConnectionState.none || ConnectionState.active || ConnectionState.done => const SizedBox.shrink(),
            };
          },
        ),
      ],
    );
  }
}
