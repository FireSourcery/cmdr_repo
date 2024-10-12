import 'dart:collection';

extension TrimString on String {
  // String trimLeft(String chars) => replaceAll(RegExp('^[$chars]+'), '');
  // String trimRight(String chars) => replaceAll(RegExp('[$chars]+\$'), '');

  String trimNulls() => replaceAll(RegExp(r'^\u0000+|\u0000+$'), '');
  String keepNonNulls() => replaceAll(String.fromCharCode(0), '');
  String keepAlphaNumeric() => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}

// extension IterableIntExtensions on Iterable<int> {
//   /// String
//   /// toStringAsCharCodes
//   // String toStringAsEncoded([int start = 0, int? end]) => String.fromCharCodes(this, start, end);

//   String asString([int start = 0, int? end]) => String.fromCharCodes(this, start, end);

//   /// Match
//   /// indexOfSequence
//   int indexOfSequence(Iterable<int> match) => String.fromCharCodes(this).indexOf(String.fromCharCodes(match));
// }
 

// get as int
// extension StringOfList on List<int> {
//   // Chars use array index
//   // from User I/O as int literal
//   String charAsValue(int index) => this[index].toString(); // 1 => '1'
//   void setCharAsLiteral(int index, String value) => this[index] = int.parse(value); // '1' => 1
//   List<int> modifyAsValue(int index, String value) => this..[index] = int.parse(value); // '1' => 1

//   String charAsCode(int index) => String.fromCharCode(this[index]); // 0x31 => '1'
//   List<int> modifyAsCode(int index, String value) => this..[index] = value.runes.single; // '1' => 0x31
// }

// extension EnumValues on Enum {
//   static List<T> values<T extends Enum>() {
//     final T first = _firstEnumValue<T>();
//     final T last = _lastEnumValue<T>();
//     final int length = last.index - first.index + 1;
//     final List<T> result = List<T>.filled(length, first);
//     for (int i = 0; i < length; i++) {
//       result[i] = first + i;
//     }
//     return result;
//   }

//   static T _firstEnumValue<T extends Enum>() {
//     final T? result = _firstEnumValueOrNull<T>();
//     if (result == null) {
//       throw StateError('No enum values found');
//     }
//     return result;
//   }

//   static T? _firstEnumValueOrNull<T extends Enum>() {
//     for (T value in Enum.values<T>()) {
//       return value;
//     }
//     return null;
//   }

//   static T _lastEnumValue<T extends Enum>() {
//     final T? result = _lastEnumValueOrNull<T>();
//     if (result == null) {
//       throw StateError('No enum values found');
//     }
//     return result;
//   }

//   static T? _lastEnumValueOrNull<T extends Enum>() {
//     T? result;
//     for (T value in Enum.values<T>()) {
//       result = value;
//     }
//     return result;
//   }
// }
