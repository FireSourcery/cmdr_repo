import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../type_ext/stringifier.dart';

/// [IOField] is effectively a view union of IO types styled similar to a [TextField]
abstract class IOField<T> implements Widget {
  /// Select widget using union config
  /// T functions as generic type, as well as selection parameter, unless explicitly defined
  factory IOField(IOFieldConfig<T> config, {Key? key}) {
    // Nullable type patterns (num?, Enum?, ...) so a nullable value type (T == int?) dispatches
    // to the same widget as its base type; the widgets handle the nullable value.
    return switch (config) {
      IOFieldConfig(isReadOnly: true) => IOFieldReader<T>.config(config),
      IOFieldConfig(valueEnumRange: != null) => IOFieldMenu<T>.config(config),
      IOFieldConfig<num?>() => IOFieldText<T>.config(config),
      IOFieldConfig<Enum?>() => IOFieldMenu<T>.config(config),
      IOFieldConfig<String?>(valueEnumRange: null) => IOFieldText<T>.config(config),
      IOFieldConfig<bool?>(:final boolStyle) => switch (boolStyle) {
        IOFieldBoolStyle.textMenu => IOFieldMenu<T>.config(config),
        IOFieldBoolStyle.latchingSwitch => IOFieldSwitch<T>(config),
        IOFieldBoolStyle.momentaryButton => IOFieldButton<T>(config),
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

  // @override
  // Widget build(BuildContext context) => Tooltip(message: config.tip, child: _builder(BuildContext context ));
}

/// [IOFieldConfig<T>] Configuration class for IOField
/// This class encapsulates the parameters and settings required to configure an IOField
///
/// Effectively:
/// The IOField generative constructor, which can be shared without inheritance
/// Union of all mode/subtype parameters. pass to subtype variations' constructors as a common interface
/// optionally as var widdget interface
class const IOFieldConfig<T>({
  final InputDecoration idDecoration = const InputDecoration(),
  final bool isReadOnly = false, // alternatively move this to constructor parameter
  final String tip = '',

  /// using Listenable for cases where value is not of the same type as valueListenable
  required final Listenable valueListenable,
  required final ValueGetter<T> valueGetter,
  final ValueSetter<T>? valueSetter,
  final ValueGetter<bool>? errorGetter,
  final Stringifier<T>? valueStringifier,
  final List<T>? valueEnumRange,
  final ({num min, num max})? valueNumLimits,
  final ValueChanged<T>? valueChanged,
  // this.useSliderBorder = false,
  final bool useSwitchBorder = true,
  final IOFieldBoolStyle boolStyle = IOFieldBoolStyle.latchingSwitch,
}) {
  // using input decoration to hold label fields
  // read/output update
  // caller handles nullability via T (e.g. IOFieldConfig<Foo?>)
  // slider only for now
  // true on error
  // the single value -> display string interface. defaults to valueGetter().toString().
  // also stringifies each [valueEnumRange] entry for menu labels.
  // required for num type, slider and input range check on submit
  // enum or String selection, alternatively type as enum only

  // final bool useSliderBorder;
  IOFieldConfig<T> copyWith({
    InputDecoration? idDecoration,
    bool? isReadOnly,
    String? tip,
    Listenable? valueListenable,
    ValueGetter<T>? valueGetter,
    ValueSetter<T>? valueSetter,
    ValueGetter<bool>? errorGetter,
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
      valueStringifier: valueStringifier ?? this.valueStringifier,
      valueEnumRange: valueEnumRange ?? this.valueEnumRange,
      valueChanged: sliderChanged ?? valueChanged,
      // useSliderBorder: useSliderBorder ?? this.useSliderBorder,
      useSwitchBorder: useSwitchBorder ?? this.useSwitchBorder,
      boolStyle: boolStyle ?? this.boolStyle,
    );
  }
}

/// Default value -> string conversion when no [Stringifier] is supplied.
String _stringifyDefault(Object? value) => value.toString();

/// Resolves a value's display string through its [Stringifier], defaulting to [toString].
/// The single string-viewing interface shared by all [IOField] subtypes.
String _viewString<T>(ValueGetter<T> valueGetter, Stringifier<T>? valueStringifier) {
  return (valueStringifier ?? _stringifyDefault)(valueGetter());
}

// utility for stateless views to rebuild the decorator accounting for error. optional for case of textfield
class const IODecorator({required final InputDecoration decoration, final bool isError = false, required final Widget child, super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    InputDecoration effectiveDecoration = decoration;

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
class IOFieldReader<T> extends StatelessWidget implements IOField<T> {
  const IOFieldReader({super.key, required this.decoration, required this.listenable, required this.valueGetter, this.valueStringifier, this.errorGetter, this.tip = ''});

  IOFieldReader.config(IOFieldConfig<T> config, {super.key})
    : listenable = config.valueListenable,
      decoration = config.idDecoration,
      valueGetter = config.valueGetter,
      tip = config.tip,
      errorGetter = config.errorGetter,
      valueStringifier = config.valueStringifier;

  final Listenable listenable;
  final ValueGetter<T> valueGetter;
  final InputDecoration decoration;
  final String tip;
  final ValueGetter<bool>? errorGetter;
  final Stringifier<T>? valueStringifier;

  Widget builder(BuildContext context, Widget? child) {
    return IODecorator(decoration: decoration, isError: errorGetter?.call() ?? false, child: Text(_viewString(valueGetter, valueStringifier)));
  }

  @override
  Widget build(BuildContext context) {
    final widget = ListenableBuilder(listenable: listenable, builder: builder);
    return Tooltip(message: tip, child: widget);
  }
}

/// Editable text field. The concrete subtype ([_IOFieldTextInt], [_IOFieldTextDouble],
/// [_IOFieldTextNum], [_IOFieldTextString]) carries the per-type keyboard, formatters, and
/// parsing. [IOFieldText.config] selects one by value type via pattern matching, so no runtime
/// type inspection (`switch (T)` / `is`) is needed once a subtype is chosen.
abstract class const IOFieldText<T>._config(IOFieldConfig<T> config, {super.key}) extends StatefulWidget implements IOField<T> {
  // int?/double? are matched before num? — both are subtypes of num?. Nullable patterns also
  // catch the non-nullable form (int <: int?), so a plain `int` field routes here too. Leaves
  // stay generic in T: a leaf fixed to `double?` can't be returned as IOFieldText<T> for a
  // non-null T (e.g. a VarIOField `double` field) — that cast throws at runtime.
  factory IOFieldText.config(IOFieldConfig<T> config, {Key? key}) {
    return switch (config) {
      IOFieldConfig<int?>() => _IOFieldTextInt<T>(config, key: key),
      IOFieldConfig<double?>() => _IOFieldTextDouble<T>(config, key: key),
      IOFieldConfig<num?>() => _IOFieldTextNum<T>(config, key: key),
      IOFieldConfig<String?>() => _IOFieldTextString<T>(config, key: key),
      _ => throw TypeError(),
    };
  }

  this
    : listenable = config.valueListenable,
      decoration = config.idDecoration,
      valueGetter = config.valueGetter,
      valueSetter = config.valueSetter,
      tip = config.tip,
      numLimits = config.valueNumLimits,
      errorGetter = config.errorGetter,
      valueStringifier = config.valueStringifier;

  final Listenable listenable;
  final InputDecoration? decoration;
  final ValueGetter<T> valueGetter;
  final ValueSetter<T>? valueSetter;
  final String tip;
  final Stringifier<T>? valueStringifier; // num or String does not need other conversion, unless user implements precision
  final ValueGetter<bool>? errorGetter;
  final ({num min, num max})? numLimits; // required for num subtypes

  num get numMin => numLimits!.min;
  num get numMax => numLimits!.max;

  /// handled by concrete subtype
  List<TextInputFormatter>? get inputFormatters;
  TextInputType get keyboardType;
  T? parse(String text);

  @override
  State<IOFieldText<T>> createState() => _IOFieldTextState<T>();
}

/// num/double/int share the decimal keyboard and clamp; double/int only narrow [parse].
class const _IOFieldTextNum<T>(super.config, {super.key}) extends IOFieldText<T> {
  this : assert(config.valueNumLimits != null, 'num field requires valueNumLimits'), super._config();
  @override
  List<TextInputFormatter>? get inputFormatters => [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')), FilteringTextInputFormatter.singleLineFormatter];
  @override
  TextInputType get keyboardType => const TextInputType.numberWithOptions(decimal: true, signed: true);
  @override
  T? parse(String text) => num.tryParse(text)?.clamp(numMin, numMax) as T?;
}

class const _IOFieldTextDouble<T>(super.config, {super.key}) extends _IOFieldTextNum<T> {
  @override
  T? parse(String text) => double.tryParse(text)?.clamp(numMin, numMax).toDouble() as T?;
}

class const _IOFieldTextInt<T>(super.config, {super.key}) extends _IOFieldTextNum<T> {
  @override
  List<TextInputFormatter>? get inputFormatters => [FilteringTextInputFormatter.digitsOnly, FilteringTextInputFormatter.singleLineFormatter];
  @override
  TextInputType get keyboardType => const TextInputType.numberWithOptions(decimal: false, signed: true);
  @override
  T? parse(String text) => int.tryParse(text)?.clamp(numMin, numMax).toInt() as T?;
}

class const _IOFieldTextString<T>(super.config, {super.key}) extends IOFieldText<T> {
  this : super._config();
  @override
  List<TextInputFormatter>? get inputFormatters => null;
  @override
  TextInputType get keyboardType => TextInputType.text;
  @override
  T? parse(String text) => text as T;
}

/// common State
class _IOFieldTextState<T>() extends State<IOFieldText<T>> {
  final TextEditingController textController = TextEditingController();
  final WidgetStatesController materialStates = WidgetStatesController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    focusNode.addListener(updateOnFocusLoss);
    textController.text = _viewString(widget.valueGetter, widget.valueStringifier);
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
      textController.text = _viewString(widget.valueGetter, widget.valueStringifier);
      // if submit on focus loss
      // onSubmitted(textController.text);
    }
  }

  void onSubmitted(String text) {
    final value = widget.parse(text);
    materialStates.update(WidgetState.error, value == null); // reject unparseable input
    if (value != null) widget.valueSetter?.call(value);
    // if use notification
    // context.dispatchNotification(IOFieldNotification(message: value));
  }

  /// handles updates from getter/listenable
  Widget _builder(BuildContext context, Widget? child) {
    textController.text = _viewString(widget.valueGetter, widget.valueStringifier);
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

/// T is Enum, bool, or String
/// PopupMenu
/// `class IOFieldEnum<T extends Enum>`
class IOFieldMenu<T> extends StatelessWidget implements IOField<T> {
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
  });

  IOFieldMenu.config(IOFieldConfig<T> config, {super.key})
    : listenable = config.valueListenable,
      decoration = config.idDecoration,
      valueGetter = config.valueGetter,
      valueSetter = config.valueSetter,
      errorGetter = config.errorGetter,
      valueEnumRange = config.valueEnumRange!,
      valueStringifier = config.valueStringifier,
      initialValue = null,
      tip = config.tip;

  final Listenable listenable;
  final InputDecoration decoration;
  final ValueGetter<T> valueGetter;
  final ValueSetter<T>? valueSetter;
  final ValueGetter<bool>? errorGetter;
  final List<T> valueEnumRange;
  final Stringifier<T>? valueStringifier;
  final T? initialValue;
  final String tip;

  // cache on widget build. otherwise regenerate string values on each sub widget build
  late final Map<T, String> _stringMap = {for (final entry in valueEnumRange) entry: (valueStringifier ?? _stringifyDefault)(entry)};
  late final _cachedEntries = [for (final entry in valueEnumRange) PopupMenuItem(value: entry, child: Text(_stringMap[entry]!))];
  List<PopupMenuEntry<T>> cachedItemBuilder(BuildContext context) => _cachedEntries; // the menu items do not need dynamic update
  // reuse the cached labels for the selected value; the reader resolves it against the current value.
  String _effectiveStringifier(T value) => _stringMap[value] ?? '';

  @override
  Widget build(BuildContext context) {
    final widget = PopupMenuButton<T>(
      itemBuilder: cachedItemBuilder,
      initialValue: valueGetter(),
      enabled: true,
      onSelected: valueSetter,
      clipBehavior: Clip.hardEdge,
      child: IOFieldReader<T>(key: key, listenable: listenable, decoration: decoration, tip: tip, valueGetter: valueGetter, valueStringifier: _effectiveStringifier, errorGetter: errorGetter),
    );

    return Tooltip(message: tip, child: widget);
  }
}

// latching. T is bool or bool?
class const IOFieldSwitch<T>(final IOFieldConfig<T> config, {super.key}) extends StatelessWidget implements IOField<T> {
  Widget builder(BuildContext context, Widget? child) {
    // a null value (e.g. an unset setting) reads as off
    final widget = Switch.adaptive(
      value: config.valueGetter() == true,
      onChanged: config.valueSetter == null ? null : (value) => config.valueSetter!(value as T),
    );

    if (config.useSwitchBorder) {
      return IODecorator(decoration: config.idDecoration, isError: config.errorGetter?.call() ?? false, child: widget);
    }

    return widget;
  }

  @override
  Widget build(BuildContext context) {
    final widget = ListenableBuilder(listenable: config.valueListenable, builder: builder);
    return Tooltip(message: config.tip, child: widget);
  }
}

// momentary. T is bool or bool?
class const IOFieldButton<T>(final IOFieldConfig<T> config, {super.key}) extends StatelessWidget implements IOField<T> {
  Widget builder(BuildContext context, Widget? child) {
    final widget = ElevatedButton(onPressed: () => config.valueSetter?.call(true as T), child: Text(config.idDecoration.labelText ?? ''));

    if (config.useSwitchBorder) {
      return IODecorator(decoration: config.idDecoration, isError: config.errorGetter?.call() ?? false, child: widget);
    }
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    final widget = ListenableBuilder(listenable: config.valueListenable, builder: builder);
    return Tooltip(message: config.tip, child: widget);
  }
}

enum IOFieldBoolStyle() {
  textMenu, // true/false, on/off
  latchingSwitch,
  momentaryButton,
}

///
extension InputDecorationHide on InputDecoration {
  InputDecoration copyWithHide({bool showLabel = true, bool showPrefix = true, bool showSuffix = true}) {
    return InputDecoration(
      labelText: showLabel ? labelText : null,
      prefixIcon: showPrefix ? prefixIcon : null,
      prefixText: showPrefix ? prefixText : null,
      suffixIcon: showSuffix ? suffixIcon : null,
      suffixText: showSuffix ? suffixText : null,
      icon: icon ?? icon,
      iconColor: iconColor ?? iconColor,
      label: label ?? label,
      // labelText: labelText ?? this.labelText,
      labelStyle: labelStyle ?? labelStyle,
      floatingLabelStyle: floatingLabelStyle ?? floatingLabelStyle,
      helper: helper ?? helper,
      helperText: helperText ?? helperText,
      helperStyle: helperStyle ?? helperStyle,
      helperMaxLines: helperMaxLines ?? helperMaxLines,
      hintText: hintText ?? hintText,
      hintStyle: hintStyle ?? hintStyle,
      hintTextDirection: hintTextDirection ?? hintTextDirection,
      hintMaxLines: hintMaxLines ?? hintMaxLines,
      hintFadeDuration: hintFadeDuration ?? hintFadeDuration,
      error: error ?? error,
      errorText: errorText ?? errorText,
      errorStyle: errorStyle ?? errorStyle,
      errorMaxLines: errorMaxLines ?? errorMaxLines,
      floatingLabelBehavior: floatingLabelBehavior ?? floatingLabelBehavior,
      floatingLabelAlignment: floatingLabelAlignment ?? floatingLabelAlignment,
      isCollapsed: isCollapsed ?? isCollapsed,
      isDense: isDense ?? isDense,
      contentPadding: contentPadding ?? contentPadding,
      // prefixIcon: prefixIcon ?? this.prefixIcon,
      // prefix: prefix ?? this.prefix,
      // prefixText: prefixText ?? this.prefixText,
      prefixStyle: prefixStyle ?? prefixStyle,
      prefixIconColor: prefixIconColor ?? prefixIconColor,
      prefixIconConstraints: prefixIconConstraints ?? prefixIconConstraints,
      // suffixIcon: suffixIcon ?? this.suffixIcon,
      // suffix: suffix ?? this.suffix,
      // suffixText: suffixText ?? this.suffixText,
      suffixStyle: suffixStyle ?? suffixStyle,
      suffixIconColor: suffixIconColor ?? suffixIconColor,
      suffixIconConstraints: suffixIconConstraints ?? suffixIconConstraints,
      counter: counter ?? counter,
      counterText: counterText ?? counterText,
      counterStyle: counterStyle ?? counterStyle,
      filled: filled ?? filled,
      fillColor: fillColor ?? fillColor,
      focusColor: focusColor ?? focusColor,
      hoverColor: hoverColor ?? hoverColor,
      errorBorder: errorBorder ?? errorBorder,
      focusedBorder: focusedBorder ?? focusedBorder,
      focusedErrorBorder: focusedErrorBorder ?? focusedErrorBorder,
      disabledBorder: disabledBorder ?? disabledBorder,
      enabledBorder: enabledBorder ?? enabledBorder,
      border: border ?? border,
      enabled: enabled ?? enabled,
      semanticCounterText: semanticCounterText ?? semanticCounterText,
      alignLabelWithHint: alignLabelWithHint ?? alignLabelWithHint,
      constraints: constraints ?? constraints,
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

// class IOFieldNotification<T> extends Notification {
//   const IOFieldNotification({this.parsedValue, this.message});

//   final T? parsedValue;
//   final String? message;
// }

// enum IOFieldNotification with Notification {
// }
