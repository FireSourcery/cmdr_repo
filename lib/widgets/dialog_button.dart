// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DialogButton<T> extends StatelessWidget {
  const DialogButton({super.key, required this.dialogBuilder, this.useRootNavigator = true, this.child, this.themeStyle, this.onPop, this.onPressed});
  // use the warning theme
  const DialogButton.warning({super.key, required this.dialogBuilder, this.useRootNavigator = true, this.child, this.onPop, this.onPressed}) : themeStyle = DialogButtonStyle.warning;

  final WidgetBuilder dialogBuilder; // must build new for async
  final Widget? child;
  final ValueSetter<T?>? onPop;
  final VoidCallback? onPressed;
  final bool useRootNavigator;
  final DialogButtonStyle? themeStyle;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = switch (themeStyle) {
      DialogButtonStyle.warning => Theme.of(context).extension<DialogButtonTheme>()!.warningButtonStyle,
      DialogButtonStyle.normal || null => Theme.of(context).extension<DialogButtonTheme>()!.buttonStyle,
    };

    return ElevatedButton(
      onPressed: () async {
        onPressed?.call();
        final result = await showDialog<T>(
          context: context,
          barrierDismissible: false,
          builder: dialogBuilder,
          useRootNavigator: useRootNavigator,
        );
        onPop?.call(result); // alternatively show dialog next over async
      },
      style: buttonStyle,
      child: child,
    );
  }
}

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

class AsyncConfirmationDialog<T> extends StatelessWidget {
  const AsyncConfirmationDialog({super.key, required this.onConfirm, required this.initialContent, required this.onConfirmContent, this.title, this.icon, this.iconColor});

  final Widget initialContent;
  final AsyncValueGetter<T> onConfirm; //process on confirm
  final AsyncWidgetBuilder<T> onConfirmContent; //onConfirm, pending completion

  final Widget? icon;
  final Color? iconColor;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    final Completer<void> userConfirmation = Completer();
    late final Future<T> processCompleted;
    // final Future<T> processCompleted = userConfirmation.future.then((_) => onConfirm());

    void onPressedConfirm() {
      userConfirmation.complete();
      processCompleted = onConfirm();
    }

    return AlertDialog(
      icon: icon,
      iconColor: iconColor,
      title: title,
      content: FutureBuilder(
        future: userConfirmation.future,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          return switch (snapshot) {
            AsyncSnapshot(connectionState: ConnectionState.waiting) => initialContent,
            AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) => FutureBuilder(future: processCompleted, builder: onConfirmContent),
          };
        },
      ),
      actions: [
        FutureBuilder(
          future: userConfirmation.future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return switch (snapshot) {
              AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) => const SizedBox.shrink(),
            };
          },
        ),
        FutureBuilder(
          future: userConfirmation.future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return switch (snapshot) {
              AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(onPressed: onPressedConfirm, child: const Text('Confirm')),
              AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) => FutureBuilder(
                  future: processCompleted,
                  builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
                    return switch (snapshot) {
                      AsyncSnapshot(connectionState: ConnectionState.waiting) => const CircularProgressIndicator(),
                      AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) =>
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

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog<Set<E>>(
      onConfirm: () => selected,
      title: widget.title,
      icon: widget.icon,
      iconColor: widget.iconColor,
      content: Wrap(
        runSpacing: 5,
        spacing: 5,
        children: [
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

enum DialogButtonStyle {
  normal,
  warning,
}

class DialogButtonTheme extends ThemeExtension<DialogButtonTheme> {
  const DialogButtonTheme({this.buttonStyle, this.warningButtonStyle, this.warningColor});

  final ButtonStyle? buttonStyle;
  final ButtonStyle? warningButtonStyle;
  // final Icon? warningIcon;
  final Color? warningColor;
  // Color? get warningBackgroundColor => buttonStyle?.backgroundColor?.resolve({});

  @override
  DialogButtonTheme copyWith({
    ButtonStyle? buttonStyle,
    ButtonStyle? warningButtonStyle,
  }) {
    return DialogButtonTheme(
      buttonStyle: buttonStyle ?? this.buttonStyle,
      warningButtonStyle: warningButtonStyle ?? this.warningButtonStyle,
    );
  }

  @override
  ThemeExtension<DialogButtonTheme> lerp(covariant ThemeExtension<DialogButtonTheme>? other, double t) {
    throw UnimplementedError();
  }
}
