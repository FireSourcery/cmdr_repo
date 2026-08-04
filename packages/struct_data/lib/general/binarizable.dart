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

/// The codec itself is on [TypedField] — [TypedFieldLayout.unpack] / [TypedFieldWords.pack].
/// It needs only offsets and widths, never the view side, so a composite whose view is not a keyed
/// map (mixed value types, nested structs) shares the same serializer without adopting
/// [BinarizableData]. Deserialization in particular runs in a constructor, before there is an
/// instance to call, so the key list carries it rather than the mixin.

/// [BinarizableData]
///
/// A struct whose canonical copy is the view side values, with the segment image derived on demand.
///
/// [K] keys the view fields, [V] is their view side type — `int` where the view value is already a
/// device word, `num` where the view holds a converted (fractional) quantity. The two are related
/// only through [dataMap]; that is the single conversion point.
///
/// Applies to any keyed struct that serializes. Storage lifecycle — has it been read, is the
/// segment still erased — is [NvmData].
mixin BinarizableData<K extends BinarizableField<V, NativeType>, V> {
  String get name; // view name

  /// Typed views. [Enumerated.toMap] is `Map<K, Object?>`; these keep the numeric scope that the
  /// form fields and the confirmation table need.
  List<K> get keys;
  Map<K, V> get valueMap;
  Iterable<MapEntry<K, V>> get entries => valueMap.entries;

  /// Device side values, derived from the canonical view values.
  Map<K, int> get dataMap;

  /// Segment length. Defaults to the fields' extent; override where the segment reserves trailing
  /// space no field covers.
  int get lengthInBytes => keys.lengthInBytes;

  /// Value of a byte no field writes — reserved space, and the gaps of a sparse layout.
  /// Zero fill by default; [NvmData] raises it to the erase pattern.
  int get unwrittenByte => 0x00;

  /// Serialize [dataMap]. Each key places its own word, at its own width.
  Uint8List toByteData() => dataMap.pack(lengthInBytes, unwrittenByte);
}

/// [NvmData]
///
/// A [BinarizableData] mirrored from an erasable non-volatile segment, which adds two states that
/// a plain struct does not have:
/// [isLoaded] — has this app side copy been read from the device.
/// [isWritten] — does the device segment hold a value, or is it still erased.
mixin NvmData<K extends BinarizableField<V, NativeType>, V> on BinarizableData<K, V> {
  /// Erased cells read as all ones.
  @override
  int get unwrittenByte => 0xFF;

  /// The word a fully erased slot reads back as — [unwrittenByte] across the slot's own width.
  /// Follows [K]'s width per key, so a `Uint32` field is not compared against a 16 bit pattern.
  int erasedWord(K key) => List.filled(key.size, unwrittenByte).fold(0, (word, byte) => (word << 8) | byte);

  /// Not-yet-loaded sentinel. Distinct from the erase pattern so [isLoaded] can tell
  /// "never read from the device" apart from "read, and the device segment is still erased".
  Object get initValue;

  bool get isLoaded => (this != initValue);

  /// Keys whose slots mark the segment as written. Defaults to every field.
  /// Override where a field may legitimately hold the erase pattern as a real value.
  Iterable<K> get writtenMarkers => keys;

  bool get isWritten => writtenMarkers.any((key) => dataMap[key] != erasedWord(key));

  // for view
  bool get isWritable => isLoaded && !isWritten;
}
