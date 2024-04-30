// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';

class LineData {
  const LineData._(this.name, this.values);
  LineData(this.name, [List<double>? values]) : values = values ?? [0];
  final String name;
  final List<double> values;

  // todo with ring buffer?
  // create a new list, list remove is O(n)
  LineData update(double value, [int excess = 0]) {
    // values.removeRange(0, excess); //O(n)
    // values.add(value);
    return updateValues(List.of(CombinedIterableView([
      values.skip(excess),
      [value]
    ])));
  }

  LineData updateValues(List<double> newValues) => LineData(name, newValues);

  // lazy generate view, a buffered FlSpot may be dynamically allocated, or passthrough values as references
  Iterable<Point<double>> mapTimes(List<double> times) => values.mapIndexed((index, element) => Point(times[index], element));

  factory LineData.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'name': String name,
          'values': String stringList,
        }) {
      if (jsonDecode(stringList) case List jsonList) {
        return LineData._(name, List<double>.from(jsonList));
      }
    }
    throw const FormatException('Unexpected JSON format');
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'values': values.toString(), // keep list on a single line
    };
  }

  factory LineData.fromMapEntry(MapEntry<String, List> map) => LineData(map.key, List<double>.from(map.value.whereNotNull()));
  MapEntry<String, List> toMapEntry() => MapEntry<String, List>(name, values);

  // // List implementation
  // @override
  // operator [](int index) => values[index];
  // @override
  // void operator []=(int index, double value) => throw UnsupportedError('Cannot modify values');
  // @override
  // set length(int newLength) => throw UnsupportedError('Cannot resize values');
  // @override
  // int get length => values.length;
}

class ChartData {
  ChartData({required this.linesMax, required this.samplesMax, required this.lines, required this.times}) : assert(lines.length <= linesMax);
  ChartData.zero({required this.linesMax, required this.samplesMax, required Iterable<String> lineNames})
      : times = [0],
        lines = [for (final entry in lineNames) LineData(entry)],
        assert(lineNames.length <= linesMax);

  final List<LineData> lines; // indexed parallel with colors list, alternatively use Map<String, List<double>>
  final List<double> times;
  final int linesMax; // alternatively use not growable entries count.
  final int samplesMax; // common entry length max

  // call first
  int get excessLength => max(0, (times.length - samplesMax));

  void updateTime(double time, int excess) {
    times.removeRange(0, excess);
    times.add(time);
  }

  void updateLine(int index, double value, int excess) {
    lines[index] = lines[index].update(value, excess);
  }

  // ChartData updateLines(int time, List<double> value ) {
  //   copyWith(lines:  ) ;
  // }

  void clear() {
    times.clear();
    times.add(0);
    for (final (index, line) in lines.indexed) {
      lines[index] = line.updateValues([0]);
    }
  }

  void addEntry(LineData entry) {
    if (lines.length < linesMax) lines.add(entry);
  }

  void updateEntries(Iterable<LineData> entries) {
    lines.clear();
    lines.addAll(entries.take(linesMax));
  }

  // if immuable
  // ChartData updateEntries(Iterable<LineData> entries) => copyWith(lines: entries.take(linesMax).toList());
  // ChartData clear() {
  //   times.clear();
  //   times.add(0);
  //   return copyWith(lines: [
  //     for (final line in lines) line.updateValues([0])
  //   ]);
  // }

  Iterable<Point<double>> dataAt(int index) => lines[index].mapTimes(times);

  // csv map
  Map<String, List<dynamic>> toMap() => {'times': times}..addEntries(lines.map((e) => e.toMapEntry()));

  // factory ChartData.fromMap(Map<String, List<double?>> map) {
  factory ChartData.fromMap(Map<String, List<dynamic>> map) {
    if (map case {'times': List timesList}) {
      if (map.entries.skip(1) case Iterable<MapEntry<String, List>> lines) {
        return ChartData(
          lines: [for (final line in lines) LineData.fromMapEntry(line)],
          times: List<double>.from(timesList),
          linesMax: lines.length,
          samplesMax: timesList.length,
        );
      }
    }
    throw const FormatException('Unexpected CSV format');
  }

// json map
  Map<String, Object?> toJson() {
    return {
      'times': times.toString(),
      'entires': [for (final entry in lines) entry.toJson()],
      'entriesMax': linesMax,
      'samplesMax': samplesMax,
    };
  }

  factory ChartData.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'times': String timesJson,
          'entires': List dataList,
          'entriesMax': int entriesMax,
          'samplesMax': int samplesMax,
        }) {
      if (jsonDecode(timesJson) case List timesList) {
        return ChartData(
          lines: [for (final data in dataList) LineData.fromJson(data)],
          times: List<double>.from(timesList),
          linesMax: entriesMax,
          samplesMax: samplesMax,
        );
      }
    }
    throw const FormatException('Unexpected JSON format');
  }

  ChartData copyWith({
    List<LineData>? lines,
    List<double>? times,
    int? linesMax,
    int? samplesMax,
  }) {
    return ChartData(
      lines: lines ?? this.lines,
      times: times ?? this.times,
      linesMax: linesMax ?? this.linesMax,
      samplesMax: samplesMax ?? this.samplesMax,
    );
  }
}
