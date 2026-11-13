import 'package:struct_data/struct_data.dart';
import 'package:test/test.dart';

enum const Color() { red, green, blue }

void main() {
  group('IndexMap with nullable values', () {
    final map = IndexMap<Color, int?>.filled(Color.values, null);

    test('[] returns null', () => expect(map[Color.red], isNull));
    test('toString', () => expect(map.toString(), '{Color.red: null, Color.green: null, Color.blue: null}'));
  });

  test('mapByName builds a non-nullable EnumMap', () {
    final map = EnumMapFactory(Color.values).mapByName<int>({'red': 1, 'green': 2, 'blue': 3});
    expect(map, {Color.red: 1, Color.green: 2, Color.blue: 3});
  });
}
