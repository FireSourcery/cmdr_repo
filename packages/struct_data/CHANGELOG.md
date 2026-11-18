## Unreleased

Breaking:
* The packet framework has its own library. `struct_data.dart` no longer exports it: import `package:struct_data/packet.dart`.
* Sources moved under `lib/src/`, except `lib/utilities/`, which stays importable file by file (`package:struct_data/utilities/num_ext.dart`). A deep import such as `package:struct_data/bits/bit_struct.dart` no longer resolves: import `struct_data.dart` or `packet.dart`.
* `binary_data.dart` is deprecated. It re-exports `struct_data.dart` and `packet.dart`, and is removed in the next release.
* The packet framework is rebuilt. Design, diagrams and what changed: `doc/packet_design.md`.
  * `PacketCodec` replaces `PacketFormat`. A protocol is a `const` codec with `PacketFrameFormat` shapes, and no `Packet` subclass or casters. Header access honours the shape's `endian`.
  * `Packet` is a mixin over `(codec, byteData)`, mixed into `PacketView` (a detached frame) and `PacketBuffer` (a frame being built).
  * Ids are `PacketId`, `PacketControlId`, `PacketPayloadId<V>` and `PacketRequestId<T, R>`; a request carries its answer's byte and codec. `PacketIdMap` builds a codec's id table.
  * `Payload.build` returns a `PayloadMeta`, and `Payload.parse` takes the frame's `PacketHeader`.
  * `PacketTransformer` frames a byte stream through a `HeaderParser`: `codec.transformer`.
* `Serializable<K>` is a typedef of `StructBase<K, Object?>`, keyed by its `SerializableField` enum; immutable copies come from the `Immutable<S>` mixin. It was a mixin keyed by the data class.
* `EnumByIndex.byIndex` throws a `RangeError` for an index outside the list when no default is given. It clamped to the nearest end.
* `EnumByIndex.resolve`, on the `List<T>` extension, returns null for a null, negative or out-of-range index. It clamped through `byIndex`.
* `ByteData.arrayAt` with a null length covers whole elements of `T` to the end of the view, and asserts that the request lies inside the view. `arrayOrNullAt` tests the same extent, counting `length` in elements of `T`; it compared the element count against bytes.
* `NumDataScale.dataOf` and the default conversion of `BinaryQuantityCodec` round to the nearest word. They truncated, which read a value back one count low about half the time. `BinaryQuantityCodec.encode` clamps the result to the format's `binaryRange`, so nothing out of range reaches the wire.
* Requires Dart 3.13 (primary constructors).

Added:
* `EnumeratedField` and `Enumerated`.
* `BinarizableField`, `BinarizableData` and `NvmData`: keyed structs whose view values serialize to a device segment image.

Removed:
* `packet/packet_ext.dart` (`PacketExt.crc16`). It was not exported and had no callers.

Documented:
* `Angle16` and its variants encode by truncation, unchanged. A negative value within half an ulp of 0 encodes 65536, which the device wraps to 0; a test pins it.

Development:
* Lints: `lints/recommended`, the workspace's shared rules (primary constructors; formatter page width 200, trailing commas preserved), and `avoid_print`. `example/` opts out of `avoid_print`.

## 0.1.3

* fixes.

## 0.1.0

* Initial public release.
* **Bits**: Bitwise operations on integers via `Bits` extension type, with `Bitmask` for field extraction and modification.
* **Word**: Register-width variable with byte/string constructors and endian-aware serialization.
* **BitStruct / BitField**: Named bit-field access within a single integer, supporting both mutable and immutable variants.
* **ByteStruct / ByteField**: Keyed access to typed fields within `TypedData` buffers using `dart:ffi` native type markers.
* **WordStruct / WordField**: Byte-aligned fields within a 64-bit word, with immutable copy helpers.
* **EnumMap / IndexMap**: Type-safe, fixed-key maps with parallel array backing and built-in JSON serialization.
* **Serializable mixin**: Declarative field schema via enum keys providing `toMap()`, `toJson()`, value equality, and immutable copies.
* **BinaryFormat / BinaryCodec**: Encode/decode between typed views and raw binary integers, including fixed-point, boolean, sign, and enum formats.
* **BitsMap / BoolMap**: Flag and boolean collections backed by a single integer.
* **Packet framework**: Abstract packet structure with header parsing, CRC/checksum validation, payload build/parse, and `PacketTransformer` for stream-based framing.
* **Version model**: 4-field version number backed by `WordStruct` with string/JSON serialization.
* **Utility extensions**: `NumLimits`, `Sliceable`, `TypeKey`, null-safe helpers, and typed data slicing.
* **TypedDataBuffer**: Fixed-size `BytesBuilder` with persistent buffer for packet assembly.
