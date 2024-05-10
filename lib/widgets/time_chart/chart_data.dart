// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';

class LineData {
  const LineData._(this.name, this.values);
  LineData(this.name, [List<double>? values, int? capacity]) : values = QueueList.from(values ?? [0.0]);
  LineData.capacity(this.name, int capacity) : values = QueueList(capacity);
  final String name;
  final QueueList<double> values;

  // todo with ring buffer?
  // caller calculates excess once for all lines
  void update(double value, [int excess = 0]) {
    values.removeRange(0, excess);
    values.add(value);
  }

  void clear() {
    values.clear();
  }

  // LineData updateValues(List<double> newValues) => LineData(name, newValues);

  // lazy generate view, a buffered FlSpot may be dynamically allocated, or passthrough values as references
  Iterable<Point<double>> mapAsPoints(List<double> times) => values.mapIndexed((index, element) => Point(times[index], element));

  factory LineData.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'name': String name,
          'values': String stringList,
        }) {
      if (jsonDecode(stringList) case List jsonList) {
        return LineData(name, List<double>.from(jsonList));
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

  factory LineData.fromMapEntry(MapEntry<String, List> mapEntry) => LineData(mapEntry.key, List<double>.from(mapEntry.value.map((e) => e ?? 0.0)));
  factory LineData.ofMapEntry(MapEntry<String, List<double>> mapEntry) => LineData(mapEntry.key, List<double>.of(mapEntry.value));
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
  ChartData._({required this.linesMax, required this.samplesMax, required this.lineEntries, required this.times}) : assert(lineEntries.length <= linesMax);
  // ChartData._filled({required this.linesMax, required this.samplesMax, List<LineData>? lineEntries, required this.times}) ;
  ChartData.zero({required this.linesMax, required this.samplesMax, required Iterable<String> lineNames})
      : times = QueueList(samplesMax)..add(0.0),
        lineEntries = [for (final entry in lineNames) LineData.capacity(entry, samplesMax)],
        assert(lineNames.length <= linesMax);

  final List<LineData> lineEntries; // indexed parallel with colors list, alternatively use Map<String, List<double>>
  final QueueList<double> times;
  final int linesMax; // alternatively use not growable entries count.
  final int samplesMax; // common entry length max

  // calculate once per update
  int get excessLength => max(0, (times.length - samplesMax));

  void updateTime(double time, int excess) {
    times.removeRange(0, excess);
    times.add(time);
  }

  void updateLine(int index, double value, int excess) {
    lineEntries[index].update(value, excess);
  }

  void clear() {
    times
      ..clear()
      ..add(0);
    for (final line in lineEntries) {
      line
        ..clear()
        ..update(0.0);
    }
  }

  void addEntry(LineData entry) {
    if (lineEntries.length < linesMax) lineEntries.add(entry);
  }

  void updateEntries(Iterable<LineData> entries) {
    lineEntries.clear();
    lineEntries.addAll(entries.take(linesMax));
  }

  Iterable<Point<double>> lineDataPoints(int index) => lineEntries[index].mapAsPoints(times);

  Iterable<Point<double>> operator [](int index) => lineDataPoints(index);

  // csv map
  Map<String, List<dynamic>> toMap() => {'times': times}..addEntries(lineEntries.map((e) => e.toMapEntry()));

  // factory ChartData.fromMap(Map<String, List<double?>> map) {
  factory ChartData.fromMap(Map<String, List<dynamic>> map) {
    if (map case {'times': List timeList}) {
      if (timeList case List<double?>()) {
        if (map.entries.skip(1) case Iterable<MapEntry<String, List>> lines) {
          return ChartData._(
            lineEntries: [for (final line in lines) LineData.fromMapEntry(line)],
            times: QueueList<double>.from(timeList.map((e) => e ?? 0.0)),
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
      'times': times.toString(),
      'entires': [for (final entry in lineEntries) entry.toJson()],
      'entriesMax': linesMax,
      'samplesMax': samplesMax,
    };
  }

  factory ChartData.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'times': String timesJson,
          'entires': List entriesJson, // List<Map<String,Object>>
          'entriesMax': int entriesMax,
          'samplesMax': int samplesMax,
        }) {
      if (jsonDecode(timesJson) case List timeList) {
        if (entriesJson case List<Map<String, Object?>>()) {
          if (timeList case List<double>()) {
            return ChartData._(
              lineEntries: [for (final entry in entriesJson) LineData.fromJson(entry)],
              times: QueueList<double>.from(timeList),
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
  //   List<double>? times,
  //   int? linesMax,
  //   int? samplesMax,
  // }) {
  //   return ChartData(
  //     lines: lines ?? this.lineEntries,
  //     times: times ?? this.times,
  //     linesMax: linesMax ?? this.linesMax,
  //     samplesMax: samplesMax ?? this.samplesMax,
  //   );
  // }
}
