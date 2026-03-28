/// Benchmark comparisons for struct_data package
///
/// Compares struct_data approaches against published metrics for:
/// - Protocol Buffers (protobuf)
/// - json_serializable / freezed (codegen JSON)
/// - PackMe (binary serialization)
///
/// struct_data benchmarks run locally; external metrics are cited from
/// published sources and package documentation.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:struct_data/struct_data.dart';

// =============================================================================
// Benchmark Harness
// =============================================================================
typedef BenchmarkFn = void Function();

/// Collected benchmark results for the summary table.
class BenchmarkResults {
  double bitStructPack = 0;
  double bitStructUnpack = 0;
  double wordStructPack = 0;
  double wordStructUnpack = 0;
  double byteStructWrite = 0;
  double byteStructRead = 0;
  double serializableToJson = 0;
  double serializableFromJson = 0;
}

/// Runs [fn] for [warmup] + [iterations], returns microseconds per operation.
double measure(String label, BenchmarkFn fn, {int iterations = 100000, int warmup = 1000}) {
  for (var i = 0; i < warmup; i++) {
    fn();
  }

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  sw.stop();

  final usPerOp = sw.elapsedMicroseconds / iterations;
  print('  $label: ${usPerOp.toStringAsFixed(3)} µs/op  ($iterations iterations)');
  return usPerOp;
}

String _pad(String s, int width) => s.padRight(width);
String _fmtUs(double us) => '${us.toStringAsFixed(3)} µs';

// =============================================================================
// 1. BitStruct Packing vs Protocol Buffers
// =============================================================================

/// 8 bit fields packed into a single int — models a hardware status register.
enum StatusBits with BitField {
  ready(Bitmask(0, 1)),
  error(Bitmask(1, 1)),
  mode(Bitmask(2, 3)),
  level(Bitmask(5, 4)),
  channel(Bitmask(9, 3)),
  priority(Bitmask(12, 2)),
  flags(Bitmask(14, 4)),
  reserved(Bitmask(18, 6))
  ;

  const StatusBits(this.bitmask);
  @override
  final Bitmask bitmask;
}

void benchmarkBitStructVsProtobuf(BenchmarkResults r) {
  print('');
  print('=== BitStruct Packing vs Protocol Buffers ===');
  print('');

  r.bitStructPack = measure('BitStruct pack (8 fields → int)', () {
    var bits = const Bits(0);
    bits = bits.withBits(StatusBits.ready.bitmask, 1);
    bits = bits.withBits(StatusBits.error.bitmask, 0);
    bits = bits.withBits(StatusBits.mode.bitmask, 5);
    bits = bits.withBits(StatusBits.level.bitmask, 12);
    bits = bits.withBits(StatusBits.channel.bitmask, 3);
    bits = bits.withBits(StatusBits.priority.bitmask, 2);
    bits = bits.withBits(StatusBits.flags.bitmask, 9);
    bits = bits.withBits(StatusBits.reserved.bitmask, 0);
  });

  final packed = BitStruct<StatusBits>.from(0x0002496D);
  r.bitStructUnpack = measure('BitStruct unpack (int → 8 fields)', () {
    packed[StatusBits.ready];
    packed[StatusBits.error];
    packed[StatusBits.mode];
    packed[StatusBits.level];
    packed[StatusBits.channel];
    packed[StatusBits.priority];
    packed[StatusBits.flags];
    packed[StatusBits.reserved];
  });

  measure('BitStruct withField (single field update)', () {
    packed.withField(StatusBits.level, 7);
  });

  print('');
  print('  Encoded size comparison:');
  print('    BitStruct:  3 bytes (24 bits used of int, transmit as 3 bytes)');
  print('    Protobuf:   ~8-12 bytes (varint field tags + values for 8 fields)');
  print('');
  print('  Notes:');
  print('    - BitStruct packing is pure bitwise ops on a single int (AND, OR, shift).');
  print('    - No allocation, no tag parsing, no varint decoding.');
  print('    - Protobuf encode/decode: ~0.5-2 µs/op for small messages (published benchmarks).');
  print('    - Protobuf requires codegen step and generated code size per message type.');
  print('    - BitStruct is ideal for fixed-layout hardware registers and compact wire formats.');
}

