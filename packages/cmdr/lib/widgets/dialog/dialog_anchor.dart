import 'package:flutter/material.dart';

///
/// [DialogAnchor] - Wraps a widget with a dialog that is shown on focus or event.
///
/// e.g. warning dialog before editing a field, and a dialog after submitting a field
///
/// [T] is the type of the event value that triggers the event dialog.
class const DialogAnchor<T>({
    super.key,
    final WidgetBuilder? initialDialogBuilder, // on first focus
    // allow a more general interface, instead of ValueListenable<T?>? eventNotifier;
    final Listenable? eventNotifier, // controls opening of dialog
    final ValueGetter<T?>? eventGetter,
    final ValueWidgetBuilder<T?>? eventDialogBuilder, // on event, e.g. submit, or other event. user match widget built to the notification event
    final T? eventMatch, // when set, open only on the transition into [eventGetter] == [eventMatch]
    final Notification? notificationMatch, // additional way to match event
    required final Widget child,
  }) extends StatefulWidget {
  @override
  State<DialogAnchor> createState() => _DialogAnchorState<T>();
}

class _DialogAnchorState<T>() extends State<DialogAnchor<T>> {
  final FocusNode _focusNode = FocusNode();
  bool _focusedOnce = false;
  T? _lastEvent; // previous [eventGetter] value, for [eventMatch] edge detection

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    if (widget.eventNotifier != null && widget.eventDialogBuilder != null) {
      _lastEvent = widget.eventGetter?.call(); // baseline, so mounting mid-event does not open the dialog
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
    showDialog(context: context, builder: (context) => widget.eventDialogBuilder!(context, widget.eventGetter?.call(), null));
  }

  /// [eventNotifier] may fire for reasons unrelated to the event, e.g. a [ChangeNotifier] shared with
  /// the value it reports on. [eventMatch] narrows this to the transition into a matching
  /// [eventGetter]; notifications while the event remains active do not reopen the dialog.
  void _showEventDialogAsListener() {
    if (widget.eventMatch case T match) {
      final T? previous = _lastEvent;
      _lastEvent = widget.eventGetter?.call();
      if (_lastEvent != match || previous == match) return;
    }
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

///
/// [DialogButton] is a button that opens a dialog when pressed.
///
class const DialogButton<T>({
  super.key,
  required final WidgetBuilder dialogBuilder, // must build new for async
  final Widget? child,
  final VoidCallback? onPressed,
  final ValueSetter<T?>? onPop,
  final bool useRootNavigator = true,
  final DialogButtonStyle? styleId,
  final bool barrierDismissible = false,
}) extends StatelessWidget {
  // use the warning theme
  // const DialogButton.warning({super.key, required this.dialogBuilder, this.useRootNavigator = true, this.child, this.onPop, this.onPressed}) : themeStyle = DialogButtonStyle.warning;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = switch (styleId) {
      DialogButtonStyle.warning => Theme.of(context).extension<DialogButtonTheme>()!.warningButtonStyle,
      DialogButtonStyle.normal || null => Theme.of(context).extension<DialogButtonTheme>()!.buttonStyle,
    };

    return ElevatedButton(
      onPressed: () async {
        onPressed?.call();
        final result = await showDialog<T>(
          context: context,
          builder: dialogBuilder,
          barrierDismissible: barrierDismissible,
          useRootNavigator: useRootNavigator,
        );
        onPop?.call(result); // alternatively show dialog next over async
      },
      style: buttonStyle,
      child: child,
    );
  }
}

enum DialogButtonStyle() { normal, warning }

//DialogExtensionTheme
class const DialogButtonTheme({final ButtonStyle? buttonStyle, final ButtonStyle? warningButtonStyle, final Color? warningColor}) extends ThemeExtension<DialogButtonTheme> {
  // final Icon? warningIcon;
  // Color? get warningBackgroundColor => buttonStyle?.backgroundColor?.resolve({});

  @override
  DialogButtonTheme copyWith({ButtonStyle? buttonStyle, ButtonStyle? warningButtonStyle}) {
    return DialogButtonTheme(buttonStyle: buttonStyle ?? this.buttonStyle, warningButtonStyle: warningButtonStyle ?? this.warningButtonStyle);
  }

  @override
  ThemeExtension<DialogButtonTheme> lerp(covariant ThemeExtension<DialogButtonTheme>? other, double t) {
    return this;
  }
}
