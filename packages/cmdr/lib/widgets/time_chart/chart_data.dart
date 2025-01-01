// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';

class LineData {
  const LineData._(this.name, this.values);
  LineData.from(this.name, Iterable<double> values, [int? capacity]) : values = QueueList(capacity)..addAll(values);
  LineData.capacity(this.name, int capacity) : values = QueueList(capacity);
  // LineData.fixed(this.name, int capacity, [Iterable<double>? values]) : values = QueueList(capacity)..add(0);

  final String name;
  final QueueList<double> values;

  // caller calculates excess once for all lines
  void update(double value, [int excess = 0]) {
    values.removeRange(0, excess);
    values.add(value);
  }

  void clear() {
    values.clear();
  }

  // lazy generate view, a buffered FlSpot may be dynamically allocated, or passthrough values as references
  // Iterable<Point<double>> mapAsPoints(List<double> timeData) => values.mapIndexed((index, element) => Point(timeData[index], element));
  Iterable<Point<double>> mapAsPoints(List<double> timeData) => Iterable.generate(min(timeData.length, values.length), (index) => Point(timeData[index], values[index]));

  factory LineData.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'name': String name,
          'values': String stringList,
        }) {
      if (jsonDecode(stringList) case List jsonList) {
        return LineData.from(name, List<double>.from(jsonList));
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

  factory LineData.fromMapEntry(MapEntry<String, List> mapEntry) => LineData.from(mapEntry.key, List<double>.from(mapEntry.value.map((e) => e ?? 0.0))); // handle non num?
  factory LineData.ofMapEntry(MapEntry<String, List<double>> mapEntry) => LineData.from(mapEntry.key, List<double>.of(mapEntry.value));

  MapEntry<String, List<double>> toMapEntry() => MapEntry<String, List<double>>(name, values.toList());

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
  ChartData._({required this.linesMax, required this.samplesMax, required this.lineEntries, required this.timeData}) : assert(lineEntries.length <= linesMax);
  // ChartData({required this.linesMax, required this.samplesMax, Iterable<List<double>>? lineEntries, required Iterable<double> times})
  //     : lineEntries = [for (final line in lines) LineData.fromMapEntry(line)],
  //       timeData = LineData.capacity(name, samplesMax);

  // include 1 initial point as it is required by the view
  ChartData.zero({required this.linesMax, required this.samplesMax, Iterable<String>? lineNames})
      : assert((lineNames?.length ?? 0) <= linesMax),
        timeData = LineData.capacity('time', samplesMax)..update(0.0), // start with 1 element for tMin
        lineEntries = [
          if (lineNames != null)
            for (final name in lineNames) LineData.capacity(name, samplesMax)..update(0.0)
        ];

  final List<LineData> lineEntries; // indexed parallel with colors list, alternatively use Map<String, List<double>>
  // final QueueList<double> timeData;
  final LineData timeData;
  final int linesMax; // alternatively use not growable entries count.
  final int samplesMax; // common entry length max

  // calculate once per update
  int get excessLength => max(0, (timeData.values.length - samplesMax + 1)); // length <= max - 1 before add

  void updateTime(double time, int excess) {
    timeData.update(time, excess);
  }

  void updateLine(int index, double value, int excess) {
    lineEntries[index].update(value, excess);
  }

  // void zero() {
  //   timeData
  //     ..clear()
  //     ..update(0.0);
  //   for (final line in lineEntries) {
  //     line
  //       ..clear()
  //       ..update(0.0);
  //   }
  // }

  void addEntry(String name) {
    if (lineEntries.length < linesMax) lineEntries.add(LineData.capacity(name, samplesMax)..update(0.0));
  }

  void replaceEntries(Iterable<String> entries) {
    (timeData..clear()).update(0.0);
    lineEntries.clear();
    entries.forEach(addEntry);
  }

  Iterable<Point<double>> lineDataPoints(int index) => lineEntries[index].mapAsPoints(timeData.values);

  Iterable<Point<double>> operator [](int index) => lineDataPoints(index);

  // csv map
  Map<String, List<dynamic>> toMap() => {'time': timeData.values}..addEntries(lineEntries.map((e) => e.toMapEntry()));

  // factory ChartData.ofMap(Map<String, List<double?>> map) {
  factory ChartData.fromMap(Map<String, List<dynamic>> map) {
    if (map case {'time': List timeList}) {
      if (timeList case List<double?>()) {
        if (map.entries.skip(1) case Iterable<MapEntry<String, List>> lines) {
          return ChartData._(
            lineEntries: [for (final line in lines) LineData.fromMapEntry(line)],
            timeData: LineData.fromMapEntry(map.entries.first),
            linesMax: lines.length,
            samplesMax: timeList.length,
          );
        }
      }
    }
    throw const FormatException('Unexpected CSV format');
  }

// json map
  Map<String, Object?> toJson() {
    return {
      'time': timeData.toString(),
      'entires': [for (final entry in lineEntries) entry.toJson()],
      'entriesMax': linesMax,
      'samplesMax': samplesMax,
    };
  }

  factory ChartData.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'time': String timeJson,
          'entires': List entriesJson, // List<Map<String,Object>>
          'entriesMax': int entriesMax,
          'samplesMax': int samplesMax,
        }) {
      if (jsonDecode(timeJson) case List timeList) {
        if (entriesJson case List<Map<String, Object?>>()) {
          if (timeList case List<double>()) {
            return ChartData._(
              lineEntries: [for (final entry in entriesJson) LineData.fromJson(entry)],
              timeData: LineData.fromJson({'time': timeJson}),
              linesMax: entriesMax,
              samplesMax: samplesMax,
            );
          }
        }
      }
    }
    throw const FormatException('Unexpected JSON format');
  }

  // ChartData copyWith({
  //   List<LineData>? lines,
  //   List<double>? time,
  //   int? linesMax,
  //   int? samplesMax,
  // }) {
  //   return ChartData(
  //     lines: lines ?? this.lineEntries,
  //     time: time ?? this.time,
  //     linesMax: linesMax ?? this.linesMax,
  //     samplesMax: samplesMax ?? this.samplesMax,
  //   );
  // }
}
