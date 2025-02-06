import 'package:type_ext/basic_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [IOField] is effectively a view union of IO types styled similar to a [TextField]
abstract mixin class IOField<T> implements Widget {
  /// Select widget using union config
  /// T functions as generic type, as well as selection parameter, unless explicitly defined
  factory IOField(IOFieldConfig<T> config, {Key? key}) {
    return switch (config) {
      IOFieldConfig(isReadOnly: true) => IOFieldReader<T>.config(config),
      IOFieldConfig(valueEnumRange: != null) => IOFieldMenu<T>.config(config),
      IOFieldConfig<num>() => IOFieldText<T>.config(config),
      IOFieldConfig<Enum>() => IOFieldMenu<T>.config(config),
      IOFieldConfig<String>(valueEnumRange: null) => IOFieldText<T>.config(config),
      IOFieldConfig<bool>(:final boolStyle) => switch (boolStyle) {
          IOFieldBoolStyle.textMenu => IOFieldMenu<T>.config(config),
          IOFieldBoolStyle.latchingSwitch => IOFieldSwitch(config as IOFieldConfig<bool>) as IOField<T>,
          IOFieldBoolStyle.momentaryButton => IOFieldButton(config as IOFieldConfig<bool>) as IOField<T>,
        },
      _ => IOFieldReader<T>.config(config),
    };
  }

  // factory IOField.valueNotifier({
  //   ValueNotifier<T?> valueNotifier,
  //   InputDecoration? decoration,
  //   Key? key,
  // }) {
  //   return IOField(IOFieldConfig(valueListenable: valueNotifier, valueGetter: valueNotifier.value, valueSetter: valueNotifier.value , key: key);
  // }

  factory IOField.withSlider(IOFieldConfig<T> config, {Key? key}) {
    assert(config.valueNumLimits != null);
    return switch (T) {
      const (int) => IOFieldWithSlider<int>(config as IOFieldConfig<int>),
      const (double) => IOFieldWithSlider<double>(config as IOFieldConfig<double>),
      const (num) => IOFieldWithSlider<num>(config as IOFieldConfig<num>),
      _ => throw TypeError(),
    } as IOField<T>;
  }

  // factory IOField.withToggle(IOFieldConfig<bool> config, {Key? key}) {
  //   assert(T == bool);
  //   return _IOFieldDecoratedSwitch(config) as IOField<T>;
  // }

  // static InputDecoration idDecorationWithDefaults({
  //   InputDecoration? decorationBase,
  //   String? labelText,
  //   FloatingLabelAlignment? labelAlignment = FloatingLabelAlignment.start,
  //   IconData? prefixIcon,
  //   String? suffixText,
  //   String? hintText,
  // }) {
  //   return InputDecoration(
  //     labelText: labelText,
  //     // prefix: prefixIcon,
  //     prefixIcon: Icon(prefixIcon),
  //     prefixText: null,
  //     // suffix: suffixText,
  //     suffixIcon: null,
  //     suffixText: suffixText,
  //     hintText: hintText,
  //   );
  // }

  // @override
  // Widget build(BuildContext context) => Tooltip(message: config.tip, child: _builder(BuildContext context ));
}

/// Subtypes include a constructor with config, and a constructor using parameters.
/// This way logic can be shared between the 2 constructors.
abstract mixin class _IOFieldStringBox<T> implements IOField<T> {
  ValueGetter<T?> get valueGetter;
  ValueGetter<String>? get valueStringGetter;
  Stringifier<T>? get valueStringifier;

  static String _stringifyDefault(Object? value) => value.toString(); // unhandled null value string
  // static String _stringifyEnum(Enum value) => value.name.titleCase;

  Stringifier<T> get _effectiveStringifier => valueStringifier ?? _stringifyDefault;

  Stringifier<T?> get _effectiveNullableStringifier {
    if (valueStringifier case Stringifier<T?> stringifier) stringifier;
    return _stringifyDefault;
  }

  String _stringifyValue() {
    if (valueGetter() case T value) return _effectiveStringifier(value);
    return 'null'; // or handle null

    // _effectiveNullableStringifier(valueGetter());
  }

  ValueGetter<String> get _effectiveValueStringGetter => valueStringGetter ?? _stringifyValue;

  // String? get fieldLabel => inputDecoration?.labelText;
}

