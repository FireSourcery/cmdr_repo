import 'package:csv/csv.dart';

import 'file_notifier.dart';

abstract class CsvFileStorage extends FileStorageNotifier<List<List<dynamic>>, String, List> {
  CsvFileStorage({this.transposeToColumnMap = false, super.saveName}) : super(allowedExtensions: const ['csv', 'txt']);

  @override
  List<List<dynamic>> decode(String encoded) => const CsvToListConverter().convert(encoded, convertEmptyTo: null);
  @override
  String encode(List<List<dynamic>> input) => const ListToCsvConverter().convert(input, convertNullTo: '');

  final bool transposeToColumnMap;

  @override
  Map<String, List> decodeToMap(List<List> contents) {
    if (transposeToColumnMap) {
      return columnMapOf(contents);
    } else {
      throw UnimplementedError();
    }
  }

  @override
  List<List> encodeFromMap(Map<String, List> map) {
    if (transposeToColumnMap) {
      return csvOfColumnMap(map);
    } else {
      throw UnimplementedError();
    }
  }

  @override
  Object? parseFromMap(Map<String, List> map);
  @override
  Map<String, List> buildToMap();

  /// Column per object
  // Convert a CSV file to a List of Maps.
  // Each map represents a column in the CSV file
  static Map<String, List<dynamic>> columnMapOf(List<List<dynamic>> csv) {
    final fields = List<String>.from(csv.first);
    final columns = transpose(csv.skip(1)); // Transpose rows to columns

    // Convert each column to a map
    return Map<String, List<dynamic>>.fromIterables(fields, columns);
  }

  // Convert a Map of columns to a CSV file.
  // Each map represents a column in the CSV file
  static List<List<dynamic>> csvOfColumnMap(Map<String, List<dynamic>> data) {
    if (data.isEmpty) return [];
    final fields = data.keys.toList();
    return [fields, ...transpose(data.values)];
  }

  static List<List<dynamic>> transpose(Iterable<Iterable<dynamic>> original) {
    final rowCount = original.length;
    final columnCount = original.first.length;
    return List<List<dynamic>>.generate(columnCount, (j) => List<dynamic>.generate(rowCount, (i) => original.elementAt(i).elementAtOrNull(j)));
  }

  /// Row per object
  // Convert a CSV file to a List of Maps.
  // Each map represents a row in the CSV file, with keys being the column names.
  // Iterable<Map<String, dynamic>> rowMapsOf(List<List<dynamic>> csv) {
  //   final fields = List<String>.from(csv.first);
  //   return csv.skip(1).map((row) => Map<String, dynamic>.fromIterables(fields, row));
  // }
}
