import 'package:csv/csv.dart';

import 'file_storage.dart';

class CsvFileCodec extends FileStringCodec<List<List<dynamic>>> {
  const CsvFileCodec();
  // @override
  // String encode(List<List<dynamic>> input) => const CsvEncoder().convert(input, convertNullTo: '');
  // @override
  // List<List<dynamic>> decode(String encoded) => const CsvDecoder().convert(encoded, convertEmptyTo: null);

  @override
  String encode(List<List<dynamic>> input) => const CsvEncoder().convert(input);
  @override
  List<List<dynamic>> decode(String encoded) => const CsvDecoder().convert(encoded);
}

class CsvFileMapCodec extends FileCodec<Map<String, List<dynamic>>, List<List<dynamic>>> {
  CsvFileMapCodec({this.transposeToColumnMap = false, this.skipEntries}); // potential make const if needed

  bool transposeToColumnMap;
  List<String>? skipEntries;

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
  // Convert a CSV file to a Map of rows.
  // Each row's first element is the key, remaining elements are the values.
  static Map<String, List<dynamic>> rowMapOf(List<List<dynamic>> csv) {
    return {for (final row in csv) row.first.toString(): row.skip(1).toList()};
  }

  // Convert a Map of rows to a CSV file.
  // Each map entry becomes a row: [key, ...values]
  static List<List<dynamic>> csvOfRowMap(Map<String, List<dynamic>> data) {
    if (data.isEmpty) return [];
    return [
      for (final MapEntry(:key, :value) in data.entries) [key, ...value],
    ];
  }
}

abstract class CsvFileStorage extends FileStorage<Map<String, List<dynamic>>> {
  CsvFileStorage({super.defaultName, super.extensions = const ['csv', 'txt'], bool transposeToColumnMap = true})
    : _stringCodec = CsvFileMapCodec(transposeToColumnMap: transposeToColumnMap).fuse(const CsvFileCodec());

  final Codec<Map<String, List<dynamic>>, String> _stringCodec;

  @override
  Codec<Map<String, List<dynamic>>, String> get stringCodec => _stringCodec;

  @override
  Object? fromContents(Map<String, List> contents);
  @override
  Map<String, List> toContents();
}
