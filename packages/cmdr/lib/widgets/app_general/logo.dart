import 'package:flutter/material.dart';

abstract interface class LogoButton extends StatelessWidget {
  const LogoButton({super.key, this.onPressed, this.buttonStyle});
  const factory LogoButton.icon({ButtonStyle? buttonStyle, VoidCallback? onPressed, Key? key}) = LogoIconButton;
  const factory LogoButton.fab({ButtonStyle? buttonStyle, VoidCallback? onPressed, Key? key}) = LogoFabButton;
  const factory LogoButton.wide({ButtonStyle? buttonStyle, VoidCallback? onPressed, Key? key}) = LogoWideButton;

  final VoidCallback? onPressed;
  final ButtonStyle? buttonStyle;
}

class LogoImage extends StatelessWidget {
  const LogoImage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<LogoTheme>()!;
    return ImageIcon(theme.imageIcon, size: 69);
  }
}

class LogoIconButton extends LogoButton {
  const LogoIconButton({super.buttonStyle, super.onPressed, super.key});

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

class LogoWideButton extends LogoButton {
  const LogoWideButton({super.buttonStyle, super.onPressed, super.key});

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

class LogoFabButton extends LogoButton {
  const LogoFabButton({super.buttonStyle, super.onPressed, super.key});

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

class LogoTheme extends ThemeExtension<LogoTheme> {
  const LogoTheme({this.imageIcon, this.imageExpanded, this.buttonStyle});

  final ButtonStyle? buttonStyle;
  final AssetImage? imageIcon;
  final AssetImage? imageExpanded;

  @override
  ThemeExtension<LogoTheme> copyWith() {
    throw UnimplementedError();
  }

  @override
  ThemeExtension<LogoTheme> lerp(covariant ThemeExtension<LogoTheme>? other, double t) {
    return this;
  }
}
