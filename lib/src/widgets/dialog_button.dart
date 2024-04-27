// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DialogButton<T> extends StatelessWidget {
  const DialogButton({super.key, required this.dialogBuilder, this.useRootNavigator = true, this.child, this.themeStyle, this.onPop});
  // use the warning theme
  const DialogButton.warning({super.key, required this.dialogBuilder, this.useRootNavigator = true, this.child, this.onPop}) : themeStyle = DialogButtonStyle.warning;

  final Widget Function(BuildContext context) dialogBuilder; // must build new for async
  final Widget? child;
  final DialogButtonStyle? themeStyle;
  final ValueSetter<T>? onPop;
  final bool useRootNavigator;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = switch (themeStyle) {
      DialogButtonStyle.warning => Theme.of(context).extension<DialogButtonTheme>()!.warningButtonStyle,
      DialogButtonStyle.normal || null => Theme.of(context).extension<DialogButtonTheme>()!.buttonStyle,
    };

    return ElevatedButton(
      onPressed: () async {
        final result = await showDialog<T>(
          context: context,
          barrierDismissible: false,
          builder: dialogBuilder,
          useRootNavigator: useRootNavigator,
        );
        if (result != null) onPop?.call(result); // alternatively show dialog next over async
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
      content: content,
      icon: icon,
      iconColor: iconColor,
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop<T>(onCancel?.call()), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop<T>(onConfirm?.call()), child: const Text('Confirm')),
      ],
    );
  }
}

// state to maintain selected items
class SelectionDialog<E> extends StatefulWidget {
  const SelectionDialog({super.key, this.title, this.icon, this.selectionCountMax, this.iconColor, required this.selection, required this.labelBuilder, this.initialSelected});
  final Widget? title;
  final Widget? icon;
  final Color? iconColor;
  final List<E> selection; // must be a new list, iterable non-primatives do not add to set properly
  final Iterable<E>? initialSelected;
  final int? selectionCountMax;
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
          for (final element in widget.selection)
            FilterChip(
              label: widget.labelBuilder(element, selected.contains(element)),
              onSelected: (bool value) => setState(() {
                if (value) {
                  if (widget.selectionCountMax != null && selected.length >= widget.selectionCountMax!) return;
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

// todo switch to composition
class AsyncConfirmationDialog<T> extends AlertDialog {
  AsyncConfirmationDialog({super.key, required this.onConfirm, required this.initialContent, required this.contentOnConfirm, super.title, super.icon, super.iconColor});

  final Widget initialContent;
  final AsyncValueGetter<T> onConfirm; //process on confirm
  final AsyncWidgetBuilder<T> contentOnConfirm; //onConfirm, pending completion

  final Completer<void> userConfirmation = Completer();
  Future<void> get userConfirmed => userConfirmation.future;
  late final Future<T> processCompleted;

  @override
  Widget? get content {
    return FutureBuilder(
      future: userConfirmed,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        return switch (snapshot) {
          AsyncSnapshot(connectionState: ConnectionState.waiting) => initialContent,
          _ => FutureBuilder(future: processCompleted, builder: contentOnConfirm),
        };
      },
    );
  }

  @override
  List<Widget>? get actions {
    onPressedConfirm() {
      userConfirmation.complete();
      processCompleted = onConfirm();
    }

    return [
      FutureBuilder(
        future: userConfirmed,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          return switch (snapshot) {
            AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            _ => const SizedBox.shrink(),
          };
        },
      ),
      FutureBuilder(
        future: userConfirmed,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          return switch (snapshot) {
            AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(onPressed: onPressedConfirm, child: const Text('Confirm')),
            _ => FutureBuilder(
                future: processCompleted,
                builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
                  return switch (snapshot) {
                    AsyncSnapshot(connectionState: ConnectionState.waiting) => const CircularProgressIndicator(),
                    _ => TextButton(onPressed: () => Navigator.of(context).pop(snapshot.data), child: const Text('Ok')), // done with or without error
                  };
                },
              ),
          };
        },
      ),
    ];
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
