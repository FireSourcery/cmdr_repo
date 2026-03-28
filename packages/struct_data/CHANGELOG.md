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
* **Utility extensions**: `NumLimits`, `LinearConversion`, `Sliceable`, `TypeKey`, null-safe helpers, and typed data slicing.
* **TypedDataBuffer**: Fixed-size `BytesBuilder` with persistent buffer for packet assembly.


## 0.1.3

* fixes.