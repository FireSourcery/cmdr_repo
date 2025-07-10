// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class NumTextField<T> extends StatefulWidget {
//   const NumTextField({
//     super.key,
//     required this.valueGetter,
//     this.valueSetter,
//     this.decoration,
//     this.numLimits,
//     this.tip = '',
//     this.valueStringGetter,
//     // this.valueStringifier,
//     this.controller,
//   }) : assert(!((T == num || T == int || T == double) && (numLimits == null)));

//   final InputDecoration? decoration;
//   final ValueGetter<T?> valueGetter;
//   final ValueSetter<T>? valueSetter;
//   final String tip;
//   final ValueGetter<String>? valueStringGetter; // num or String does not need other conversion, unless user implements precision
//   // final Stringifier<T>? valueStringifier;
//   final ({num min, num max})? numLimits; // required for num type only

//   final TextEditingController? controller;

//   /// num only
//   num get numMin => numLimits!.min;
//   num get numMax => numLimits!.max;

//   List<TextInputFormatter>? get inputFormatters {
//     return switch (T) {
//       const (int) => [FilteringTextInputFormatter.digitsOnly, FilteringTextInputFormatter.singleLineFormatter],
//       const (double) || const (num) => [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')), FilteringTextInputFormatter.singleLineFormatter],
//       const (String) => null,
//       _ => throw TypeError(),
//     };
//   }

//   TextInputType get keyboardType {
//     return switch (T) {
//       const (int) => const TextInputType.numberWithOptions(decimal: false, signed: true),
//       const (double) || const (num) => const TextInputType.numberWithOptions(decimal: true, signed: true),
//       const (String) => TextInputType.text,
//       _ => throw TypeError(),
//     };
//   }

//   @override
//   State<NumTextField<T>> createState() => _NumTextFieldState<T>();
// }

// class _NumTextFieldState<T> extends State<NumTextField<T>> {
//   final TextEditingController textController = TextEditingController();
//   final WidgetStatesController materialStates = WidgetStatesController();
//   final FocusNode focusNode = FocusNode();

//   late final ValueSetter<String> submitText = switch (T) { const (int) || const (double) || const (num) => submitTextNum, const (String) => submitTextString, _ => throw TypeError() };

//   // num? validNum(String numString) {
//   // if (num.tryParse(numString) case num numValue when numValue.clamp(widget.numMin, widget.numMax) == numValue) return numValue;
//   // return null; // null or out of bounds
//   // }

//   /// num type
//   num? validNum(String numString) {
//     return num.tryParse(numString)?.clamp(widget.numMin, widget.numMax);
//   }

//   // optionally use to clamp bounds 'as-you-type'
//   num? validateNumText(String numString) {
//     final num? result = validNum(numString);
//     materialStates.update(WidgetState.error, result != null);
//     return result;
//   }

//   // num type must define min and max
//   void submitTextNum(String numString) {
//     if (validateNumText(numString) case num validNum) {
//       widget.valueSetter?.call(validNum.to<T>());
//     }
//   }

//   /// String type
//   void submitTextString(String string) => widget.valueSetter?.call(string as T);

//   @override
//   void initState() {
//     focusNode.addListener(updateOnFocusLoss);
//     textController.text = widget._effectiveValueStringGetter();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     textController.dispose();
//     materialStates.dispose();
//     focusNode.dispose();
//     super.dispose();
//   }

//   void updateOnFocusLoss() {
//     if (!focusNode.hasFocus) {
//       textController.text = widget._effectiveValueStringGetter();
//       // if submit on focus loss
//       // onSubmitted(textController.text);
//     }
//   }

//   void onSubmitted(value) {
//     submitText(value);
//     // if use notification
//     // context.dispatchNotification(IOFieldNotification(message: value));
//   }

//   /// handles updates from getter/listenable
//   Widget _builder(BuildContext context, Widget? child) {
//     textController.text = widget._effectiveValueStringGetter();
//     if (widget.errorGetter != null) materialStates.update(WidgetState.error, widget.errorGetter!());
//     return child!;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final textField = TextField(
//       decoration: widget.decoration,
//       controller: textController,
//       statesController: materialStates,
//       onSubmitted: onSubmitted,
//       readOnly: false,
//       showCursor: true,
//       enableInteractiveSelection: true,
//       enabled: true,
//       expands: false,
//       canRequestFocus: true,
//       focusNode: focusNode,
//       maxLines: 1,
//       keyboardType: widget.keyboardType,
//       inputFormatters: widget.inputFormatters,
//       // onChanged: onChanged,
//     );

//     return Tooltip(message: widget.tip, child: textField);
//   }
// }