/// [IOFieldConfig<T>] Configuration class for IOField
/// This class encapsulates the parameters and settings required to configure an IOField
///
/// Effectively:
/// The IOField generative constructor, which can be shared without inheritance
/// Union of all mode/subtype parameters. pass to subtype variations' constructors as a common interface
class IOFieldConfig<T> {
  const IOFieldConfig({
    this.idDecoration = const InputDecoration(),
    this.isReadOnly = false, // alternatively move this to constructor parameter
    this.tip = '',
    required this.valueListenable,
    required this.valueGetter,
    this.valueSetter,
    this.errorGetter,
    this.valueStringGetter,
    this.valueStringifier,
    this.valueEnumRange,
    this.valueNumLimits,
    this.sliderChanged,
    this.useSliderBorder = false,
    this.useSwitchBorder = true,
    this.boolStyle = IOFieldBoolStyle.latchingSwitch,
  }) : assert(!((T == num || T == int || T == double) && (valueNumLimits == null && valueEnumRange == null)));

  final InputDecoration idDecoration;
  final bool isReadOnly;
  final String tip;

  /// using ListenableBuilder for cases where value is not of the same type as valueListenable
  final Listenable valueListenable; // read/output update
  final ValueGetter<T?> valueGetter;
  final ValueSetter<T>? valueSetter;

  final ValueGetter<bool>? errorGetter; // true on error

  // value string precedence: valueStringGetter > valueStringifier > valueGetter().toString()
  final ValueGetter<String>? valueStringGetter;
  final Stringifier<T>? valueStringifier; // for enum and other range bound types

  final ({num min, num max})? valueNumLimits; // required for num type, slider and input range check on submit
  final List<T>? valueEnumRange; // enum or String selection, alternatively type as enum only

  final ValueChanged<T>? sliderChanged;

  final bool useSliderBorder;
  final bool useSwitchBorder;
  final IOFieldBoolStyle boolStyle;

  IOFieldConfig<T> copyWith({
    InputDecoration? idDecoration,
    bool? isReadOnly,
    String? tip,
    Listenable? valueListenable,
    ValueGetter<T?>? valueGetter,
    ValueSetter<T>? valueSetter,
    ValueGetter<bool>? errorGetter,
    ValueGetter<String>? valueStringGetter,
    Stringifier<T>? valueStringifier,
    List<T>? valueEnumRange,
    ValueChanged<T>? sliderChanged,
    bool? useSliderBorder,
    bool? useSwitchBorder,
    IOFieldBoolStyle? boolStyle,
  }) {
    return IOFieldConfig<T>(
      idDecoration: idDecoration ?? this.idDecoration,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      tip: tip ?? this.tip,
      valueListenable: valueListenable ?? this.valueListenable,
      valueGetter: valueGetter ?? this.valueGetter,
      valueSetter: valueSetter ?? this.valueSetter,
      errorGetter: errorGetter ?? this.errorGetter,
      valueStringGetter: valueStringGetter ?? this.valueStringGetter,
      valueStringifier: valueStringifier ?? this.valueStringifier,
      valueEnumRange: valueEnumRange ?? this.valueEnumRange,
      sliderChanged: sliderChanged ?? this.sliderChanged,
      useSliderBorder: useSliderBorder ?? this.useSliderBorder,
      useSwitchBorder: useSwitchBorder ?? this.useSwitchBorder,
      boolStyle: boolStyle ?? this.boolStyle,
    );
  }
}

extension on num {
  R to<R>() => switch (R) { const (int) => toInt(), const (double) => toDouble(), const (num) => this, _ => throw TypeError() } as R;
}

// utility for stateless views to rebuild the decorator accounting for error. optional for case of textfield
class IODecorator extends StatelessWidget {
  const IODecorator({required this.decoration, this.isError = false, required this.child, super.key});

  final InputDecoration decoration;
  final bool isError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var effectiveDecoration = decoration;

