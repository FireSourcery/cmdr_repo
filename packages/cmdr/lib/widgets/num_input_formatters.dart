import 'package:flutter/services.dart';

/// A leading `-` only when [signed], digits, and a single `.` with any number of decimals when [decimal].
/// [signed] follows the field's lower limit, [decimal] its value type; shared by the numeric text inputs.
List<TextInputFormatter> numInputFormatters({required bool signed, required bool decimal}) => [
  FilteringTextInputFormatter.allow(RegExp(r'^' + (signed ? r'-?' : '') + r'\d*' + (decimal ? r'\.?\d*' : ''))),
];