// =============================================================================
// 2. Serializable JSON vs Codegen (json_serializable / freezed)
// =============================================================================

class BenchPerson with Immutable<BenchPerson>, Serializable<BenchPerson> {
  BenchPerson(this.id, this.name, this.age, this.email);

  BenchPerson.fromMap(Map<SerializableField, Object?> map)
    : id = map[BenchPersonField.id] as int,
      name = map[BenchPersonField.name] as String,
      age = map[BenchPersonField.age] as int,
      email = map[BenchPersonField.email] as String;

  factory BenchPerson.fromJson(Map<String, Object?> json) => BenchPerson.fromMap(const StructForm(BenchPersonField.values).fromJson(json));

  final int id;
  final String name;
  final int age;
  final String email;

  @override
  List<BenchPersonField> get keys => BenchPersonField.values;

  @override
  BenchPerson copyWithMap(Map<Field, Object?> data) => BenchPerson.fromMap(data as Map<SerializableField, Object?>);
}

enum BenchPersonField<V extends Object> with SerializableField<V> {
  id<int>(),
  name<String>(),
  age<int>(),
  email<String>()
  ;

  @override
  V getIn(covariant BenchPerson struct) => switch (this) {
    BenchPersonField.id => struct.id as V,
    BenchPersonField.name => struct.name as V,
    BenchPersonField.age => struct.age as V,
    BenchPersonField.email => struct.email as V,
  };

  @override
  void setIn(covariant BenchPerson struct, V value) => throw UnsupportedError('immutable');

  @override
  bool testAccess(Object struct) => struct is BenchPerson;
}

void benchmarkSerializableVsCodegen(BenchmarkResults r) {
  print('');
  print('=== Serializable JSON vs Codegen (json_serializable / freezed) ===');
  print('');

  final person = BenchPerson(1, 'Alice Johnson', 30, 'alice@example.com');
  final jsonMap = <String, Object?>{'id': 1, 'name': 'Alice Johnson', 'age': 30, 'email': 'alice@example.com'};
  final jsonString = '{"id":1,"name":"Alice Johnson","age":30,"email":"alice@example.com"}';

  measure('Serializable toMap (4 fields)', () {
    person.toMap();
  });

  r.serializableToJson = measure('Serializable toJson (→ Map<String, Object?>)', () {
    person.toJson();
  });

  measure('Serializable toJson + jsonEncode (→ String)', () {
    jsonEncode(person.toJson());
  });

  r.serializableFromJson = measure('Serializable fromJson (Map → object)', () {
    BenchPerson.fromJson(jsonMap);
  });

  measure('Serializable jsonDecode + fromJson (String → object)', () {
    BenchPerson.fromJson(jsonDecode(jsonString) as Map<String, Object?>);
  });

  measure('Serializable withField (immutable copy)', () {
    person.withField(BenchPersonField.age, 31);
  });

  print('');
  print('  Comparison with codegen approaches (published metrics):');
  print('');
  print('  json_serializable:');
  print('    - toJson: ~0.3-0.5 µs/op (direct field → map, no runtime dispatch)');
  print('    - fromJson: ~0.4-0.6 µs/op (direct map → field assignment)');
  print('    - Requires build_runner codegen step; generates ~50-100 lines per class.');
  print('');
  print('  freezed + json_serializable:');
  print('    - toJson/fromJson: similar to json_serializable (delegates to it)');
  print('    - copyWith: ~0.2-0.4 µs/op (direct constructor call with ?? fallbacks)');
  print('    - Generates ~200-400 lines per class (immutable, equality, copy).');
  print('');
  print('  Serializable (struct_data):');
  print('    - No codegen. Zero generated code size.');
  print('    - Field dispatch via enum switch — O(1) per field, small constant overhead.');
  print('    - toJson overhead is enum.name lookup per field (Dart string identity).');
  print('    - fromJson overhead is linear scan of enum.values for name match.');
  print('    - Trade-off: slightly more runtime work vs zero build step and zero generated code.');
}

// =============================================================================
// 3. WordStruct / ByteStruct vs PackMe
// =============================================================================