    if (isError) {
      final theme = Theme.of(context).inputDecorationTheme;
      effectiveDecoration = effectiveDecoration.copyWith(
        // use enabledBorder to display error, work around hiding error text.
        enabledBorder: theme.errorBorder, // if errorBorder is null, enabledBorder is set to null -> defaults to 'border' resolve material state
        prefixIconColor: theme.errorBorder?.borderSide.color,
        border: WidgetStateProperty.resolveAs(theme.border, {WidgetState.error}),
        floatingLabelStyle: theme.errorStyle ?? WidgetStateProperty.resolveAs(theme.floatingLabelStyle, {WidgetState.error}),
        labelStyle: theme.errorStyle ?? WidgetStateProperty.resolveAs(theme.labelStyle, {WidgetState.error}),
      );
    }

    return InputDecorator(decoration: effectiveDecoration, child: child); // InputDecorator applies theme default
  }
}

/// Updates on listenable change only, no user input
class IOFieldReader<T> extends StatelessWidget with _IOFieldStringBox<T> implements IOField<T> {
  const IOFieldReader({
    super.key,
    required this.decoration,
    required this.listenable,
    required this.valueGetter,
    this.valueStringGetter,
    this.valueStringifier,
    this.errorGetter,
    this.tip = '',
  });

  IOFieldReader.config(IOFieldConfig<T> config, {super.key})
      : listenable = config.valueListenable,
        decoration = config.idDecoration,
        valueGetter = config.valueGetter,
        tip = config.tip,
        errorGetter = config.errorGetter,
        valueStringGetter = config.valueStringGetter,
        valueStringifier = config.valueStringifier;

  final Listenable listenable;
  final ValueGetter<T?> valueGetter;
  final InputDecoration decoration;
  final String tip;
  final ValueGetter<bool>? errorGetter;
  final ValueGetter<String>? valueStringGetter;
  final Stringifier<T>? valueStringifier;

