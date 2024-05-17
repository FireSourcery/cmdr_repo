import 'dart:collection';

import 'package:async/async.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'chart_data.dart';

/// todo user set y min, max
class ChartController with TimerNotifier, ChangeNotifier {
  ChartController({
    List<ChartEntry>? chartEntries,
    this.updateInterval = const Duration(milliseconds: 50),
    int samplesMax = 200, // e.g 100 samples at 10ms => 1s display
    // int? entriesMax = 16,
    int selectionCountMax = kSelectionCountMax,
    double? yMin,
    double? yMax,
  })  : chartEntries = chartEntries ?? [],
        _yMax = yMax,
        _yMin = yMin,
        assert(selectionCountMax <= kSelectionCountMax),
        _chartData = ChartData.zero(
          samplesMax: samplesMax,
          linesMax: selectionCountMax,
          lineNames: chartEntries?.map((e) => e.name) ?? [],
        ) {
    // start(); // ensure late timer is initialized
    // stop();
  }

  static const int kSelectionCountMax = 8; // fixed 16 selections max

  Duration updateInterval;

  ChartData _chartData; // line data models, derive from entry, file storage
  ChartData get chartData => _chartData;
  set chartData(ChartData value) {
    stop();
    _chartData = value;
    // match chart entries, values getters disabled
    updateEntries(_chartData.lineEntries.map((e) => ChartEntry(name: e.name, valueGetter: () => 0)));
    notifyListeners();
  }

  int get chartDataLength => chartData.lineEntries.length;

  double? _yMin;
  double? get yMin => _yMin;
  set yMin(double? value) {
    _yMin = value;
    notifyListeners();
  }

  double? _yMax;
  double? get yMax => _yMax;
  set yMax(double? value) {
    _yMax = value;
    notifyListeners();
  }

  double get tValue => stopwatch.elapsedMilliseconds / 1000;
  double get tMin => chartData.times.first;
  double get tMax => chartData.times.last;
  // double get tViewRange => ;
  // double get tSamplesRange => updateInterval.inSeconds * chartData.samplesMax * 1.0;

  bool get isActive => _timer?.isActive ?? false;
  bool get isStopped => !isActive; //todo view change

  void _updateData() {
    final remove = chartData.excessLength;
    chartData.updateTime(tValue, remove);
    for (final (index, entry) in chartEntries.indexed) {
      chartData.updateLine(index, entry.valueGetter().toDouble(), remove);
    }
  }

  void start() => startPeriodic(updateInterval, _updateData);
  void stop() => stopPeriodic();

  final List<ChartEntry> chartEntries; // line config

  void updateEntries(Iterable<ChartEntry> entries) {
    stop();
    chartEntries.clear();
    chartEntries.addAll(entries);
    chartData.updateEntries(entries.map((e) => LineData(e.name)));
    notifyListeners();
  }

  void addEntry(ChartEntry entry) {
    stop(); // todo check concurrent modification error
    chartEntries.add(entry);
    chartData.addEntry(LineData(entry.name));
    notifyListeners();
    // start();
  }

  void replaceEntryAt(int index, ChartEntry entry) {
    stop();
    chartEntries[index] = entry;
    chartData.lineEntries[index] = LineData(entry.name);
    notifyListeners();
    // start();
  }

  // void removeEntry(ChartEntry entry) {
  //   final index = chartEntries.indexOf(entry);
  //   if (index != -1) removeEntryAt(index);
  // }

  // void removeEntryAt(int index) {
  //   stop();
  //   chartEntries.removeAt(index);
  //   chartData.lines.removeAt(index);
  //   // start();
  // }

  List<FlSpot> flSpotsViewOf(int index) => UnmodifiableListView(chartData.lineDataPoints(index).map((e) => FlSpot(e.x, e.y)));

  /// todo visual options with notify
  FlDotData configDotData = const FlDotData(show: true);
  FlGridData configGridData = const FlGridData(show: true, drawVerticalLine: true, drawHorizontalLine: true);
  FlBorderData configBorderData = FlBorderData(show: false);

  void showDotData() {
    configDotData = FlDotData(checkToShowDot: configDotData.checkToShowDot, show: true);
    notifyListeners();
  }
}

// entry view model
class ChartEntry {
  const ChartEntry({required this.name, required this.valueGetter, this.color, this.onSelect, this.preferredPrecision});
  final String name;
  final ValueGetter<num> valueGetter;
  // final List<LineData> dataBuffer = [];
  // yRange
  final Color? color; //override default
  final VoidCallback? onSelect;
  final int? preferredPrecision;
}

mixin TimerNotifier implements ChangeNotifier {
  Stopwatch stopwatch = Stopwatch();
  RestartableTimer? _timer;

  @protected
  void startPeriodic(Duration updateInterval, VoidCallback callback) {
    stopwatch.start();
    _timer = RestartableTimer(updateInterval, () {
      callback();
      notifyListeners();
      _timer!.reset();
    });
  }

  @protected
  void stopPeriodic() {
    _timer?.cancel();
    stopwatch.stop();
  }
}

// todo state
sealed class ChartMode {
  double? get yMin;
  double? get yMax;
  set yMin(double? value);
  set yMax(double? value);
  double get tMin;
  double get tMax;
  set tMin(double value);
  set tMax(double value);

  List<FlSpot> dataOf(int index);
  void start();
  void stop();
}
