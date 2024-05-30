import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Select using union config
// T functions as generic type, as well as selection parameter, unless explicitly defined
abstract interface class IOField<T> extends Widget {
  factory IOField(IOFieldConfig<T> config, {Key? key}) {
    if (config.isReadOnly) return IOFieldReader<T>.config(config: config);
    if (config.stringMap?.isNotEmpty ?? false) return IOFieldMenu<T>.config(config: config);

    return switch (config.valueGetter()) {
      // Enum() => IOFieldMenu<T>.config(config: config),
      num() => IOFieldText<T>.config(config: config),
      String() => IOFieldText<T>.config(config: config),
      bool() => IOFieldDecoratedSwitch(config: config as IOFieldConfig<bool>),
      // bool() when config.useBoolButton => IOFieldButton(config as IOFieldConfig<bool>),
      // bool() => IOFieldMenu<bool>(config as IOFieldConfig<bool>),
      _ => IOFieldReader<T>.config(config: config),
    } as IOField<T>;
  }

  factory IOField.withSlider(IOFieldConfig<T> config, {Key? key}) {
    assert(config.valueMin != null && config.valueMax != null);

    return switch (config.valueGetter()) {
      int() => IOFieldWithSlider<int>(config: config as IOFieldConfig<int>),
      double() => IOFieldWithSlider<double>(config: config as IOFieldConfig<double>),
      _ => throw TypeError(),
    } as IOField<T>;
  }

  // static R parseTo<R>(String numString) => num.parse(numString).to<R>();

  // factory IOField.withToggle(IOFieldConfig<bool> config, {Key? key}) {
  //   assert(T == bool);
  //   return _IOFieldDecoratedSwitch(config) as IOField<T>;
  // }

  // @override
  // Widget build(BuildContext context) => Tooltip(message: config.tip, child: _builder(BuildContext context ));
}

/// union of all modes config. effectively an immutable controller. pass to variations constructor for common interface
class IOFieldConfig<T> {
  const IOFieldConfig({
    required this.valueListenable,
    required this.valueGetter,
    this.valueErrorGetter,
    this.isReadOnly = false,
    this.stringMap,
    this.valueSetter,
    this.sliderChanged,
    this.valueMin, // required for num type, slider and input range check on submit
    this.valueMax,
    this.inputDecoration = const InputDecoration(),
    this.tip = '',
    this.valueStringGetter,
  }); //assert(!((T == num || T == int || T == double) && (config.valueMin == null || config.valueMax == null)));

  // IOFieldConfig.fromInterface(VarViewInterface<T> interface)
  //     : this(
  //         valueGetter: interface.getValue,
  //         valueListenable: interface.valueListenable,
  //         valueErrorGetter: interface.valueErrorGetter,
  //         isReadOnly: interface.isReadOnly,
  //         stringMap: interface.stringMap,
  //         valueSetter: interface.valueSetter,
  //         sliderChanged: interface.sliderChanged,
  //         valueMin: interface.valueMin,
  //         valueMax: interface.valueMax,
  //         inputDecoration: interface.inputDecoration,
  //         tip: interface.tip,
  //         valueStringGetter: interface.valueStringGetter,
  //       );

  final InputDecoration inputDecoration;
  final bool isReadOnly;
  final String tip;

  /// using ListenableBuilder for cases where value is not of the same type as valueListenable
  final Listenable valueListenable; // read/output update
  final ValueGetter<T> valueGetter;

  final ValueGetter<bool>? valueErrorGetter; // true on error, or use MaterialStatesController
  final ValueGetter<String>? valueStringGetter;
  final ValueSetter<T>? valueSetter;

// ValueWidgetBuilder<T>
  // Enum or bool?
  final Map<T, String>? stringMap; //  enum Key : label
  final num? valueMin;
  final num? valueMax;
  //todo combine
  // final (num min, num max)? numLimits; // required for num type, slider and input range check on submit

  final ValueChanged<T>? sliderChanged;
  // final bool useBoolButton;

  // String? get fieldLabel => config.inputDecoration?.labelText;

