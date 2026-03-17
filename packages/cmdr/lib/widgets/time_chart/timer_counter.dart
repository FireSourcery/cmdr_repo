import 'package:flutter/material.dart';

mixin class TimerCounter {
  TimerCounter();

  final Stopwatch _stopwatch = Stopwatch();
  final ValueNotifier<int> elapsedNotifier = ValueNotifier(0);
  int get elapsed => elapsedNotifier.value;

  int captureElapsedMicroseconds([bool reset = true]) {
    elapsedNotifier.value = _stopwatch.elapsedMicroseconds;
    if (reset) _stopwatch.reset();
    return elapsedNotifier.value;
  }

  int captureElapsed([bool reset = true]) {
    elapsedNotifier.value = _stopwatch.elapsedMilliseconds;
    if (reset) _stopwatch.reset();
    return elapsedNotifier.value;
  }

  void startElapsed() {
    _stopwatch.reset();
    _stopwatch.start();
  }
}
