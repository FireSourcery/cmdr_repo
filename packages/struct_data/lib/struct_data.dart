/// Bitwise operations, binary data manipulation, typed structs, and serialization utilities for Dart.
/// The packet framework is its own barrel, `package:struct_data/packet.dart`.
library;

/// General data types
export 'utilities/basic_types.dart';
export 'utilities/basic_ext.dart';
export 'utilities/num_ext.dart';
export 'utilities/slice.dart';

export 'src/general/serializable.dart';
export 'src/general/binarizable.dart';
export 'src/general/enum_map.dart';
export 'src/general/enum_types.dart';
export 'src/general/enumerated.dart';
export 'src/general/index_map.dart';
export 'src/general/struct.dart';

/// Bit-level structures
export 'src/bits/bit_field.dart';
export 'src/bits/bit_struct.dart';
export 'src/bits/bits.dart';
export 'src/bits/bits_map.dart';

/// Byte-level structures
export 'src/bytes/byte_struct.dart';
export 'src/bytes/typed_array.dart';
export 'src/bytes/typed_data_buffer.dart';
export 'src/bytes/typed_data_ext.dart';
export 'src/bytes/typed_field.dart';

/// Word-level structures
export 'src/word/word.dart';
export 'src/word/word_struct.dart';

/// Binary format / codec
export 'src/binary_format/binary_codec.dart';
export 'src/binary_format/binary_format.dart';
export 'src/binary_format/quantity_format.dart';

/// Derived
export 'src/models/version.dart';
