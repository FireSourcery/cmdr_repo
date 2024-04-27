import 'package:flutter/material.dart';
import 'package:kelly_user_app/src/common/widgets/time_chart/chart_data.dart';

import '../../file_storage/csv_file_storage.dart';
import '../../file_storage/file_storage_view.dart';
import 'chart_controller.dart';

class ChartFileStorage extends CsvFileStorage {
  ChartFileStorage(this.chartController) : super(transposeToColumnMap: true);

  final ChartController chartController;

  @override
  void parseFromMap(Map<String, List<dynamic>> map) => chartController.chartData = ChartData.fromMap(map);

  @override
  Map<String, List<dynamic>> buildToMap() => chartController.chartData.toMap();
}

/// View
// load and parse
class OpenChartFileButton extends FileLoadButton {
  const OpenChartFileButton({required this.csvFile, super.title = 'Open File', super.iconData = Icons.file_open, super.key}) : super(fileNotifier: csvFile);

  final ChartFileStorage csvFile;
  @override
  Future<void> beginAsync() async => csvFile.openParseNotify();
}

class SaveChartFileButton extends FileLoadButton {
  const SaveChartFileButton({required this.csvFile, super.title = 'Save File', super.iconData = Icons.file_copy, super.key}) : super(fileNotifier: csvFile);

  final ChartFileStorage csvFile;
  @override
  Future<void> beginAsync() async => await csvFile.buildSaveNotify();
}
