// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data_views/enum_chips.dart';

class ConfirmationDialog<T> extends StatelessWidget {
  const ConfirmationDialog({super.key, this.onCancel, this.onConfirm, this.title, this.icon, this.iconColor, this.content});
  final ValueGetter<T>? onCancel;
  final ValueGetter<T>? onConfirm;
  final Widget? title;
  final Widget? icon;
  final Color? iconColor;
  final Widget? content;

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
class AsyncConfirmationDialog<T> extends StatefulWidget {
  const AsyncConfirmationDialog({super.key, required this.onConfirm, required this.initialContent, required this.onConfirmContent, this.title, this.icon, this.iconColor});

  final Widget initialContent;
  final AsyncValueGetter<T> onConfirm; // process on confirm, asyncProcess
  final AsyncWidgetBuilder<T> onConfirmContent; // onConfirm, pending completion, asyncProcessContent

  final Widget? icon;
  final Color? iconColor;
  final Widget? title;

  @override
  State<AsyncConfirmationDialog<T>> createState() => _AsyncConfirmationDialogState<T>();
}

class _AsyncConfirmationDialogState<T> extends State<AsyncConfirmationDialog<T>> {
  final Completer<void> userConfirmation = Completer(); // results of 'Confirm' button
  Future<T>? onConfirmCompleted; // process onConfirm.

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
    onConfirmCompleted = widget.onConfirm();
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
            ConnectionState.done => FutureBuilder(future: onConfirmCompleted, builder: widget.onConfirmContent),
            ConnectionState.none || ConnectionState.active => const SizedBox.shrink(),
          };
        },
      ),

      // Buttons
      actions: [
        /// Cancel Button
        FutureBuilder(
          future: userConfirmation.future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return switch (snapshot.connectionState) {
              ConnectionState.waiting => TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
              ConnectionState.none || ConnectionState.active || ConnectionState.done => const SizedBox.shrink(),
            };
          },
        ),

        /// Confirm Button
        FutureBuilder(
          future: userConfirmation.future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return switch (snapshot.connectionState) {
              ConnectionState.waiting => TextButton(onPressed: onPressedConfirm, child: const Text('Confirm')),
              ConnectionState.none || ConnectionState.active || ConnectionState.done => FutureBuilder(
                future: onConfirmCompleted,
                builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
                  // AsyncSnapshot(hasError: true) =>  ,
                  return switch (snapshot.connectionState) {
                    ConnectionState.none => const Text('Initialing...'),
                    ConnectionState.waiting || ConnectionState.active => const CircularProgressIndicator(),
                    ConnectionState.done => TextButton(onPressed: () => Navigator.of(context).pop(snapshot.data), child: const Text('Ok')), // done with or without error
                  };
                },
              ),
            };
          },
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
// state to maintain selected items
class SelectionDialog<E> extends StatefulWidget {
  const SelectionDialog({super.key, this.title, this.icon, this.selectMax, this.iconColor, required this.selectable, this.labelBuilder, this.selectionState, this.initialSelected});
  final Widget? title;
  final Widget? icon;
  final Color? iconColor;
  // MultiSelectChips
  final List<E> selectable; // must be a new list, iterable non-primitives do not add to set properly
  final Set<E>? selectionState;
  // final ValueSetter<E>? onAdd;
  // final ValueSetter<E>? onRemove;
  final Iterable<E>? initialSelected;
  final int? selectMax;
  final ValueWidgetBuilder<E>? labelBuilder;

  @override
  State<SelectionDialog<E>> createState() => _SelectionDialogState<E>();
}

class _SelectionDialogState<E> extends State<SelectionDialog<E>> {
  late final selected = widget.selectionState ?? {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) selected.addAll(widget.initialSelected!);
  }

  Set<E> onConfirm() => selected;

  void onSelected(E value) {
    setState(() {});
    // widget.onSelected?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog<Set<E>>(
      onConfirm: onConfirm,
      title: widget.title,
      icon: widget.icon,
      iconColor: widget.iconColor,
      content: MultiSelectChips<E>(
        selectable: widget.selectable,
        selectionState: selected,
        selectMax: widget.selectMax,
        // initialSelected: widget.initialSelected,
        labelBuilder: widget.labelBuilder,
        onSelected: onSelected,
      ),
    );
  }
}