  IOFieldConfig<T> copyWith({
    InputDecoration? inputDecoration,
    bool? isReadOnly,
    String? tip,
    Listenable? valueListenable,
    ValueGetter<T>? valueGetter,
    ValueGetter<bool>? valueErrorGetter,
    ValueGetter<String>? valueStringGetter,
    ValueSetter<T>? valueSetter,
    Map<T, String>? stringMap,
    num? valueMin,
    num? valueMax,
    ValueChanged<T>? sliderChanged,
  }) {
    return IOFieldConfig<T>(
      inputDecoration: inputDecoration ?? this.inputDecoration,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      tip: tip ?? this.tip,
      valueListenable: valueListenable ?? this.valueListenable,
      valueGetter: valueGetter ?? this.valueGetter,
      valueErrorGetter: valueErrorGetter ?? this.valueErrorGetter,
      valueStringGetter: valueStringGetter ?? this.valueStringGetter,
      valueSetter: valueSetter ?? this.valueSetter,
      stringMap: stringMap ?? this.stringMap,
      valueMin: valueMin ?? this.valueMin,
      valueMax: valueMax ?? this.valueMax,
      sliderChanged: sliderChanged ?? this.sliderChanged,
    );
  }
}

extension on num {
  R to<R>() => switch (R) { const (int) => toInt(), const (double) => toDouble(), _ => throw TypeError() } as R;
}

// case of InputDecorator, manually update error
// - use enabledBorder to display error, work around hiding error text, optional for case of textfield
class IOFieldDecorator extends StatelessWidget {
  const IOFieldDecorator({required this.decoration, this.isError = false, required this.child, super.key});

  final InputDecoration decoration;
  final bool isError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var effectiveDecoration = decoration;
    late final theme = Theme.of(context).inputDecorationTheme;

    if (isError) {
      effectiveDecoration = effectiveDecoration.copyWith(
        enabledBorder: theme.errorBorder, // if errorBorder is null, enabledBorder is set to null, => default to 'border' resolve material state
        border: MaterialStateProperty.resolveAs(theme.border, {MaterialState.error}),
        prefixIconColor: theme.errorBorder?.borderSide.color,
        floatingLabelStyle: MaterialStateProperty.resolveAs(theme.floatingLabelStyle, {MaterialState.error}) ?? theme.errorStyle,
      );
    }

    return InputDecorator(decoration: effectiveDecoration, child: child); // InputDecorator applies theme default
  }
}

/// Updates on listenable change only, no user input
class IOFieldReader<T> extends StatelessWidget implements IOField<T> {
  const IOFieldReader({super.key, required this.decoration, required this.listenable, this.tip = '', required this.valueGetter, this.valueStringGetter, this.errorGetter});

  IOFieldReader.config({required IOFieldConfig<T> config, super.key})
      : listenable = config.valueListenable,
        decoration = config.inputDecoration,
        valueGetter = config.valueGetter,
        tip = config.tip,
        errorGetter = config.valueErrorGetter,
        valueStringGetter = config.valueStringGetter;

  final Listenable listenable;
  final InputDecoration decoration;
  final ValueGetter<T?> valueGetter;
  final String tip;
  final ValueGetter<bool>? errorGetter;
  final ValueGetter<String>? valueStringGetter; // enums may define user friendly string

  String _getText() => valueGetter().toString();

  @override
  Widget build(BuildContext context) {
    final ValueGetter<String> textGetter = valueStringGetter ?? _getText;

    final widget = ListenableBuilder(
      listenable: listenable,
      builder: (context, child) {
        return IOFieldDecorator(
          decoration: decoration,
          isError: errorGetter?.call() ?? false,
          child: Text(textGetter(), maxLines: 1),
        );
      },
    );

    return Tooltip(message: tip, child: widget);
  }
}

/// T == num or String
// textField rebuild based on user input
// textController update based on control logic, and propagates to partial textfield rebuild
class IOFieldText<T> extends StatefulWidget implements IOField<T> {
  const IOFieldText(
      {required this.listenable, required this.valueGetter, this.valueSetter, this.decoration, this.numMin, this.numMax, super.key, this.tip = '', this.errorGetter, this.valueStringGetter});

