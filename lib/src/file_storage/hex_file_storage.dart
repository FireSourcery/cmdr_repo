import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:intel_hex/intel_hex.dart';

import 'file_notifier.dart';
import 'file_storage.dart';

abstract class FirmwareFileStorage<T> extends FileStorageNotifier<T, int, Uint8List> {
  FirmwareFileStorage({super.saveName, super.allowedExtensions = const ['hex']});

  // extension(file!.path)
  factory FirmwareFileStorage.type(String fileType) {
    return switch (fileType) {
      '.hex' => HexFileStorage(),
      // '.bin' => Uint8List.fromList(encoded.codeUnits),
      String() => throw UnimplementedError(),
    } as FirmwareFileStorage<T>;
  }

  int get totalBytes => contentsMap.values.fold<int>(0, (previousValue, element) => element.length + previousValue);

  Iterable<MapEntry<int, Uint8List>> get segments => contentsMap.entries;
}

class HexFileStorage extends FirmwareFileStorage<List<MemorySegment>> {
  HexFileStorage({super.saveName}) : super(allowedExtensions: const ['hex']);

  @override
  List<MemorySegment> decode(String encoded) => (hex = IntelHexFile.fromString(encoded)).segments;
  @override
  String encode(List<MemorySegment> input) => throw UnimplementedError();
  @override
  Map<int, Uint8List> decodeToMap(List<MemorySegment> contents) => {for (final e in contents) e.address: e.slice()};
  @override
  List<MemorySegment> encodeFromMap(Map<int, Uint8List> map) => map.entries.map((e) => MemorySegment.fromBytes(address: e.key, data: e.value)).toList();

  IntelHexFile hex = IntelHexFile();

  @override
  Object? parseFromMap(Map<int, Uint8List> map) => throw UnimplementedError();
  @override
  Map<int, Uint8List> buildToMap() => throw UnimplementedError();
}
