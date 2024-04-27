import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:recase/recase.dart';

abstract class FileStorage<T, K, V> with FileCodec<T, K, V> {
  FileStorage({this.allowedExtensions, this.saveName});

  final List<String>? allowedExtensions;
  final String? saveName; // default name

  // implement for openParse, saveBuild
  Object? parseFromMap(Map<K, V> map); // Object? parseMap(Map<K, V> map);
  Map<K, V> buildToMap(); // Map<K, V> buildMap();

  File? file;
  String? get filePath => file?.path;
  Map<K, V> contentsMap = const {}; // buffer if needed
  // FileStorageStatus status = FileStorageStatus.ok;

  // static Type typeOf<T>() {
  //   if (<T>[] is List<List>) return List;
  //   if (<T>[] is List<Map>) return Map;
  //   return T;
  // }

  // static T emptyCollection<T>() => switch (typeOf<T>()) { const (List) => [], const (Map) => {}, _ => throw Exception('Invalid Type') } as T;

  /// File picker using settings
  Future<File?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      lockParentWindow: true,
      allowMultiple: false,
    );
    return (result != null) ? File(result.files.single.path!) : null;
  }

  Future<File?> pickSaveFile() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      String? path = await FilePicker.platform.saveFile(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        lockParentWindow: true,
        dialogTitle: 'Save As:',
        fileName: saveName,
      );
      return (path != null) ? File(path) : null;
    } else {
      return pickFile();
    }
  }

  Future<Map<K, V>> readAsMap() async => (file != null) ? await readToMap(file!) : const {};
  Future<File?> writeAsMap(Map<K, V> map) async => (file != null) ? await writeFromMap(file!, map) : null;

  // remap status shared with exception
  // Future<T?> tryReadFile(File file) async {
  //   try {
  //     return await read(file);
  //   } on FormatException {
  //     // throw const FormatException('Invalid File');
  //     throw FileStorageStatus.invalidFile;
  //   } on Exception {
  //     // throw Exception('File Read Error');
  //     throw FileStorageStatus.fileReadError;
  //   } catch (e) {
  //     throw FileStorageStatus.unknownError;
  //   }
  //   return null;
  // }

  // Future<File> tryWriteFile(File file, T contents) async {
  //   try {
  //     return await write(file, contents);
  //   } on Exception {
  //     // throw Exception('File Write Error');
  //     throw FileStorageStatus.fileWriteError;
  //   } catch (e) {
  //     throw FileStorageStatus.unknownError;
  //   }
  //   return file;
  // }
}

// skip Converter encoder/decoder of Codec class for simplicity
// implements Codec<T, String>
abstract mixin class FileCodec<T, K, V> {
  String encode(T input);
  T decode(String encoded);

  T encodeFromMap(Map<K, V> map); // buildContents, encodeOuter
  Map<K, V> decodeToMap(T contents); // parseContents, decodeInner

  Future<T> read(File file) async => decode(await file.readAsString());
  Future<File> write(File file, T contents) async => file.writeAsString(encode(contents));

  Future<Map<K, V>> readToMap(File file) async => decodeToMap(await read(file));
  Future<File> writeFromMap(File file, Map<K, V> map) async => write(file, encodeFromMap(map));
}

enum FileStorageStatus implements Exception {
  ok,
  processing,
  invalidFile,
  fileReadError,
  fileWriteError,
  unknownError,
  ;

  const FileStorageStatus();
  String get message => name.sentenceCase;
  @override
  toString() => message;
}
