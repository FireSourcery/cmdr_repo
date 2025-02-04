import 'package:csv/csv.dart';

import 'file_storage.dart';

class CsvFileCodec extends FileStringCodec<List<List<dynamic>>> {
  const CsvFileCodec();
  @override
  String encode(List<List<dynamic>> input) => const ListToCsvConverter().convert(input, convertNullTo: '');
  @override
  List<List<dynamic>> decode(String encoded) => const CsvToListConverter().convert(encoded, convertEmptyTo: null);
}

class CsvFileMapCodec extends FileContentCodec<Map<String, List<dynamic>>, List<List<dynamic>>> {
  CsvFileMapCodec({this.transposeToColumnMap = false}); // potential make const if needed

  bool transposeToColumnMap;

  // @override
  // final FileStringCodec<List<List<dynamic>>> innerCodec = const CsvFileCodec();
  @override
  List<List> encode(Map<String, List> decoded) => transposeToColumnMap ? csvOfColumnMap(decoded) : csvOfRowMap(decoded);
  @override
  Map<String, List> decode(List<List> contents) => transposeToColumnMap ? columnMapOf(contents) : rowMapOf(contents);

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
  static Map<String, List<dynamic>> rowMapOf(List<List<dynamic>> csv) {
    throw UnimplementedError();
    // final fields = List<String>.from(csv.first);
    // return csv.skip(1).map((row) => Map<String, dynamic>.fromIterables(fields, row));
  }

  static List<List<dynamic>> csvOfRowMap(Map<String, List<dynamic>> data) {
    throw UnimplementedError();
    // if (data.isEmpty) return [];
    // final fields = data.keys.toList();
    // return [fields, ...transpose(data.values)];
  }
}

abstract class CsvFileStorage extends FileStorage<Map<String, List<dynamic>>> {
  CsvFileStorage({super.defaultName, super.extensions = const ['csv', 'txt'], bool transposeToColumnMap = true})
      : _fileCodec = FileStorageCodec.fuse(CsvFileMapCodec(transposeToColumnMap: transposeToColumnMap), const CsvFileCodec());

  final FileStorageCodec<Map<String, List<dynamic>>, String> _fileCodec;

  @override
  FileStorageCodec<Map<String, List<dynamic>>, String> get fileCodec => _fileCodec;

  @override
  Object? fromContents(Map<String, List> contents);
  @override
  Map<String, List> toContents();
}
