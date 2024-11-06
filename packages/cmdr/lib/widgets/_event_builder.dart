import 'package:flutter/material.dart';

class EventNotifier<T> with ChangeNotifier implements ValueNotifier<T?> {
  EventNotifier();

  T? _value;

  @override
  T? get value => _value;

  // always notify on set
  @override
  set value(T? newValue) {
    _value = newValue;
    notifyListeners();
  }

  void notify(T? event) {
    value = event;
  }
}

/// same as ValueListenableBuilder, but matches event before setState
class EventBuilder<T> extends StatelessWidget {
  const EventBuilder({
    super.key,
    required this.eventNotifier,
    required this.eventMatch,
    required this.builder,
    this.child,
  });

  final ValueNotifier<T?> eventNotifier;
  final T eventMatch;
  final TransitionBuilder builder; // the wrapping widget, reactive to events
  final Widget? child; // the users child widget, that is passed back to the builder

  Widget _eventBuilder(BuildContext context, T? event, Widget? initialBuild) {
    if (event == eventMatch) {
      return builder(context, child); // also pass event back to builder?
    }
    return initialBuild!;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T?>(
      valueListenable: eventNotifier,
      builder: _eventBuilder,
      child: builder(context, child), // initialBuild
    );
  }
}