  Widget builder(BuildContext context, Widget? child) {
    return IODecorator(
      decoration: decoration,
      isError: errorGetter?.call() ?? false,
      child: Text(_effectiveValueStringGetter(), maxLines: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final widget = ListenableBuilder(listenable: listenable, builder: builder);
    return Tooltip(message: tip, child: widget);
  }
}

typedef IOFieldNum = IOFieldText<num>;

/// T == num or String
// split sub types requires the default constructor to be a sub factory
class IOFieldText<T> extends StatefulWidget with _IOFieldStringBox<T> implements IOField<T> {
  const IOFieldText({
    super.key,
    required this.listenable,
    required this.valueGetter,
    this.valueSetter,
    this.decoration,
    this.numLimits,
    this.tip = '',
    this.errorGetter,
    this.valueStringGetter,
    this.valueStringifier,
  }) : assert(!((T == num || T == int || T == double) && (numLimits == null)));

  IOFieldText.config(IOFieldConfig<T> config, {super.key})
      : listenable = config.valueListenable,
        decoration = config.idDecoration,
        valueGetter = config.valueGetter,
        valueSetter = config.valueSetter,
        tip = config.tip,
        numLimits = config.valueNumLimits,
        errorGetter = config.errorGetter,
        valueStringifier = config.valueStringifier,
        valueStringGetter = config.valueStringGetter;

  final Listenable listenable;
  final InputDecoration? decoration;
  final ValueGetter<T?> valueGetter;
  final ValueSetter<T>? valueSetter;
  final String tip;
  final ValueGetter<String>? valueStringGetter; // num or String does not need other conversion, unless user implements precision
  final Stringifier<T>? valueStringifier;
  final ValueGetter<bool>? errorGetter;
  final ({num min, num max})? numLimits; // required for num type only

  /// num only
  num get numMin => numLimits!.min;
  num get numMax => numLimits!.max;

  List<TextInputFormatter>? get inputFormatters {
    return switch (T) {
      const (int) => [FilteringTextInputFormatter.digitsOnly, FilteringTextInputFormatter.singleLineFormatter],
      const (double) || const (num) => [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')), FilteringTextInputFormatter.singleLineFormatter],
      const (String) => null,
      _ => throw TypeError(),
    };
  }

  TextInputType get keyboardType {
    return switch (T) {
      const (int) => const TextInputType.numberWithOptions(decimal: false, signed: true),
      const (double) || const (num) => const TextInputType.numberWithOptions(decimal: true, signed: true),
      const (String) => TextInputType.text,
      _ => throw TypeError(),
    };
  }

  @override
  State<IOFieldText<T>> createState() => _IOFieldTextState<T>();
}

class _IOFieldTextState<T> extends State<IOFieldText<T>> {
  final TextEditingController textController = TextEditingController();
  final WidgetStatesController materialStates = WidgetStatesController();
  final FocusNode focusNode = FocusNode();

  late final ValueSetter<String> submitText = switch (T) { const (int) || const (double) || const (num) => submitTextNum, const (String) => submitTextString, _ => throw TypeError() };

  // num? validNum(String numString) {
  // if (num.tryParse(numString) case num numValue when numValue.clamp(widget.numMin, widget.numMax) == numValue) return numValue;
  // return null; // null or out of bounds
  // }

  /// num type
  num? validNum(String numString) {
    return num.tryParse(numString)?.clamp(widget.numMin, widget.numMax);
  }

  // optionally use to clamp bounds 'as-you-type'
  num? validateNumText(String numString) {
    final num? result = validNum(numString);
    materialStates.update(WidgetState.error, result != null);
    return result;
  }

  // num type must define min and max
  void submitTextNum(String numString) {
    if (validateNumText(numString) case num validNum) {
      widget.valueSetter?.call(validNum.to<T>());
    }
  }

  /// String type
  void submitTextString(String string) => widget.valueSetter?.call(string as T);

  @override
  void initState() {
    focusNode.addListener(updateOnFocusLoss);
    textController.text = widget._effectiveValueStringGetter();
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    materialStates.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void updateOnFocusLoss() {
    if (!focusNode.hasFocus) {
      textController.text = widget._effectiveValueStringGetter();
      // if submit on focus loss
      // onSubmitted(textController.text);
    }
  }

  void onSubmitted(value) {
    submitText(value);
    // if use notification
    // context.dispatchNotification(IOFieldNotification(message: value));
  }

  /// handles updates from getter/listenable
  Widget _builder(BuildContext context, Widget? child) {
    textController.text = widget._effectiveValueStringGetter();
    if (widget.errorGetter != null) materialStates.update(WidgetState.error, widget.errorGetter!());
    return child!;
  }

// TextField update based on user input
// TextController update based on valueGetter, and propagates to TextField partial rebuild
  @override
  Widget build(BuildContext context) {
    final textField = ListenableBuilder(
      listenable: widget.listenable,
      builder: _builder,
      child: TextField(
        decoration: widget.decoration,
        controller: textController,
        statesController: materialStates,
        onSubmitted: onSubmitted,
        readOnly: false,
        showCursor: true,
        enableInteractiveSelection: true,
        enabled: true,
        expands: false,
        canRequestFocus: true,
        focusNode: focusNode,
        maxLines: 1,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        // onChanged: onChanged,
      ),
    );

    return Tooltip(message: widget.tip, child: textField);
  }
}

// class IOFieldNotification<T> extends Notification {
//   const IOFieldNotification({this.parsedValue, this.message});

//   final T? parsedValue;
//   final String? message;
// }

// enum IOFieldNotification with Notification {
// }

/// T is Enum, bool, or String
/// PopupMenu
/// class IOFieldEnum<T extends Enum>
class IOFieldMenu<T> extends StatelessWidget with _IOFieldStringBox<T> implements IOField<T> {
  IOFieldMenu({
    super.key,
    required this.listenable,
    required this.decoration,
    required this.valueGetter,
    required this.valueSetter,
    required this.valueEnumRange,
    this.valueStringifier,
    this.tip = '',
    this.errorGetter,
    this.initialValue,
    this.valueStringGetter,
  });

  IOFieldMenu.config(IOFieldConfig<T> config, {super.key})
      : listenable = config.valueListenable,
        decoration = config.idDecoration,
        valueGetter = config.valueGetter,
        valueSetter = config.valueSetter,
        errorGetter = config.errorGetter,
        valueEnumRange = config.valueEnumRange!,
        valueStringifier = config.valueStringifier,
        valueStringGetter = config.valueStringGetter,
        initialValue = null,
        tip = config.tip;

  final Listenable listenable;
  final InputDecoration decoration;
  final ValueGetter<T?> valueGetter;
  final ValueSetter<T>? valueSetter;
  final ValueGetter<bool>? errorGetter;
  final List<T> valueEnumRange;
  final ValueGetter<String>? valueStringGetter;
  final Stringifier<T>? valueStringifier;
  final T? initialValue;
  final String tip;

  // List<PopupMenuEntry<T>> buildEntries(BuildContext context) => [for (final entry in valueEnumRange) PopupMenuItem(value: entry, child: Text(_effectiveStringifier(entry)))];

  // cache on widget build. otherwise regenerate string values on each sub widget build
  late final _stringMap = {for (final entry in valueEnumRange) entry: _effectiveStringifier(entry)};
  late final _cachedEntries = [for (final entry in valueEnumRange) PopupMenuItem(value: entry, child: Text(_stringMap[entry]!))];
  List<PopupMenuEntry<T>> cachedItemBuilder(BuildContext context) => _cachedEntries; // the menu items do not need dynamic update
  String valueString() => _stringMap[valueGetter()] ?? valueGetter().toString();

  @override
  Widget build(BuildContext context) {
    final widget = PopupMenuButton<T>(
      itemBuilder: cachedItemBuilder,
      initialValue: valueGetter(),
      enabled: true,
      onSelected: valueSetter,
      clipBehavior: Clip.hardEdge,
      child: IOFieldReader<T>(
        key: key,
        listenable: listenable,
        decoration: decoration,
        tip: tip,
        valueGetter: valueGetter,
        valueStringGetter: valueString,
        errorGetter: errorGetter,
      ),
    );

    return Tooltip(message: tip, child: widget);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// Visual
/// connected widget using same config
////////////////////////////////////////////////////////////////////////////////
abstract interface class IOFieldVisual<T> extends IOField<T> {
  factory IOFieldVisual(IOFieldConfig<T> config, {Key? key}) {
    return switch (T) {
      const (int) => IOFieldSlider<int>(config as IOFieldConfig<int>),
      const (double) => IOFieldSlider<double>(config as IOFieldConfig<double>),
      const (num) => IOFieldSlider<num>(config as IOFieldConfig<num>),
      const (bool) => switch (config.boolStyle) {
          IOFieldBoolStyle.textMenu => IOFieldMenu<T>.config(config),
          IOFieldBoolStyle.latchingSwitch => IOFieldSwitch(config as IOFieldConfig<bool>) as IOField<T>,
          IOFieldBoolStyle.momentaryButton => IOFieldButton(config as IOFieldConfig<bool>) as IOField<T>,
        },
      _ => throw TypeError(),
    } as IOFieldVisual<T>;
  }
}

class IOFieldSlider<T extends num> extends StatelessWidget implements IOField<T>, IOFieldVisual<T> {
  const IOFieldSlider(this.config, {super.key});

  final IOFieldConfig<T> config;

  double get min => config.valueNumLimits!.min.toDouble();
  double get max => config.valueNumLimits!.max.toDouble();

  void onChanged(double value) => config.sliderChanged?.call(value.to<T>());
  void onChangeEnd(double value) => config.valueSetter?.call(value.to<T>());

  Widget builder(BuildContext context, Widget? child) {
    final value = config.valueGetter()?.toDouble().clamp(min, max);
    if (value == null) return const Text('Error');

    return Slider.adaptive(
      label: config.idDecoration.labelText,
      min: min,
      max: max,
      value: value,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: config.valueListenable, builder: builder);
}

// latching
class IOFieldSwitch extends StatelessWidget implements IOField<bool>, IOFieldVisual<bool> {
  const IOFieldSwitch(this.config, {super.key});

  final IOFieldConfig<bool> config;

  Widget builder(BuildContext context, Widget? child) {
    final value = config.valueGetter();
    if (value == null) return const Text('Error');

    final widget = Switch.adaptive(value: value, onChanged: config.valueSetter);

    if (config.useSwitchBorder) {
      return IODecorator(
        decoration: config.idDecoration,
        isError: config.errorGetter?.call() ?? false,
        child: widget,
      );
    }

    return widget;
  }

  @override
  Widget build(BuildContext context) {
    final widget = ListenableBuilder(listenable: config.valueListenable, builder: builder);
    return Tooltip(message: config.tip, child: widget);
  }
}

// class IOFieldBool extends StatelessWidget implements IOField<bool>, IOFieldVisual<bool> {}

// momentary
class IOFieldButton extends StatelessWidget implements IOField<bool>, IOFieldVisual<bool> {
  const IOFieldButton(this.config, {super.key});

  final IOFieldConfig<bool> config;

  Widget builder(BuildContext context, Widget? child) {
    final widget = ElevatedButton(onPressed: () => config.valueSetter?.call(true), child: Text(config.idDecoration.labelText ?? ''));

    if (config.useSwitchBorder) {
      return IODecorator(
        decoration: config.idDecoration,
        isError: config.errorGetter?.call() ?? false,
        child: widget,
      );
    }
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    final widget = ListenableBuilder(listenable: config.valueListenable, builder: builder);
    return Tooltip(message: config.tip, child: widget);
  }
}

enum IOFieldBoolStyle {
  textMenu, // true/false, on/off
  latchingSwitch,
  momentaryButton,
}

////////////////////////////////////////////////////////////////////////////////
/// Composites
////////////////////////////////////////////////////////////////////////////////
// class SelectableIOField<T> extends StatefulWidget {
//   const SelectableIOField({this.initialItem, super.key, required this.menuSource, required this.builder});

//   final FlyweightMenuSource<T> menuSource;
//   final T? initialItem;
//   // final ValueWidgetBuilder<T> builder;
//   // final ValueWidgetBuilder<T> builder;
//   final IOFieldConfig Function(T key) configBuilder;
//   // final Widget? child;

//   Widget effectiveBuilder(BuildContext context, T key, Widget? child) {
//     return IOField(configBuilder(key));
//   }

//   @override
//   State<SelectableIOField<T>> createState() => _SelectableIOFieldState<T>();
// }

// class _SelectableIOFieldState<T> extends State<SelectableIOField<T>> {
//   late final FlyweightMenu<T> menu = widget.menuSource.create(initialValue: widget.initialItem /*  onPressed: widget.onPressed */);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         FlyweightMenuButton<T>(menu: menu),
//         const VerticalDivider(thickness: 0, color: Colors.transparent),
//         // config rebuilds on varNotifier select update
//         Expanded(child: FlyweightMenuListenableBuilder<T>(menu: menu, builder: widget.effectiveBuilder)),
//       ],
//     );

//     // return ListTile(
//     //   // dense: true,
//     //   leading: menuSource.toButton(),
//     //   title: menuSource.contain((_, __) => _VarIOFieldBuilder.options(selectController.varNotifier, showLabel: true, isDense: false, showPrefix: true, showSuffix: true)),
//     // );
//   }
// }

// convenience for attaching the same config
class IOFieldWithSlider<T extends num> extends StatelessWidget implements IOField<T> {
  const IOFieldWithSlider(this.config, {this.breakWidth = 400, super.key});
  final int breakWidth;
  final IOFieldConfig<T> config;

  // Widget Function(BuildContext, Widget, Widget) builder;

  @override
  Widget build(BuildContext context) {
    final ioField = IOFieldText<T>.config(config);
    final slider = IOFieldSlider<T>(config);

    return LayoutBuilder(
      builder: (context, constraints) {
        return (constraints.maxWidth > breakWidth) ? Row(children: [Expanded(child: ioField), Expanded(flex: 2, child: slider)]) : OverflowBar(children: [ioField, slider]);
      },
    );
  }
}

extension InputDecorationHide on InputDecoration {
  InputDecoration copyWithHide({
    bool showLabel = true,
    bool showPrefix = true,
    bool showSuffix = true,
  }) {
    return InputDecoration(
      labelText: showLabel ? labelText : null,
      prefixIcon: showPrefix ? prefixIcon : null,
      prefixText: showPrefix ? prefixText : null,
      suffixIcon: showSuffix ? suffixIcon : null,
      suffixText: showSuffix ? suffixText : null,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      label: label ?? this.label,
      // labelText: labelText ?? this.labelText,
      labelStyle: labelStyle ?? this.labelStyle,
      floatingLabelStyle: floatingLabelStyle ?? this.floatingLabelStyle,
      helper: helper ?? this.helper,
      helperText: helperText ?? this.helperText,
      helperStyle: helperStyle ?? this.helperStyle,
      helperMaxLines: helperMaxLines ?? this.helperMaxLines,
      hintText: hintText ?? this.hintText,
      hintStyle: hintStyle ?? this.hintStyle,
      hintTextDirection: hintTextDirection ?? this.hintTextDirection,
      hintMaxLines: hintMaxLines ?? this.hintMaxLines,
      hintFadeDuration: hintFadeDuration ?? this.hintFadeDuration,
      error: error ?? this.error,
      errorText: errorText ?? this.errorText,
      errorStyle: errorStyle ?? this.errorStyle,
      errorMaxLines: errorMaxLines ?? this.errorMaxLines,
      floatingLabelBehavior: floatingLabelBehavior ?? this.floatingLabelBehavior,
      floatingLabelAlignment: floatingLabelAlignment ?? this.floatingLabelAlignment,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      isDense: isDense ?? this.isDense,
      contentPadding: contentPadding ?? this.contentPadding,
      // prefixIcon: prefixIcon ?? this.prefixIcon,
      // prefix: prefix ?? this.prefix,
      // prefixText: prefixText ?? this.prefixText,
      prefixStyle: prefixStyle ?? this.prefixStyle,
      prefixIconColor: prefixIconColor ?? this.prefixIconColor,
      prefixIconConstraints: prefixIconConstraints ?? this.prefixIconConstraints,
      // suffixIcon: suffixIcon ?? this.suffixIcon,
      // suffix: suffix ?? this.suffix,
      // suffixText: suffixText ?? this.suffixText,
      suffixStyle: suffixStyle ?? this.suffixStyle,
      suffixIconColor: suffixIconColor ?? this.suffixIconColor,
      suffixIconConstraints: suffixIconConstraints ?? this.suffixIconConstraints,
      counter: counter ?? this.counter,
      counterText: counterText ?? this.counterText,
      counterStyle: counterStyle ?? this.counterStyle,
      filled: filled ?? this.filled,
      fillColor: fillColor ?? this.fillColor,
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      errorBorder: errorBorder ?? this.errorBorder,
      focusedBorder: focusedBorder ?? this.focusedBorder,
      focusedErrorBorder: focusedErrorBorder ?? this.focusedErrorBorder,
      disabledBorder: disabledBorder ?? this.disabledBorder,
      enabledBorder: enabledBorder ?? this.enabledBorder,
      border: border ?? this.border,
      enabled: enabled ?? this.enabled,
      semanticCounterText: semanticCounterText ?? this.semanticCounterText,
      alignLabelWithHint: alignLabelWithHint ?? this.alignLabelWithHint,
      constraints: constraints ?? this.constraints,
    );
  }
}

/// IOField Enum
/// Editable Text Dropdown
/// output clamps right side with icon, text is editable
// class IOFieldDropdown<T> extends IOField<T> {
//   IOFieldDropdown(super.config, {super.key}) : super._();
//   IOFieldDropdown._(super.config, {super.key}) : super._();

//   late final List<DropdownMenuEntry<T>> entries = [for (final entry in config.stringMap!.entries) DropdownMenuEntry(value: entry.key, label: entry.value)];

//   // late final TextEditingController textController = TextEditingController(text: valueStringGetter());

//   void onSelected(T? value) {
//     if (value != null) config.valueSubmitter?.call(value);
//   }

//   @override
//   late final Widget builderChild = DropdownMenu<T>(
//     label: (fieldLabel != null) ? Text(fieldLabel!) : null,
//     dropdownMenuEntries: entries,
//     initialSelection: _value,
//     onSelected: onSelected,
//     trailingIcon: null,
//     enableSearch: false,
//     enableFilter: false,
//     enabled: true,
//   );

//   @override
//   Widget builder(BuildContext context, Widget? child) {
//     return child!;
//   }
// }
