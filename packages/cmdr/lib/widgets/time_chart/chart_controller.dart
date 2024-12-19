import 'dart:collection';
import 'dart:math';

import 'package:async/async.dart';
import 'package:cmdr/connection/base/_socket_io.dart';
import 'package:cmdr/widgets/time_chart/chart_style.dart';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'chart_data.dart';

class ChartController with TimerNotifier, ChangeNotifier {
  ChartController({
    List<ChartEntry>? chartEntries,
    this.updateInterval = const Duration(milliseconds: 50),
    int samplesMax = 200, // e.g 100 samples at 10ms => 1s display
    int entriesMax = kSelectionCountMax,
    double? yMin,
    double? yMax,
  })  : assert(entriesMax <= kSelectionCountMax),
        chartEntries = chartEntries ?? [],
        _yMax = yMax,
        _yMin = yMin,
        _chartData = ChartData.zero(
          samplesMax: samplesMax,
          linesMax: entriesMax,
          lineNames: chartEntries?.map((e) => e.name),
        );

  static const int kSelectionCountMax = 8; // fixed 16 selections max

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  /// line configs, data generators
  final List<ChartEntry> chartEntries;
  final ChartStyle style = const ChartStyleDefault();

  // stop iteration before modifying
  void addEntry(ChartEntry entry) {
    stop();
    chartEntries.add(entry);
    chartData.addEntry(entry.name);
    notifyListeners();
    // start();
  }

  // void updateSelection(Iterable<ChartEntry> entries) {
  void replaceEntries(Iterable<ChartEntry> entries) {
    // _yMin = value;
    // _yMax = value;
    stop();
    chartEntries.clear();
    chartEntries.addAll(entries);
    chartData.replaceEntries(entries.map((e) => e.name));
    notifyListeners();
  }

  // void updateViewRange() {
  //   chartEntries.

  //   //scale to 1

  // }

  // void replaceEntryAt(int index, ChartEntry entry) {
  //   stop();
  //   chartEntries[index] = entry;
  //   chartData.replaceEntryAt(index) = LineData(entry.name);
  //   notifyListeners();
  //   // start();
  // }

  // attempt to retrieve Entries
  void loadWithMeta(ChartData data, List<String> keyNames, ChartEntry Function(String) mapper) {
    chartData = data;
    // replaceEntries(_chartData.lineEntries.map((e) => ChartEntry(name: e.name, valueGetter: () => 0)));
  }

  /// view data. independent of data generators
  ChartData _chartData; // line data models, derive from entry, file storage
  ChartData get chartData => _chartData;
  set chartData(ChartData value) {
    stop();
    _chartData = value;
    // match chart entries, values getters disabled
    replaceEntries(_chartData.lineEntries.map((e) => ChartEntry(name: e.name, valueGetter: () => 0)));
    notifyListeners();
  }

  int get chartDataLength => chartData.lineEntries.length;

  /// data update with generators
  void _updateData() {
    final remove = chartData.excessLength;
    chartData.updateTime(tValue, remove);
    for (final (index, entry) in chartEntries.indexed) {
      chartData.updateLine(index, entry.valueGetter().toDouble(), remove);
    }
  }

  // TimerNotifier timerNotifier = TimerNotifier();
  Duration updateInterval;
  bool get isActive => _timer?.isActive ?? false;
  bool get isStopped => !isActive;

  void start() {
    hideTouchData();
    startPeriodic(updateInterval, _updateData);
  }

  void stop() {
    showTouchData();
    stopPeriodic();
  }

  /// view config
  // todo view change
  double? _yMin;
  // double? get yMin => _yMin;
  double? get yMin => (useScalarView) ? -1.1 : _yMin;
  set yMin(double? value) {
    _yMin = value;
    notifyListeners();
  }

  double? _yMax;
  // double? get yMax => _yMax;
  double? get yMax => (useScalarView) ? 1.1 : _yMax;
  set yMax(double? value) {
    _yMax = value;
    notifyListeners();
  }

  double get tValue => stopwatch.elapsedMilliseconds / 1000;
  double get tMin => chartData.timeData.values.first;
  double get tMax => chartData.timeData.values.last;
  // double get tViewRange => ;
  // double get tSamplesRange => updateInterval.inSeconds * chartData.samplesMax * 1.0;

