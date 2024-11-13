import 'dart:typed_data';

// import 'package:path/path.dart';
import 'package:intel_hex/intel_hex.dart';

import 'file_storage.dart';

/// general type as interface/dependency
abstract mixin class FirmwareFileStorage implements FileStorage<Map<int, Uint8List>> {
  // extension(file!.path)
  factory FirmwareFileStorage.type(String fileExtension) {
    return switch (fileExtension) {
      '.hex' => HexFileStorage(),
      // '.bin' => Uint8List.fromList(encoded.codeUnits),
      String() => throw UnimplementedError(),
    } as FirmwareFileStorage;
  }

  @override
  Object? fromContents(Map<int, Uint8List> contents) => contentsBuffer = contents;
  // @override
  // Map<int, Uint8List> toContents() => throw UnimplementedError();
  // @override
  // FileCodec<Map<int, Uint8List>, dynamic> get fileCodec => throw UnimplementedError();

  Map<int, Uint8List> contentsBuffer = const {}; // buffer if needed
  // alternatively as static
  int get bytesTotal => contentsBuffer.values.fold<int>(0, (previousValue, element) => previousValue + element.length);

  Iterable<MapEntry<int, Uint8List>> get segments => contentsBuffer.entries;
}

/// hex codec
class HexFileCodec extends FileStringCodec<List<MemorySegment>> {
  const HexFileCodec();

  @override
  List<MemorySegment> decode(String encoded) => IntelHexFile.fromString(encoded).segments;
  @override
  String encode(List<MemorySegment> input) => throw UnimplementedError();
}

class HexFileMapCodec extends FileContentCodec<Map<int, Uint8List>, List<MemorySegment>> {
  const HexFileMapCodec();

  @override
  final FileStringCodec<List<MemorySegment>> innerCodec = const HexFileCodec();
  @override
  Map<int, Uint8List> decode(List<MemorySegment> contents) => {for (final e in contents) e.address: e.slice()};
  @override
  List<MemorySegment> encode(Map<int, Uint8List> decoded) => decoded.entries.map((e) => MemorySegment.fromBytes(address: e.key, data: e.value)).toList();
}

///
class HexFileStorage extends FileStorage<Map<int, Uint8List>> with FirmwareFileStorage {
  HexFileStorage({super.defaultName, super.extensions = const ['hex']});

  @override
  FileCodec<Map<int, Uint8List>, dynamic> get fileCodec => const HexFileMapCodec();

  @override
  Map<int, Uint8List> toContents() => throw UnimplementedError();
}
