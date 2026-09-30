import 'package:flutter/material.dart';

abstract interface class const LogoButton({super.key, final VoidCallback? onPressed, final ButtonStyle? buttonStyle}) extends StatelessWidget {
  const factory LogoButton.icon({ButtonStyle? buttonStyle, VoidCallback? onPressed, Key? key}) = LogoIconButton;
  const factory LogoButton.fab({ButtonStyle? buttonStyle, VoidCallback? onPressed, Key? key}) = LogoFabButton;
  const factory LogoButton.wide({ButtonStyle? buttonStyle, VoidCallback? onPressed, Key? key}) = LogoWideButton;

}

class const LogoImage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<LogoTheme>()!;
    return ImageIcon(theme.imageIcon, size: 69);
  }
}

class const LogoIconButton({super.buttonStyle, super.onPressed, super.key}) extends LogoButton {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<LogoTheme>()!;
    final style = buttonStyle ?? theme.buttonStyle;

    return SizedBox(
      width: 100,
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: style!.copyWith(padding: WidgetStateProperty.all(const EdgeInsets.all(15))),
        child: ImageIcon(theme.imageIcon!, size: 69), // > 100 - padding
      ),
    );
  }
}

class const LogoWideButton({super.buttonStyle, super.onPressed, super.key}) extends LogoButton {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<LogoTheme>()!;

    return SizedBox(
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle ?? theme.buttonStyle,
        child: Image(image: theme.imageExpanded!, height: 69, fit: BoxFit.contain),
      ),
    );
  }
}

class const LogoFabButton({super.buttonStyle, super.onPressed, super.key}) extends LogoButton {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<LogoTheme>()!;
    final style = buttonStyle ?? theme.buttonStyle;

    return FloatingActionButton.large(
      heroTag: UniqueKey(), // when a FAB is used, use
      shape: style?.shape?.resolve({}),
      backgroundColor: style?.backgroundColor?.resolve({}),
      onPressed: onPressed,
      child: const LogoImage(),
    );
  }
}

class const LogoTheme({final AssetImage? imageIcon, final AssetImage? imageExpanded, final ButtonStyle? buttonStyle}) extends ThemeExtension<LogoTheme> {
  @override
  ThemeExtension<LogoTheme> copyWith() {
    throw UnimplementedError();
  }

  @override
  ThemeExtension<LogoTheme> lerp(covariant ThemeExtension<LogoTheme>? other, double t) {
    return this;
  }
}
