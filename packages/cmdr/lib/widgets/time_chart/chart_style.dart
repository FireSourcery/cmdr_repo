import 'package:flutter/material.dart';

class ChartStyle extends ThemeExtension<ChartStyle> {
  const ChartStyle({
    this.backgroundColor,
    this.legendColors,
    this.lineTextStyle,
    this.legendTextStyle,
  });

  final Color? backgroundColor;
  final List<Color>? legendColors;
  final TextStyle? lineTextStyle;
  final TextStyle? legendTextStyle;

  LinearGradient? gradient(int index) => (legendColors != null) ? ChartColors.gradient(legendColors![index]) : null;
  Color? legendColor(int index) => legendColors?[index % legendColors!.length];

  ChartStyle copyWith({
    Color? backgroundColor,
    List<Color>? legendColors,
    TextStyle? lineTextStyle,
    TextStyle? legendTextStyle,
  }) {
    return ChartStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      legendColors: legendColors ?? this.legendColors,
      lineTextStyle: lineTextStyle ?? this.lineTextStyle,
      legendTextStyle: legendTextStyle ?? this.legendTextStyle,
    );
  }

  @override
  ThemeExtension<ChartStyle> lerp(covariant ThemeExtension<ChartStyle>? other, double t) {
    throw UnimplementedError();
  }
}

class ChartStyleDefault extends ChartStyle {
  const ChartStyleDefault();

  @override
  TextStyle get lineTextStyle => const TextStyle(fontSize: 10);
  @override
  TextStyle get legendTextStyle => const TextStyle(color: Color(0xff757391), fontSize: 16, fontWeight: FontWeight.bold);
  // TextStyle get legendTextStyle  => const TextStyle(color: Color(0xff757391), fontSize: 12);
  @override
  Color get backgroundColor => Colors.black26;
  @override
  List<Color> get legendColors => ChartColors.colorsNeon;
}

class ChartColors {
  static LinearGradient gradient(Color color) => LinearGradient(colors: [color.withOpacity(0), color], stops: const [0.01, 1.0]);

  static const Color neonBlue = Color(0xFF2196F3);
  static const Color neonYellow = Color(0xFFFFC300);
  static const Color neonOrange = Color(0xFFFF683B);
  static const Color neonGreen = Color(0xFF3BFF49);
  static const Color neonPurple = Color(0xFF6E1BFF);
  static const Color neonPink = Color(0xFFFF3AF2);
  static const Color neonRed = Color(0xFFE80054);
  static const Color neonCyan = Color(0xFF50E4FF);

  static const List<Color> colorsNeon = [neonRed, neonOrange, neonYellow, neonGreen, neonCyan, neonBlue, neonPurple, neonPink];
  static const List<Color> colorsStandard = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.pink];

  static const Color menuBackground = Color(0xFF090912);
  static const Color itemsBackground = Color(0xFF1B2339);
  static const Color pageBackground = Color(0xFF282E45);
  static const Color mainTextColor1 = Colors.white;
  static const Color mainTextColor2 = Colors.white70;
  static const Color mainTextColor3 = Colors.white38;
  static const Color mainGridLineColor = Colors.white10;
  static const Color borderColor = Colors.white54;
  static const Color gridLinesColor = Color(0x11FFFFFF);
}