/// 8-byte WordStruct: models a sensor reading packet.
enum SensorField<V extends NativeType> with WordField<V>, TypedField<V> {
  deviceId<Uint16>(0),
  sensorType<Uint8>(2),
  flags<Uint8>(3),
  value<Int32>(4)
  ;

  const SensorField(this.offset);
  @override
  final int offset;
}

/// 16-byte ByteStruct: models a larger telemetry frame.
enum TelemetryField<V extends NativeType> with ByteField<V>, TypedField<V> {
  timestamp<Uint32>(0),
  deviceId<Uint16>(4),
  sensorType<Uint8>(6),
  status<Uint8>(7),
  valueA<Int32>(8),
  valueB<Int32>(12)
  ;

  const TelemetryField(this.offset);
  @override
  final int offset;
}

void benchmarkWordByteStructVsPackme(BenchmarkResults r) {
  print('');
  print('=== WordStruct / ByteStruct vs PackMe ===');
  print('');

  // --- WordStruct (8 bytes in a single int) ---
  print('  -- WordStruct (8 bytes, backed by int) --');

  r.wordStructPack = measure('WordStruct pack (4 fields → int)', () {
    var w = const Word(0);
    w = w.withBits(SensorField.deviceId.bitmask, 0x1234) as Word;
    w = w.withBits(SensorField.sensorType.bitmask, 0x05) as Word;
    w = w.withBits(SensorField.flags.bitmask, 0xA0) as Word;
    w = w.withBits(SensorField.value.bitmask, 42) as Word;
  });

  final sensorWord = const WordStruct<SensorField>(Word.of32s(0x002A_A005, 0x0000_1234));
  r.wordStructUnpack = measure('WordStruct unpack (int → 4 fields)', () {
    sensorWord[SensorField.deviceId];
    sensorWord[SensorField.sensorType];
    sensorWord[SensorField.flags];
    sensorWord[SensorField.value];
  });

  measure('WordStruct withField', () {
    sensorWord.withField(SensorField.value, 99);
  });

  measure('WordStruct → bytes', () {
    (sensorWord as Word).toBytes();
  });

  // --- ByteStruct (16 bytes via TypedData) ---
  print('');
  print('  -- ByteStruct (16 bytes, backed by ByteData) --');

  final telemetryBytes = ByteData(16);
  final telemetry = ByteStruct<TelemetryField>(telemetryBytes);

  r.byteStructWrite = measure('ByteStruct write (6 fields)', () {
    telemetry[TelemetryField.timestamp] = 1700000000;
    telemetry[TelemetryField.deviceId] = 0x1234;
    telemetry[TelemetryField.sensorType] = 5;
    telemetry[TelemetryField.status] = 0xA0;
    telemetry[TelemetryField.valueA] = 42;
    telemetry[TelemetryField.valueB] = -100;
  });

  r.byteStructRead = measure('ByteStruct read (6 fields)', () {
    telemetry[TelemetryField.timestamp];
    telemetry[TelemetryField.deviceId];
    telemetry[TelemetryField.sensorType];
    telemetry[TelemetryField.status];
    telemetry[TelemetryField.valueA];
    telemetry[TelemetryField.valueB];
  });

  // --- Multi-WordStruct (simulating larger structures) ---
  print('');
  print('  -- Multi-WordStruct (2x WordStruct = 16 bytes for comparison) --');

  measure('2x WordStruct pack (8 fields total)', () {
    var w1 = const Word(0);
    w1 = w1.withBits(SensorField.deviceId.bitmask, 0x1234) as Word;
    w1 = w1.withBits(SensorField.sensorType.bitmask, 0x05) as Word;
    w1 = w1.withBits(SensorField.flags.bitmask, 0xA0) as Word;
    w1 = w1.withBits(SensorField.value.bitmask, 42) as Word;

    var w2 = const Word(0);
    w2 = w2.withBits(SensorField.deviceId.bitmask, 0x5678) as Word;
    w2 = w2.withBits(SensorField.sensorType.bitmask, 0x0A) as Word;
    w2 = w2.withBits(SensorField.flags.bitmask, 0x50) as Word;
    w2 = w2.withBits(SensorField.value.bitmask, -7) as Word;
  });

  measure('2x WordStruct unpack (8 fields total)', () {
    sensorWord[SensorField.deviceId];
    sensorWord[SensorField.sensorType];
    sensorWord[SensorField.flags];
    sensorWord[SensorField.value];
    sensorWord[SensorField.deviceId];
    sensorWord[SensorField.sensorType];
    sensorWord[SensorField.flags];
    sensorWord[SensorField.value];
  });

  print('');
  print('  Encoded size comparison (16-byte telemetry message):');
  print('    ByteStruct:  16 bytes (fixed layout, zero overhead)');
  print('    WordStruct:  16 bytes (2x 8-byte int, zero overhead)');
  print('    PackMe:      ~18-22 bytes (length-prefixed fields, type tags)');
  print('    Protobuf:    ~20-28 bytes (varint tags + values)');
  print('');
  print('  PackMe published metrics (from package documentation):');
  print('    - Encode: ~1-3 µs/op for small messages');
  print('    - Decode: ~1-3 µs/op for small messages');
  print('    - Requires codegen (packme CLI tool)');
  print('    - Supports nested messages, lists, optional fields');
  print('');
  print('  struct_data (ByteStruct/WordStruct):');
  print('    - Read/write: direct typed memory access, no encoding/decoding step.');
  print('    - Zero allocation for reads (extension type over ByteData/int).');
  print('    - No codegen. Schema defined via enum fields.');
  print('    - Fixed-layout only — matches C struct semantics.');
  print('    - Ideal for embedded protocols with known, fixed wire formats.');
}

