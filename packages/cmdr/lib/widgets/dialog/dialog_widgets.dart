import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef EventWidgetBuilder<T> = Widget Function(BuildContext context, T? value);

////////////////////////////////////////////////////////////////////////////////
/// [DialogAnchor]
///
/// e.g. warning dialog before editing a field, and a dialog after submitting a field
////////////////////////////////////////////////////////////////////////////////
class DialogAnchor<T> extends StatefulWidget {
  const DialogAnchor({
    super.key,
    required this.child,
    this.eventNotifier,
    this.eventGetter,
    this.initialSelectDialog,
    this.eventDialogBuilder,
  });

  factory DialogAnchor.conditional({
    Key? key,
    ValueGetter<bool>? displayCondition,
    String? warningMessage,
    String? finalMessage,
    required Widget child,
  }) {
    if (displayCondition == null) {
      return DialogAnchor(eventNotifier: null, child: child);
    } else {
      return _ConditionalEditWarningDialog<T>(displayCondition: displayCondition, child: child);
    }
  }

  final Widget? initialSelectDialog;

  // user match widget built to the notification event
  final Listenable? eventNotifier;
  final ValueGetter<T?>? eventGetter;
  // final ValueListenable<T?>? eventNotifier;
  final EventWidgetBuilder<T?>? eventDialogBuilder;

  final Widget child;

  static const String initialMessageDefault = 'Are you sure you want to continue?';
  static const String finalMessageDefault = 'You have completed editing this field.';

  @override
  State<DialogAnchor> createState() => _DialogAnchorState<T>();
}

class _DialogAnchorState<T> extends State<DialogAnchor> {
  final FocusNode _focusNode = FocusNode();
  bool _focusedOnce = false;

  void _handleFocusChange() {
    if (!_focusedOnce && _focusNode.hasFocus) {
      _showInitialDialog();
      _focusedOnce = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    widget.eventNotifier?.addListener(_showEventDialog);
  }

  @override
  void dispose() {
    widget.eventNotifier?.removeListener(_showEventDialog);
    _focusNode.dispose();
    super.dispose();
  }

  void _showInitialDialog() {
    if (widget.initialSelectDialog != null) {
      showDialog(context: context, builder: (context) => widget.initialSelectDialog!);
    }
  }

  void _showEventDialog() {
    //   if (value == eventMatch)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // if eventNotifier is provided, then eventDialogBuilder must not be null
        return widget.eventDialogBuilder!(context, widget.eventGetter?.call());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainWidget = Focus(focusNode: _focusNode, child: widget.child);
    return mainWidget;
  }
}

class _ConditionalEditWarningDialog<T> extends DialogAnchor<T> {
  const _ConditionalEditWarningDialog({
    super.key,
    required this.displayCondition,
    required super.child,
    super.eventNotifier,
    super.eventGetter,
    super.initialSelectDialog,
    super.eventDialogBuilder,
  });

  final ValueGetter<bool> displayCondition;

  @override
  State<_ConditionalEditWarningDialog> createState() => _ConditionalEditWarningDialogState<T>();
}

class _ConditionalEditWarningDialogState<T> extends State<_ConditionalEditWarningDialog> {
  @override
  Widget build(BuildContext context) {
    if (widget.displayCondition.call()) {
      return DialogAnchor<T>(
        child: widget.child,
      );
    } else {
      return widget.child;
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
/// [DialogButton] is a button that opens a dialog when pressed.
////////////////////////////////////////////////////////////////////////////////
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