  IOFieldText.config({required IOFieldConfig<T> config, super.key})
      : listenable = config.valueListenable,
        decoration = config.inputDecoration,
        valueGetter = config.valueGetter,
        valueSetter = config.valueSetter,
        tip = config.tip,
        numMin = config.valueMin,
        numMax = config.valueMax,
        errorGetter = config.valueErrorGetter,
        valueStringGetter = config.valueStringGetter;

  final Listenable listenable;
  final InputDecoration? decoration;
  final ValueGetter<T?> valueGetter;
  final ValueSetter<T>? valueSetter;
  final String tip;
  final ValueGetter<String>? valueStringGetter; // // num or String does not need other conversion, unless user implements precision
  final ValueGetter<bool>? errorGetter;
  // required for num type only, alternatively value setter checks for bounds
  final num? numMin;
  final num? numMax;

  String _getText() => valueGetter().toString();

  //  num.parse(numString).clamp(numMin!, numMax!)
  void submitTextNum(String numString) => valueSetter?.call(num.parse(numString).to<T>());
  void submitTextString(String string) => valueSetter?.call(string as T);

  @override
  State<IOFieldText<T>> createState() => _IOFieldTextState<T>();
}

class _IOFieldTextState<T> extends State<IOFieldText<T>> {
  final List<TextInputFormatter>? inputFormatters = switch (T) {
    const (int) => [FilteringTextInputFormatter.digitsOnly],
    const (double) || const (num) => [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))],
    _ => null,
  };

  final TextEditingController textController = TextEditingController();
  final MaterialStatesController materialStates = MaterialStatesController();
  final FocusNode focusNode = FocusNode();

  // alternatively resolve in initializer list
  late final ValueSetter<String> onSubmitted = switch (T) { const (int) || const (double) || const (num) => widget.submitTextNum, const (String) => widget.submitTextString, _ => throw TypeError() };
  late final ValueChanged<String>? onChanged = switch (T) { const (int) || const (double) || const (num) when (widget.numMin != null && widget.numMax != null) => changedTextNum, _ => null };
  late final ValueGetter<String> textGetter = widget.valueStringGetter ?? widget._getText;

  // todo optionally check bounds
  void changedTextNum(String numString) {
    final value = numString.isNotEmpty ? num.parse(numString) : 0;
    materialStates.update(MaterialState.error, (value.clamp(widget.numMin!, widget.numMax!) != value));
  }

  void updateOnFocusLoss() {
    if (!focusNode.hasFocus) onSubmitted(textController.text);
  }

  @override
  void initState() {
    focusNode.addListener(updateOnFocusLoss);
    textController.text = textGetter();
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    materialStates.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textField = ListenableBuilder(
      listenable: widget.listenable,
      builder: (context, child) {
        textController.text = textGetter();
        if (widget.errorGetter != null) materialStates.update(MaterialState.error, widget.errorGetter!());
        return child!;
      },
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
        // focusNode: ,
        maxLines: 1,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: inputFormatters,
        onChanged: onChanged,
      ),
    );

    return Tooltip(message: widget.tip, child: textField);
  }
}

/// PopupMenu
class IOFieldMenu<T> extends StatelessWidget implements IOField<T> {
  const IOFieldMenu({
    super.key,
    required this.listenable,
    required this.decoration,
    required this.valueGetter,
    required this.valueSetter,
    required this.stringMap,
    this.tip = '',
    this.errorGetter,
    this.initialValue,
  });

  IOFieldMenu.config({required IOFieldConfig<T> config, super.key})
      : listenable = config.valueListenable,
        decoration = config.inputDecoration,
        valueGetter = config.valueGetter,
        valueSetter = config.valueSetter,
        errorGetter = config.valueErrorGetter,
        stringMap = config.stringMap ?? {},
        initialValue = null,
        tip = config.tip;

  final Listenable listenable;
  final InputDecoration decoration;
  final ValueGetter<T?> valueGetter;
  final ValueSetter<T>? valueSetter;
  final String tip;
  final ValueGetter<bool>? errorGetter;
  final Map<T, String> stringMap; // alternatively pass list of enums, + optional string list/getter
  final T? initialValue;

