import 'package:flutter/material.dart';

import '../../file_storage/csv_file_storage.dart';
import '../../file_storage/file_storage_view.dart';
import '../../file_storage/file_storage_controller.dart';
import 'chart_controller.dart';
import 'chart_data.dart';

class ChartFileStorage extends CsvFileStorage with FileStorageNotifier<Map<String, List<dynamic>>> {
  ChartFileStorage(this.chartController);

  final ChartController chartController;

  @override
  void fromContents(Map<String, List<dynamic>> contents) => chartController.chartData = ChartData.fromMap(contents);

  @override
  Map<String, List<dynamic>> toContents() => chartController.chartData.toMap();
}

/// View
// load and parse
class OpenChartFileButton extends OpenFileButton {
  const OpenChartFileButton({required ChartFileStorage super.fileNotifier, super.title, super.iconData, super.key});

  // final ChartFileStorage csvFile;
  // @override
  // Future<void> beginAsync() async => csvFile.openParseNotify();
}

// class SaveChartFileButton extends SaveFileButton {
//   const SaveChartFileButton({required ChartFileStorage super., super.title = 'Save File', super.iconData = Icons.file_copy, super.key});

//   // final ChartFileStorage csvFile;
//   // @override
//   // Future<void> beginAsync() async => await csvFile.buildSaveNotify();
// }
