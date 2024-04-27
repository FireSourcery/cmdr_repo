import 'csv_file_storage.dart';

import 'package:flutter/material.dart';
import 'file_storage_view.dart';

// /// View
// // load and parse
// class OpenCsvFileButton extends FileLoadButton {
//   const OpenCsvFileButton({required this.csvFile, super.title = 'Open File', super.iconData = Icons.file_open, super.key}) : super(fileNotifier: csvFile);

//   final CsvFileStorage csvFile;
//   @override
//   Future<void> onShowDialog() async => csvFile.fromOpen();
// }

// class SaveCsvFileButton extends FileLoadButton {
//   const SaveCsvFileButton({required this.csvFile, super.title = 'Save File', super.iconData = Icons.file_copy, super.key}) : super(fileNotifier: csvFile);

//   final CsvFileStorage csvFile;
//   @override
//   Future<void> onShowDialog() async => await csvFile.saveTo();
// }