  List<PopupMenuEntry<T>> entries(BuildContext context) => [for (final entry in stringMap.entries) PopupMenuItem(value: entry.key, child: Text(entry.value))];

  String getText() => stringMap[valueGetter()] ?? valueGetter().toString();

  @override
  Widget build(BuildContext context) {
    // final ValueGetter<String> textGetter = (() => stringMap[valueGetter()] ?? valueGetter().toString());

    final widget = PopupMenuButton<T>(
      itemBuilder: entries,
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
        valueStringGetter: getText,
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
    return switch (config.valueGetter()) {
      int() => IOFieldSlider<int>(config: config as IOFieldConfig<int>),
      double() => IOFieldSlider<double>(config: config as IOFieldConfig<double>),
      bool() => IOFieldSwitch(config: config as IOFieldConfig<bool>),
      // bool() => IOFieldButton(config as IOFieldConfig<bool>),
      // bool()  => IOFieldDecoratedSwitch(config as IOFieldConfig<bool>),
      _ => throw TypeError(),
    } as IOFieldVisual<T>;
  }
}

class IOFieldSlider<T extends num> extends StatelessWidget implements IOField<T>, IOFieldVisual<T> {
  const IOFieldSlider({required this.config, super.key});

  final IOFieldConfig<T> config;

  void submitValue(double value) => config.valueSetter?.call(value.to<T>());
  void updateVisual(double value) => config.sliderChanged?.call(value.to<T>());

  @override
  Widget build(BuildContext context) {
    final min = config.valueMin!.toDouble();
    final max = config.valueMax!.toDouble();

    return ListenableBuilder(
      listenable: config.valueListenable,
      builder: (context, child) {
        return Slider.adaptive(
          label: config.inputDecoration.labelText,
          min: min,
          max: max,
          value: config.valueGetter().clamp(min, max).toDouble(),
          onChanged: updateVisual,
          onChangeEnd: submitValue,
        );
      },
    );
  }
}

// latching
class IOFieldSwitch extends StatelessWidget implements IOField<bool>, IOFieldVisual<bool> {
  const IOFieldSwitch({required this.config, super.key});

  final IOFieldConfig<bool> config;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: config.valueListenable,
      builder: (context, child) => Switch.adaptive(value: config.valueGetter(), onChanged: config.valueSetter),
    );
  }
}

// momentary
class IOFieldButton extends StatelessWidget implements IOField<bool>, IOFieldVisual<bool> {
  const IOFieldButton({required this.config, super.key});

  final IOFieldConfig<bool> config;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: config.valueListenable,
      builder: (context, child) => ElevatedButton(onPressed: () => config.valueSetter?.call(true), child: Text(config.inputDecoration.labelText ?? '')),
    );
  }
}

class IOFieldDecoratedSwitch extends StatelessWidget implements IOField<bool>, IOFieldVisual<bool> {
  const IOFieldDecoratedSwitch({required this.config, super.key});

  final IOFieldConfig<bool> config;

  @override
  Widget build(BuildContext context) {
    final widget = ListenableBuilder(
      listenable: config.valueListenable,
      builder: (context, child) {
        return IOFieldDecorator(
          decoration: config.inputDecoration,
          isError: config.valueErrorGetter?.call() ?? false,
          child: Switch.adaptive(value: config.valueGetter(), onChanged: config.valueSetter),
        );
      },
    );

    return Tooltip(message: config.tip, child: widget);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// Combined View
////////////////////////////////////////////////////////////////////////////////
class IOFieldWithSlider<T extends num> extends StatelessWidget implements IOField<T> {
  const IOFieldWithSlider({required this.config, this.breakWidth = 400, super.key});
  final int breakWidth;
  final IOFieldConfig<T> config;

  @override
  Widget build(BuildContext context) {
    final ioField = IOFieldText<T>.config(config: config);
    final slider = IOFieldSlider<T>(config: config);

    return LayoutBuilder(
      builder: (context, constraints) {
        return (constraints.maxWidth > breakWidth) ? Row(children: [Expanded(child: ioField), Expanded(flex: 2, child: slider)]) : OverflowBar(children: [ioField, slider]);
      },
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
