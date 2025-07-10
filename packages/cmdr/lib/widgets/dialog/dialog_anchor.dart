import 'package:flutter/material.dart';

typedef EventWidgetBuilder<T> = Widget Function(BuildContext context, T event);
// typedef EventWidgetBuilder1<T> = ValueWidgetBuilder<T>;

////////////////////////////////////////////////////////////////////////////////
/// [DialogAnchor] - Wraps a widget with a dialog that is shown on focus or event.
///
/// e.g. warning dialog before editing a field, and a dialog after submitting a field
////////////////////////////////////////////////////////////////////////////////
class DialogAnchor<T> extends StatefulWidget {
  const DialogAnchor({
    super.key,
    this.initialDialogBuilder,
    this.eventNotifier,
    this.eventGetter,
    this.eventDialogBuilder,
    this.eventMatch,
    this.notificationMatch,
    required this.child,
  });

  final WidgetBuilder? initialDialogBuilder;
  // allow a more general interface, instead of ValueListenable<T?>? eventNotifier;
  final Listenable? eventNotifier; // controls opening of dialog
  final ValueGetter<T?>? eventGetter;
  // returns on notification match
  final T? eventMatch;

  // additional way to match event
  final Notification? notificationMatch;

  // user match widget built to the notification event
  final EventWidgetBuilder<T?>? eventDialogBuilder;
  final Widget child;

  @override
  State<DialogAnchor> createState() => _DialogAnchorState<T>();
}

class _DialogAnchorState<T> extends State<DialogAnchor<T>> {
  final FocusNode _focusNode = FocusNode();
  bool _focusedOnce = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    if (widget.eventNotifier != null && widget.eventDialogBuilder != null) {
      widget.eventNotifier!.addListener(_showEventDialogAsListener);
    }
  }

  @override
  void dispose() {
    if (widget.eventNotifier != null && widget.eventDialogBuilder != null) {
      widget.eventNotifier!.removeListener(_showEventDialogAsListener);
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && !_focusedOnce) {
      _showInitialDialog();
      _focusedOnce = true;
    }
  }

  void _showInitialDialog() {
    if (widget.initialDialogBuilder != null) {
      showDialog(context: context, builder: widget.initialDialogBuilder!);
    }
  }

  // eventDialogBuilder not null, checked on init
  void _showEventDialog() {
    showDialog(
      context: context,
      builder: (context) => widget.eventDialogBuilder!(context, widget.eventGetter?.call()),
    );
  }

  void _showEventDialogAsListener() {
    // if (widget.eventGetter == null || widget.eventGetter?.call() == widget.eventMatch)
    _showEventDialog();
  }

  @override
  Widget build(BuildContext context) {
    var mainWidget = widget.child;

    if (widget.notificationMatch != null) {
      mainWidget = NotificationListener(
        onNotification: (Notification notification) {
          if (notification == widget.notificationMatch) {
            _showEventDialog();
            return true;
          }
          return false;
        },
        child: mainWidget,
      );
    }

    return Focus(focusNode: _focusNode, child: mainWidget);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// [DialogButton] is a button that opens a dialog when pressed.
////////////////////////////////////////////////////////////////////////////////
class DialogButton<T> extends StatelessWidget {
  const DialogButton({
    super.key,
    required this.dialogBuilder,
    this.child,
    this.onPressed,
    this.onPop,
    this.useRootNavigator = true,
    this.styleId,
    this.barrierDismissible = false,
  });
  // use the warning theme
  // const DialogButton.warning({super.key, required this.dialogBuilder, this.useRootNavigator = true, this.child, this.onPop, this.onPressed}) : themeStyle = DialogButtonStyle.warning;

  final WidgetBuilder dialogBuilder; // must build new for async
  final Widget? child;
  final VoidCallback? onPressed;
  final ValueSetter<T?>? onPop;
  final bool useRootNavigator;
  final DialogButtonStyle? styleId;

  final bool barrierDismissible;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = switch (styleId) {
      DialogButtonStyle.warning => Theme.of(context).extension<DialogButtonTheme>()!.warningButtonStyle,
      DialogButtonStyle.normal || null => Theme.of(context).extension<DialogButtonTheme>()!.buttonStyle,
    };

    return ElevatedButton(
      onPressed: () async {
        onPressed?.call();
        final result = await showDialog<T>(context: context, builder: dialogBuilder, barrierDismissible: barrierDismissible, useRootNavigator: useRootNavigator);
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

//DialogExtensionTheme
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
    return this;
  }
}
