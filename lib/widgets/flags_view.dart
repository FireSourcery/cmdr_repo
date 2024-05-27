import 'package:flutter/material.dart';
// import 'package:recase/recase.dart';

import '../binary_data/bitflags.dart';

class FlagIcons<T extends Enum> {
  const FlagIcons({required this.bitFlags, this.iconsMap, this.textMap, this.onColor = Colors.red, this.offColor = Colors.grey});

  final BitFlags<T> bitFlags;
  final Color onColor;
  final Color offColor;
  final Map<T, IconData?>? iconsMap;
  final Map<T, String?>? textMap;

  Widget iconOf((T, bool) flag) => Icon(iconsMap?[flag.$1] ?? Icons.circle, color: (flag.$2) ? onColor : offColor);
  Widget textOf((T, bool) flag) => Text(nameOf(flag), overflow: TextOverflow.ellipsis, maxLines: 1, softWrap: false, style: const TextStyle(fontSize: 12));
  String nameOf((T, bool) flag) => textMap?[flag.$1] ?? flag.$1.name;
  // String nameOf(T key) => textMap?[key] ?? key.name;

  Iterable<Widget> toTiles() {
    return bitFlags.pairs.map<Widget>((e) {
      return ListTile(leading: iconOf(e), title: textOf(e), dense: true);
    });
  }

  Iterable<Widget> toIconButtons() {
    return bitFlags.pairs.map<Widget>((e) {
      return Tooltip(message: nameOf(e), child: IconButton(icon: iconOf(e), onPressed: null));
    });
  }

  // Widget toListView(context) {
  //   // final theme = Theme.of(context).extension<FlagIconsTheme>()!;
  //   return ListView(
  //     padding: const EdgeInsets.all(0),
  //     children: toTiles().toList(),
  //   );
  // }
}

class FlagIconsTheme extends ThemeExtension<FlagIconsTheme> {
  const FlagIconsTheme({required this.color1});

  final Color color1;

  @override
  FlagIconsTheme copyWith({Color? color1}) {
    throw UnimplementedError();
  }

  @override
  ThemeExtension<FlagIconsTheme> lerp(covariant ThemeExtension<FlagIconsTheme>? other, double t) {
    throw UnimplementedError();
  }
}
