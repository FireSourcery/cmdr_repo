import 'dart:io';

import 'package:cmdr/widgets/time_chart/chart_controller.dart';
import 'package:cmdr/widgets/time_chart/chart_file.dart';
import 'package:flutter_test/flutter_test.dart';

/// A chart CSV as a spreadsheet writes it: integer cells among the decimals, CRLF line ends.
const _fixture = 'time,Speed,Iq\r\n0,0,0.5\r\n0.02,100,1\r\n0.04,200,1.5\r\n';

const _fixtureSeries = {
  'time': [0.0, 0.02, 0.04],
  'Speed': [0.0, 100.0, 200.0],
  'Iq': [0.5, 1.0, 1.5],
};

Map<String, List<double>> _seriesOf(ChartController controller) => {
  controller.chartData.timeData.name: controller.chartData.timeData.values,
  for (final line in controller.chartData.lineEntries) line.name: line.values,
};

/// Pins the load path `OpenFileButton` runs, from the picked file to the chart's series and entries.
void main() {
  late Directory dir;
  late ChartController controller;
  late ChartFileStorage storage;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('chart_file_test');
    controller = ChartController();
    storage = ChartFileStorage(controller);
  });

  tearDown(() {
    storage.dispose();
    controller.dispose();
    dir.deleteSync(recursive: true);
  });

  File fixtureFile() => File('${dir.path}/fixture.csv')..writeAsStringSync(_fixture);

  test('a CSV file loads into the series it holds, one entry per line', () async {
    await storage.openParseWithNotify(Future.value(fixtureFile()));

    expect(_seriesOf(controller), _fixtureSeries);
    expect(controller.chartEntries.map((e) => e.name), ['Speed', 'Iq']);
  });

  test('loading twice keeps the lines: the fixture, then the chart\'s own save of it', () async {
    await storage.openParseWithNotify(Future.value(fixtureFile()));
    final saved = await storage.save(File('${dir.path}/saved.csv'), storage.buildContents());
    await storage.openParseWithNotify(Future.value(saved));

    expect(_seriesOf(controller), _fixtureSeries);
    expect(controller.chartEntries.map((e) => e.name), ['Speed', 'Iq']);
  });

  test('a CSV whose time column is not numeric is refused, and the chart keeps its lines', () async {
    await storage.openParseWithNotify(Future.value(fixtureFile()));
    final clock = File('${dir.path}/clock.csv')..writeAsStringSync('time,Speed\r\n12:00:01,0\r\n');

    await expectLater(storage.openParseWithNotify(Future.value(clock)), throwsFormatException);
    expect(_seriesOf(controller), _fixtureSeries);
  });
}