  // smallest max and largest max over 100
  bool get useScalarView => true;
  // bool get useScalarView {
  //   // double min = double.infinity;
  //   // double max = double.negativeInfinity;
  //   // for (final entry in chartEntries) {
  //   //   var value = entry.normalRef;
  //   //   if (value < min) min = value;
  //   //   if (value > max) max = value;
  //   // }
  //   // return max.abs() / min.abs() > 100;
  //   return false;
  // }

  // List<FlSpot> flSpotsViewOf(int index) => UnmodifiableListView(chartData.lineDataPoints(index).map((e) => FlSpot(e.x, e.y)));
  List<FlSpot> _flSpotsViewOf(int index) => [...chartData.lineDataPoints(index).map((e) => FlSpot(e.x, e.y))];
  List<FlSpot> _flSpotsViewOfAsScalar(int index) => [...chartData.lineDataPoints(index).map((e) => FlSpot(e.x, e.y / (chartEntries.elementAtOrNull(index)?.normalRef ?? 1)))];
  List<FlSpot> flSpotsViewOf(int index) => (useScalarView) ? _flSpotsViewOfAsScalar(index) : _flSpotsViewOf(index);

  /// todo visual options with notify
  FlDotData configDotData = const FlDotData(show: true);
  FlGridData configGridData = const FlGridData(show: true, drawVerticalLine: true, drawHorizontalLine: true);
  FlBorderData configBorderData = FlBorderData(show: false);

  LineTouchData touchData = const LineTouchData(enabled: false);

  void showTouchData({List<Color>? colors}) {
    touchData = LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        // getTooltipColor: (touchedSpot) => style.tooltipColor ?? const ChartStyleDefault().tooltipColor,
        getTooltipItems: (touchedSpots) {
          return [
            // alternatively make the first entry time
            ...touchedSpots.map(_lineTooltipItem),
          ];
        },
        fitInsideVertically: true,
      ),
    );
    notifyListeners();
  }

  LineTooltipItem? _lineTooltipItem(LineBarSpot e) {
    return LineTooltipItem(
      // chartEntries[e.barIndex].name, may point to removed entries
      // '${chartEntries[e.barIndex].name}: ${e.y.toStringAsFixed(3)}',
      '${chartEntries[e.barIndex].name}: ${chartData.lineEntries[e.barIndex].values[e.spotIndex].toStringAsFixed(3)}',
      TextStyle(color: style.legendColors?[e.barIndex] ?? Colors.white),
      textAlign: TextAlign.left,
    );
  }

  void hideTouchData() {
    touchData = const LineTouchData(enabled: false);
    notifyListeners();
  }

  void showDotData() {
    configDotData = FlDotData(checkToShowDot: configDotData.checkToShowDot, show: true);
    notifyListeners();
  }

  // Debug
  void addTestData() {
    final fnTimer = Stopwatch();
    addEntry(ChartEntry(valueGetter: () => sin(fnTimer.elapsedMilliseconds / 1000), name: 'sine'));
    addEntry(ChartEntry(valueGetter: () => cos(fnTimer.elapsedMilliseconds / 1000), name: 'cosine'));
    yMax ??= 1.2;
    yMin ??= -1.2;
    fnTimer.start();
    // start();
  }
}

// ChartEntry
// Chart Data Generator
class ChartEntry {
  const ChartEntry({
    required this.name,
    required this.valueGetter,
    this.color,
    this.onSelect,
    this.preferredPrecision,
    this.normalRef = 1,
  });

  final String name;
  final ValueGetter<num> valueGetter;

  final double normalRef; // yRange
  // final T key;

  final Color? color; //override default
  final VoidCallback? onSelect;
  final int? preferredPrecision;
}

abstract mixin class TimerNotifier implements ChangeNotifier {
  Stopwatch stopwatch = Stopwatch();
  RestartableTimer? _timer;
  VoidCallback _callback = () {};

  // VoidCallback get _callback;
  // Duration get updateInterval;

  void _timerCallback() {
    _callback();
    notifyListeners();
    _timer!.reset();
  }

  @protected
  void startPeriodic(Duration updateInterval, VoidCallback callback) {
    stopwatch.start();
    _callback = callback;
    _timer = RestartableTimer(updateInterval, _timerCallback);
  }

  @protected
  void stopPeriodic() {
    _timer?.cancel();
    stopwatch.stop();
  }
}

// todo state
// sealed class ChartMode {
//   double? get yMin;
//   double? get yMax;
//   set yMin(double? value);
//   set yMax(double? value);
//   double get tMin;
//   double get tMax;
//   set tMin(double value);
//   set tMax(double value);

//   List<FlSpot> dataOf(int index);
//   void start();
//   void stop();
// }
