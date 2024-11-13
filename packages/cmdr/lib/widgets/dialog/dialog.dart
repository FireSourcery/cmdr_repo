// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  late final Future<T> onConfirmCompleted; // process onConfirm. is it more defensive to leave uninitialized?

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
          return switch (snapshot) {
            AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active) => widget.initialContent,
            AsyncSnapshot(connectionState: ConnectionState.waiting) => widget.initialContent,
            AsyncSnapshot(connectionState: ConnectionState.done) => FutureBuilder(future: onConfirmCompleted, builder: widget.onConfirmContent),
          };
        },
      ),

      // Buttons
      actions: [
        /// Cancel Button
        FutureBuilder(
          future: userConfirmation.future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return switch (snapshot) {
              AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
              AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) => const SizedBox.shrink(),
            };
          },
        ),

        /// Confirm Button
        FutureBuilder(
          future: userConfirmation.future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return switch (snapshot) {
              AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(onPressed: onPressedConfirm, child: const Text('Confirm')),
              AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) => FutureBuilder(
                  future: onConfirmCompleted,
                  builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
                    return switch (snapshot) {
                      // AsyncSnapshot(hasError: true) =>  ,
                      AsyncSnapshot(connectionState: ConnectionState.none) => const Text('Initialing...'),
                      AsyncSnapshot(connectionState: ConnectionState.waiting || ConnectionState.active) => const CircularProgressIndicator(),
                      AsyncSnapshot(connectionState: ConnectionState.done) =>
                        TextButton(onPressed: () => Navigator.of(context).pop(snapshot.data), child: const Text('Ok')), // done with or without error
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
  const SelectionDialog({super.key, this.title, this.icon, this.selectedMax, this.iconColor, required this.selectable, required this.labelBuilder, this.initialSelected});
  final Widget? title;
  final Widget? icon;
  final Color? iconColor;
  final List<E> selectable; // must be a new list, iterable non-primatives do not add to set properly
  final Iterable<E>? initialSelected;
  final int? selectedMax;
  final Widget Function(E value, bool isSelected) labelBuilder;

  @override
  State<SelectionDialog<E>> createState() => _SelectionDialogState<E>();
}

class _SelectionDialogState<E> extends State<SelectionDialog<E>> {
  late final Set<E> selected = {...?widget.initialSelected};

  Set<E> onConfirm() => selected;

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog<Set<E>>(
      onConfirm: onConfirm,
      title: widget.title,
      icon: widget.icon,
      iconColor: widget.iconColor,
      // change this to multiselectwdiget
      content: Wrap(
        runSpacing: 5,
        spacing: 5,
        children: [
          //todo move this to selection chips? MultiSelectChips
          for (final element in widget.selectable)
            FilterChip(
              label: widget.labelBuilder(element, selected.contains(element)),
              onSelected: (bool value) => setState(() {
                if (value) {
                  if (widget.selectedMax != null && selected.length >= widget.selectedMax!) return;
                  selected.add(element);
                } else {
                  selected.remove(element);
                }
                // value ? selected.add(element) : selected.remove(element);
              }),
              selected: selected.contains(element),
            ),
        ],
      ),
    );
  }
}
