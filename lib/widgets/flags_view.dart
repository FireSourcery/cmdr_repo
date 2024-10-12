import 'package:cmdr/common/defined_types.dart';
import 'package:cmdr/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';
// import 'package:recase/recase.dart';

import '../binary_data/bitflags.dart';

// class FlagTile<T extends Enum> extends StatelessWidget {
//   const FlagTile({
//     super.key,
//   });

//   final IconData icon;
//   final Color onColor;
//   final Color offolor;

//   @override
//   Widget build(BuildContext context) {
//     //   // final theme = Theme.of(context).extension<FlagIconsTheme>()!;
//     return ListTile(
//       leading: Icon(icon, color: iconColor),
//       // contentPadding: const EdgeInsets.all(0),
//       dense: true,
//     );
//   }
// }

// class FlagIcon<T extends Enum> extends StatelessWidget {}

class FlagIcons<T extends Enum> extends StatelessWidget {
  const FlagIcons({super.key, required this.flags, this.onPressed, this.iconMap, this.toolTipMap, this.textMap});
  // FlagIcons.bitFlags({Key? key, required BitFlags<T> bitFlags}) : this(flags: bitFlags.pairs);

  // final FlagIconsSource<T> flagIconsSource;
  final Iterable<(T key, bool isOn)> flags;
  final ValueChanged<T>? onPressed;

  final Map<T, IconData>? iconMap; // likely compile time const, preferred over callback
  final Stringifier<T>? toolTipMap; // likely already exists, preferred over callback
  final Stringifier<T>? textMap;

  final IconData iconDefault = Icons.circle;
  final Color onColor = Colors.red;
  final Color offColor = Colors.grey;
  final bool showText = true;
  //hover mode => tooltip or name

  String _nameOf(T key) => textMap?.call(key) ?? key.name.pascalCase;

  Widget _iconOf((T, bool) flag) => Icon(iconMap?[flag.$1] ?? iconDefault, color: (flag.$2) ? onColor : offColor);
  Widget _textOf((T, bool) flag) => Text(_nameOf(flag.$1), overflow: TextOverflow.ellipsis, maxLines: 1, softWrap: false, style: const TextStyle(fontSize: 12));

  Widget iconButton((T, bool) flag) {
    return IconButton(
      // selectedIcon: , //alternative to color
      // isSelected: flag.$2,
      icon: _iconOf(flag),
      onPressed: onPressed != null ? () => onPressed!(flag.$1) : null,
      color: flag.$2 ? onColor : offColor,
    );
  }

  Widget flagTile((T, bool) flag) {
    return ListTile(
      contentPadding: EdgeInsets.all(0),
      leading: iconButton(flag),
      title: (showText) ? _textOf(flag) : null,
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context).extension<FlagIconsTheme>() ;
    // return Wrap(
    //   spacing: 0,
    //   runSpacing: 0,
    //   alignment: WrapAlignment.start,
    //   children: [
    //     for (final flag in flags) flagTile(flag),
    //   ],
    // );

    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        for (final flag in flags) flagTile(flag),
      ],
    );
  }
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