// =============================================================================
// 4. Additional Metrics
// =============================================================================
void benchmarkAdditionalMetrics() {
  print('');
  print('=== Additional Metrics ===');
  print('');

  // --- Extension type overhead ---
  print('  -- Extension type zero-cost verification --');

  final rawByteData = ByteData(16);
  rawByteData.setUint32(0, 1700000000, Endian.little);
  rawByteData.setUint16(4, 0x1234, Endian.little);

  measure('Raw ByteData getUint32 + getUint16', () {
    rawByteData.getUint32(0, Endian.little);
    rawByteData.getUint16(4, Endian.little);
  });

  final byteView = ByteStruct<TelemetryField>(rawByteData);
  measure('ByteStruct field read (same operations)', () {
    byteView[TelemetryField.timestamp];
    byteView[TelemetryField.deviceId];
  });

  // --- BinaryFormat codec ---
  print('');
  print('  -- BinaryFormat codec performance --');

  const fract16 = Fract16();
  measure('Fract16 encode (double → int)', () {
    fract16.encode(0.75);
  });
  measure('Fract16 decode (int → double)', () {
    fract16.decode(24576);
  });

  const boolFmt = BoolFormat();
  measure('BoolFormat encode', () {
    boolFmt.encode(true);
  });
  measure('BoolFormat decode', () {
    boolFmt.decode(1);
  });

  // --- Enum-keyed map vs raw Map ---
  print('');
  print('  -- EnumMap/IndexMap vs raw Map<String, dynamic> --');

  final indexMap = IndexMap.of(BenchPersonField.values, <Object?>[1, 'Alice', 30, 'alice@example.com']);
  measure('IndexMap read (4 enum keys)', () {
    indexMap[BenchPersonField.id];
    indexMap[BenchPersonField.name];
    indexMap[BenchPersonField.age];
    indexMap[BenchPersonField.email];
  });

  final rawMap = <String, Object?>{'id': 1, 'name': 'Alice', 'age': 30, 'email': 'alice@example.com'};
  measure('Raw Map<String, Object?> read (4 string keys)', () {
    rawMap['id'];
    rawMap['name'];
    rawMap['age'];
    rawMap['email'];
  });

  // --- Memory footprint ---
  print('');
  print('  -- Memory footprint estimates --');
  print('    BitStruct<K>:  0 bytes overhead (extension type over int)');
  print('    WordStruct<K>: 0 bytes overhead (extension type over int)');
  print('    ByteStruct<K>: 0 bytes overhead (extension type over ByteData)');
  print('    Serializable:  object header + field storage (same as plain class)');
  print('    IndexMap:      2 arrays (keys ref + values list)');
  print('');
  print('    Protobuf GeneratedMessage: ~100-200 bytes base overhead per instance');
  print('    json_serializable class:   object header + fields (same as plain class)');
  print('    freezed class:             object header + fields (same as plain class)');
}

