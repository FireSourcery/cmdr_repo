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
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T?>(
      valueListenable: eventNotifier,
      builder: (context, event, initialBuild) {
        if (event == eventMatch) {
          return builder(context, child);
        }
        return initialBuild!;
      },
      child: builder(context, child), // initialBuild
    );
  }
}
