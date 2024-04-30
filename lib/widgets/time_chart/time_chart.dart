import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:meta/meta.dart';

import 'chart_controller.dart';
import 'chart_data.dart';
import 'chart_style.dart';

// todo widget for y min and y max
class TimeChart extends StatelessWidget {
  const TimeChart({required this.chartController, this.style = const ChartStyleDefault(), super.key});

  final ChartController chartController;
  final ChartStyle? style;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = style?.backgroundColor ?? const ChartStyleDefault().backgroundColor;
    final colors = style?.legendColors ?? const ChartStyleDefault().legendColors;
    final gradients = [for (final color in colors) ChartColors.gradient(color)];

    Widget builder(BuildContext context, Widget? child) {
      return LineChart(
        LineChartData(
          minY: chartController.yMin,
          maxY: chartController.yMax,
          minX: chartController.tMin,
          maxX: chartController.tMax,
          lineBarsData: [
            for (var index = 0; index < chartController.chartDataLength; index++)
              LineChartBarData(
                spots: chartController.flSpotsViewOf(index),
                gradient: gradients[index],
                dotData: chartController.configDotData,
                barWidth: 4,
                isCurved: true,
              ),
          ],
          backgroundColor: backgroundColor,
          lineTouchData: const LineTouchData(enabled: false),
          // clipData: const FlClipData.all(),
          gridData: const FlGridData(show: true, drawVerticalLine: true, drawHorizontalLine: true),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => SideTitleWidget(axisSide: meta.axisSide, space: 16, child: Text(meta.formattedValue)),
                reservedSize: 56,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => SideTitleWidget(axisSide: meta.axisSide, space: 16, child: Text(meta.formattedValue)),
                interval: 1,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
        ),
      );
    }

    return ListenableBuilder(listenable: chartController, builder: builder);
  }

  TimeChart.test({this.style, required this.chartController, super.key}) {
    Stopwatch fnTimer = Stopwatch();
    chartController.addEntry(ChartEntry(valueGetter: () => sin(fnTimer.elapsedMilliseconds / 1000), name: 'sine'));
    chartController.addEntry(ChartEntry(valueGetter: () => cos(fnTimer.elapsedMilliseconds / 1000), name: 'cosine'));
    chartController.yMax ??= 1.2;
    chartController.yMin ??= -1.2;
    fnTimer.start();
    chartController.start();
  }
}
