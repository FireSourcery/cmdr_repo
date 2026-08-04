import 'dart:ffi';
import 'dart:typed_data';

import 'package:struct_data/binary_data.dart';
import 'package:struct_data/general/enumerated.dart';

/// [BinarizableData] stops at `dataMap` — it is the view/state layer and knows nothing about byte
/// widths. Each blob serializes its own `dataMap`, since the word size and the reserved space are
/// properties of that blob's segment, not of calibration data in general.

/// [BinarizableField]
///
/// Key carrying both descriptors: the view side value ([EnumeratedField], type [V]) and the data
/// side slot ([TypedField], native type [B]). A field's two representations are independent — [V] is
/// what the form edits, [B] is what the segment stores — so both are named.
abstract mixin class BinarizableField<V, B extends NativeType> implements EnumeratedField<V>, TypedField<B> {
  // TypedField<B> get transport => this; optionally compose
  @override
  int getWord(ByteData byteData) => byteData.wordAt<B>(offset);

  // BinaryFormat<B, V> get format;
  // Map<BinarizableField, BinaryFormat> get mapSchema;
}

/// [BinarizableData]
///
/// Common state for a calibration blob.
/// [isLoaded] — has this app side copy been read from the device.
/// [isWritten] — does the device segment hold a value, or is it still erased.
///
/// [K] keys the view fields, [V] is their view side type — `int` where the view value is already a
/// device word, `num` where the view holds a converted (fractional) quantity.
///
/// Type specific parts are the hooks: the not-yet-loaded sentinel, the canonical to data side
/// conversion, and which fields distinguish an erased segment from a written one.
mixin BinarizableData<K extends BinarizableField, V> {
  static const int flashErasePattern = 0xFFFF; // const: [isWritten] depends on it

  /// Not-yet-loaded sentinel. Distinct from [flashErasePattern] so [isLoaded] can tell
  /// "never read from the device" apart from "read, and the device segment is still erased".
  Object get initValue;

  String get name; // view name

  /// Values compared against [flashErasePattern]. Defaults to the whole segment.
  /// Override where only part of the segment marks it as written.
  Iterable<int> get writtenMarkers => dataMap.values;

  bool get isLoaded => (this != initValue);

  bool get isWritten => writtenMarkers.any((value) => value != flashErasePattern);

  // for view
  bool get isWritable => isLoaded && !isWritten;

  /// Device side values, derived from the canonical view values.
  /// The single conversion point — serialization and [writtenMarkers] both read it.
  Map<K, int> get dataMap;

  /// Typed views. [Enumerated.toMap] is `Map<K, Object?>`; these keep the numeric scope that the
  /// form fields and the confirmation table need.
  List<K> get keys;
  Map<K, V> get valueMap;
  Iterable<MapEntry<K, V>> get entries => valueMap.entries;

  // Map<K, int> mapFromByteData(TypedData data);
  TypedData toByteData();
}

// // extension type const BinaryForm(List<)
// extension B<K extends BinaryField> on ByteForm<K> {
//   ({StructForm<K, int> type, StructData<K, int> data}) _create() => this(create());

//   Map<ByteField, Object?> fromBinary(ByteStruct binary) => {for (final key in fields) key: key.format.decode(binary[key])};
// }
