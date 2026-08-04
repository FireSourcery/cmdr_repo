import 'dart:typed_data';

import 'package:struct_data/binary_data.dart';
import 'package:struct_data/general/enumerated.dart';

/// [BinarizableField]
///
/// Key carrying both descriptors: the view side value ([EnumeratedField], type [V]) and the data
/// side slot ([TypedField], native type [B]). A field's two representations are independent — [V] is
/// what the form edits, [B] is what the segment stores — so both are named.
///
/// Word access comes from [TypedField.getWord]/[TypedField.setWord], which resolve their width from
/// [B] per key. Nothing here or in [BinarizableData] names a width, so a struct may mix them.
abstract mixin class BinarizableField<V, B extends NativeType> implements EnumeratedField<V>, TypedField<B> {
  // TypedField<B> get transport; optionally compose

  // optionally with format for exact type decoding
  // BinaryFormat<B, V> get format;
  // Map<BinarizableField, BinaryFormat> get mapSchema;
}

/// Read each field's word out of [data]. Inverse of [BinarizableData.toByteData].
///
/// Static counterpart to [BinarizableData] — deserialization runs in a constructor, before there is
/// an instance to call, so the key list carries it.
extension BinarizableFields<K extends BinarizableField> on List<K> {
  int get lengthInBytes => fold<int>(0, (extent, key) => key.end > extent ? key.end : extent);

  // mapWithData
  Map<K, int> unpack(ByteData data) {
    if (data.lengthInBytes < lengthInBytes) throw const FormatException('BinarizableData: short buffer');
    return {for (final key in this) key: key.getWord(data)};
  }
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
///
// alternatively split FlashData from Binarizable transport handling
mixin BinarizableData<K extends BinarizableField<V, NativeType>, V> {
  String get name; // view name

  /// Typed views. [Enumerated.toMap] is `Map<K, Object?>`; these keep the numeric scope that the
  /// form fields and the confirmation table need.
  List<K> get keys;
  Map<K, V> get valueMap;
  Iterable<MapEntry<K, V>> get entries => valueMap.entries;

  /// Device side values, derived from the canonical view values.
  /// The single conversion point — serialization and [writtenMarkers] both read it.
  Map<K, int> get dataMap;

  /// Segment length. Defaults to the fields' extent; override where the segment reserves trailing
  /// space no field covers.
  int get lengthInBytes => keys.lengthInBytes;

  /// Serialize [dataMap]. Each key places its own word, at its own width.
  Uint8List toByteData() {
    final bytes = Uint8List(lengthInBytes)..fillRange(0, lengthInBytes, unwrittenByte);
    final buffer = ByteData.sublistView(bytes);
    for (final MapEntry(:key, :value) in dataMap.entries) {
      key.setWord(buffer, value);
    }
    return bytes;
  }

  //  NvmData
  static const int flashErasePattern = 0xFFFF; // const: [isWritten] depends on it
  /// Value of a byte no field writes — reserved space, and the gaps of a sparse layout.
  /// `0xFF` matches erased NOR flash, so an all-reserved segment round trips as still-erased.
  int get unwrittenByte => 0xFF;
  // todo merge flashErasePattern

  /// Not-yet-loaded sentinel. Distinct from [flashErasePattern] so [isLoaded] can tell
  /// "never read from the device" apart from "read, and the device segment is still erased".
  Object get initValue;

  /// Values compared against [flashErasePattern]. Defaults to the whole segment.
  /// Override where only part of the segment marks it as written.
  Iterable<int> get writtenMarkers => dataMap.values;

  bool get isLoaded => (this != initValue);

  bool get isWritten => writtenMarkers.any((value) => value != flashErasePattern);

  // for view
  bool get isWritable => isLoaded && !isWritten;
}

// mixin NvmData<K,V> on BinarizableData<K,V>
// {

// }
