import 'dart:typed_data';

// import 'package:path/path.dart';
import 'package:intel_hex/intel_hex.dart';

import 'file_storage.dart';

class FirmwareFileStorage extends FileStorage<Map<int, Uint8List>> {
  FirmwareFileStorage(super.fileCodec, {super.defaultName, super.extensions = const ['hex']});

  @override
  Object? fromContents(Map<int, Uint8List> contents) => contentsBuffer = contents;
  @override
  Map<int, Uint8List> toContents() => throw UnimplementedError();

  // extension(file!.path)
  factory FirmwareFileStorage.type(String fileType) {
    return switch (fileType) {
      '.hex' => HexFileStorage(),
      // '.bin' => Uint8List.fromList(encoded.codeUnits),
      String() => throw UnimplementedError(),
    } as FirmwareFileStorage;
  }

  Map<int, Uint8List> contentsBuffer = const {}; // buffer if needed
  // alternatively as static
  int get bytesTotal => contentsBuffer.values.fold<int>(0, (previousValue, element) => element.length + previousValue);

  Iterable<MapEntry<int, Uint8List>> get segments => contentsBuffer.entries;
}

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

class HexFileStorage extends FirmwareFileStorage {
  HexFileStorage({super.defaultName}) : super(const HexFileMapCodec());
}
