import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

import 'package:type_ext/basic_types.dart';

// interface, a field with value that reduces to bool
typedef FlagField = ({Enum key, bool value});

class FlagIndicators extends StatelessWidget {
  const FlagIndicators({super.key, required this.flags, this.onPressed, this.iconMap, this.toolTipMap, this.textMap});
  // FlagIcons.boolStruct({Key? key, required BoolStruct<T> boolStruct}) : this(flags: boolStruct.pairs);

  final Iterable<FlagField> flags;
  final ValueChanged<Enum>? onPressed;

  final Map<Enum, IconData>? iconMap; // likely compile time const, preferred over callback
  final Stringifier<Enum>? toolTipMap; // likely already exists, preferred over map
  final Stringifier<Enum>? textMap;

  final IconData iconDefault = Icons.circle;
  final Color onColor = Colors.red;
  final Color offColor = Colors.grey;
  final bool showText = true;
  //hover mode => tooltip or name

  String _nameOf(Enum key) => textMap?.call(key) ?? key.name;

  Widget _iconOf(FlagField flag) => Icon(iconMap?[flag.key] ?? iconDefault, color: (flag.value) ? onColor : offColor);
  Widget _textOf(FlagField flag) => Text(_nameOf(flag.key), overflow: TextOverflow.ellipsis, maxLines: 1, softWrap: false, style: const TextStyle(fontSize: 12));

  Widget iconButton(FlagField flag) {
    return IconButton(
      icon: _iconOf(flag),
      onPressed: onPressed != null ? () => onPressed!(flag.key) : null,
      color: flag.value ? onColor : offColor,
      // selectedIcon: , //alternative to color
      // isSelected: flag.value,
    );
  }

  Widget flagTile(FlagField flag) {
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
      children: [for (final flag in flags) flagTile(flag)],
    );
  }
}

// class FlagFieldTile<T extends Enum, V> extends StatelessWidget {
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
