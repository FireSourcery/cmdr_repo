import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'chart_controller.dart';
import 'chart_style.dart';

export 'chart_controller.dart';
export 'chart_data.dart';
export 'chart_file.dart';
export 'chart_legend.dart';
export 'chart_style.dart';
export 'chart_widgets.dart';

// todo widget for y min and y max
class TimeChart extends StatelessWidget {
  const TimeChart({required this.chartController, this.style = const ChartStyleDefault(), super.key});

  TimeChart.test({this.style = const ChartStyleDefault(), required this.chartController, super.key}) {
    chartController.addTestData();
    chartController.start();
  }

  final ChartController chartController;
  final ChartStyle style;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = style.backgroundColor ?? const ChartStyleDefault().backgroundColor;
    final colors = style.legendColors ?? const ChartStyleDefault().legendColors;
    final gradients = [for (final color in colors) ChartColors.gradient(color)];

    Widget builder(BuildContext context, Widget? child) {
      return LineChart(
        LineChartData(
          lineBarsData: [
            for (var index = 0; index < chartController.chartDataLength; index++)
              LineChartBarData(
                spots: chartController.flSpotsViewOf(index),
                gradient: gradients[index],
                dotData: chartController.configDotData,
                barWidth: 4,
                isCurved: false,
                preventCurveOverShooting: true,
                isStepLineChart: true,
              ),
          ],
          minY: chartController.yMin,
          maxY: chartController.yMax,
          minX: chartController.tMin,
          maxX: chartController.tMax,
          clipData: const FlClipData.all(),
          backgroundColor: backgroundColor,
          lineTouchData: chartController.touchDataWhenStopped, // only when stopped
          gridData: const FlGridData(show: true, drawVerticalLine: true, drawHorizontalLine: true),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (_, meta) => SideTitleWidget(axisSide: meta.axisSide, space: 16, child: Text(meta.formattedValue)),
                reservedSize: 56,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (_, meta) => SideTitleWidget(axisSide: meta.axisSide, space: 16, child: Text(meta.formattedValue)),
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
}
