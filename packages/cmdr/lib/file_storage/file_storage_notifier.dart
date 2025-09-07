import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'file_storage.dart';

// app side extends FileStorage can mixin instead of creating controller
abstract mixin class FileStorageNotifier<T> implements FileStorage<T> {
  // FileStorage<T> fileStorage;

  /// ValueNotifiers for caller update
  // async values are available once after resolving future. continuous updates use ValueNotifier
  final ValueNotifier<File?> fileNotifier = ValueNotifier(null);
  set file(File? value) => fileNotifier.value = value;
  File? get file => fileNotifier.value;
  String? get filePath => file?.path;

  // // FileStorageStatus status = FileStorageStatus.ok;
  // final ValueNotifier<FileStorageStatus> statusNotifier = ValueNotifier(FileStorageStatus.ok);
  final ValueNotifier<String?> statusNotifier = ValueNotifier(null);
  String get status => statusNotifier.value ?? 'Ok';
  set status(String value) => statusNotifier.value = status;

  // normalized progress to 0-1
  final ValueNotifier<double> progressNotifier = ValueNotifier(0);
  set progress(double value) => progressNotifier.value = value;
  double get progress => progressNotifier.value;

  /// async state notifiers for FutureBuilder, pick open and pick save
  Future<File?> _pickedFile = Future.value(null);
  Future<File?> get pickedFile => _pickedFile;
  Future<String> get pickedFileName => _pickedFile.then((value) => value?.path ?? 'No file selected');
  set pickedFile(Future<File?> value) => (_pickedFile = value).then((value) => file = value); // also updates associated views listening to fileNotifier

  Future<dynamic>? operationCompleted; // return of function pass to processWithNotify
  @protected
  Completer<void> userConfirmation = Completer();
  Future<void> get userConfirmed => userConfirmation.future;
  void initUserConfirmation() => userConfirmation = Completer<void>();
  void confirm() => userConfirmation.complete();

  // process with notify, async status,
  // error thrown will pass to widget
  // statusNotifier and AsyncSnapshot error arrive at same result. although statusNotifier may transition through a number of update
  Future<R?> processWithNotify<R>(Future<R> Function() operation) async {
    // status = FileStorageStatus.ok;
    statusNotifier.value = null;
    try {
      operationCompleted = operation();
      return await operationCompleted;
      // } on FileStorageStatus catch (e) {
      //   status = e;
    } on Exception catch (e) {
      statusNotifier.value = e.toString();
    } catch (e) {
      // status = FileStorageStatus.unknownError;
      statusNotifier.value = 'Unknown Error: $e';
    } finally {}
    return null;
  }

  // full sequence for future builder
  // returns null for no file selected
  // await file resolve file set
  // dispatch fileNotifier update after parsing
  Future<T?> openWithNotify(Future<File?> value) async => processWithNotify<T?>(() async => await openAsync(pickedFile = value)).whenComplete(() async => file = await pickedFile);
  Future<Object?> openParseWithNotify(Future<File?> value) async => processWithNotify<Object?>(() async => await openParseAsync(pickedFile = value)).whenComplete(() async => file = await pickedFile);

  Future<File?> saveWithNotify(Future<File?> value, T contents) async => processWithNotify<File?>(() async => await saveAsync(pickedFile = value, contents));
  Future<File?> saveBuildWithNotify(Future<File?> value) async => processWithNotify<File?>(() async => await saveBuildAsync(pickedFile = value));

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

////////////////////////////////////////////////////////////////////////////////
/// with View State
////////////////////////////////////////////////////////////////////////////////
// class FileStorageWithNotifier<T> extends FileStorage<T> with FileStorageNotifier<T> {
//   // FileStorageWithNotifier(super.fileCodec);
//   FileStorageWithNotifier.on(FileStorage<T> fileStorage)
//       : _fromContents = fileStorage.fromContents,
//         _toContents = fileStorage.toContents,
//         super(extensions: fileStorage.extensions, defaultName: fileStorage.defaultName);
  
//   // FileStorage<T> fileStorage;

//   @override 
//   FileCodec<T, dynamic> get fileCodec => throw UnimplementedError();

//   final Object? Function(T contents)? _fromContents;
//   final T Function()? _toContents;

//   @override
//   Object? fromContents(T contents) => _fromContents?.call(contents);
//   @override
//   T toContents() => _toContents?.call() ?? (throw UnimplementedError());
  
// }