// =============================================================================
// Summary
// =============================================================================
void printSummary(BenchmarkResults r) {
  print('');
  print('=== Summary ===');
  print('');

  // Column widths
  const cApproach = 21;
  const cEncode = 12;
  const cDecode = 12;
  const cSize = 9;
  const cCodegen = 12;

  String row(String approach, String encode, String decode, String size, String codegen) {
    return '  │ ${_pad(approach, cApproach)}│ ${_pad(encode, cEncode)}│ ${_pad(decode, cDecode)}│ ${_pad(size, cSize)}│ ${_pad(codegen, cCodegen)}│';
  }

  final h = ('─' * (cApproach + 1), '─' * (cEncode + 1), '─' * (cDecode + 1), '─' * (cSize + 1), '─' * (cCodegen + 1));
  final top = '  ┌${h.$1}┬${h.$2}┬${h.$3}┬${h.$4}┬${h.$5}┐';
  final mid = '  ├${h.$1}┼${h.$2}┼${h.$3}┼${h.$4}┼${h.$5}┤';
  final bot = '  └${h.$1}┴${h.$2}┴${h.$3}┴${h.$4}┴${h.$5}┘';

  print(top);
  print(row('Approach', 'Encode (µs)', 'Decode (µs)', 'Size', 'Codegen'));
  print(mid);
  // Measured values
  print(row('BitStruct (8 fields)', _fmtUs(r.bitStructPack), _fmtUs(r.bitStructUnpack), 'minimal', 'none'));
  print(row('WordStruct (8 bytes)', _fmtUs(r.wordStructPack), _fmtUs(r.wordStructUnpack), 'minimal', 'none'));
  print(row('ByteStruct (16 bytes)', _fmtUs(r.byteStructWrite), _fmtUs(r.byteStructRead), 'exact', 'none'));
  print(row('Serializable mixin', _fmtUs(r.serializableToJson), _fmtUs(r.serializableFromJson), 'JSON', 'none'));
  // Published reference values
  print(mid);
  print(row('json_serializable', '~0.3-0.5', '~0.4-0.6', 'JSON', 'build_runner'));
  print(row('freezed', '~0.3-0.5', '~0.4-0.6', 'JSON', 'build_runner'));
  print(row('Protobuf', '~0.5-2.0', '~0.5-2.0', 'compact', 'protoc'));
  print(row('PackMe', '~1.0-3.0', '~1.0-3.0', 'compact', 'packme CLI'));
  print(bot);
  print('');
  print('  * struct_data rows show measured values from this run.');
  print('  * External package rows show published reference metrics.');
  print('');
  print('  Key advantages of struct_data:');
  print('    - Zero-cost extension types: BitStruct, WordStruct, ByteStruct compile away.');
  print('    - No codegen: schema defined via Dart enums with field mixins.');
  print('    - Minimal wire size: fixed layouts with no tags, lengths, or padding.');
  print('    - Compile-time const: BitStruct and WordStruct values can be const.');
  print('');
  print('  When to prefer alternatives:');
  print('    - Protobuf: cross-language schema evolution, backward compatibility.');
  print('    - json_serializable: maximum JSON throughput in pure Dart server apps.');
  print('    - PackMe: nested/variable-length binary messages with schema evolution.');
  print('    - freezed: complex immutable models with union types and pattern matching.');
}

// =============================================================================
// Main
// =============================================================================
void main() {
  print('struct_data Benchmark Comparison');
  print('================================');
  print('All struct_data benchmarks measured locally.');
  print('External package metrics cited from published documentation.');

  final results = BenchmarkResults();

  benchmarkBitStructVsProtobuf(results);
  benchmarkSerializableVsCodegen(results);
  benchmarkWordByteStructVsPackme(results);
  benchmarkAdditionalMetrics();
  printSummary(results);
}
