import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'file_storage.dart';

////////////////////////////////////////////////////////////////////////////////
/// with View State
////////////////////////////////////////////////////////////////////////////////
class FileStorageWithNotifier<T> extends FileStorage<T> with FileStorageNotifier<T> implements FileStorageNotifier<T> {
  // FileStorageWithNotifier(super.fileCodec);
  FileStorageWithNotifier.on(FileStorage<T> fileStorage)
      : _fromContents = fileStorage.fromContents,
        _toContents = fileStorage.toContents,
        super(fileStorage.fileCodec, extensions: fileStorage.extensions, defaultName: fileStorage.defaultName);
  // FileStorage<T> fileStorage;

  final Object? Function(T contents)? _fromContents;
  final T Function()? _toContents;

  @override
  Object? fromContents(T contents) => _fromContents?.call(contents);
  @override
  T toContents() => _toContents?.call() ?? (throw UnimplementedError());
}

extension FileStorageWithNotifierExtension on FileStorage {
  FileStorageWithNotifier withNotifier() => FileStorageWithNotifier.on(this);
}

// app side extends FileStorage can mixin instead of creating controller
// Notify with futures
abstract mixin class FileStorageNotifier<T> implements FileStorage<T> {
  // hold notifier values for caller update
  // values are available once after resolving future. continued updates must use ValueNotifier
  final ValueNotifier<File?> fileNotifier = ValueNotifier(null);
  set file(File? value) => fileNotifier.value = value;
  File? get file => fileNotifier.value;
  String? get filePath => file?.path;

  final ValueNotifier<String?> statusNotifier = ValueNotifier(null);
  String get status => statusNotifier.value ?? 'Ok';
  set status(String value) => statusNotifier.value = status;
// // FileStorageStatus status = FileStorageStatus.ok;

  final ValueNotifier<double> progressNotifier = ValueNotifier(0);
  // set progress(double value) => progressNotifier.value = value;
  // double get progress => progressNotifier.value;

  // async state notifiers
  // @protected
  // Completer<File?> pickCompleter = Completer();
  // // Future<File?> get pickCompleted => Future.value();
  // Future<File?> get pickCompleted => pickCompleter.future; // pick open and pick save
  // Future<String?> get pickedFileName => pickCompleter.future.then((value) => value?.path);

  Future<File?>? _pickedFile; // pick open and pick save
  Future<String>? get pickedFileName => _pickedFile?.then((value) => value?.path ?? 'No file selected'); // ?? Future.value('');

  void setFileAsync(Future<File?> value) => (_pickedFile = value).then((value) => file = value);

  set pickedFile(Future<File?>? value) => (_pickedFile = value)?.then((value) => file = value);

  @protected
  Completer<Object?> operationCompleter = Completer(); // Load and operations common, returns value pass by user process function
  Future<Object?> get operationCompleted => operationCompleter.future;
  // Future<Object?>? operationCompleted;

  @protected
  Completer<void> userConfirmation = Completer(); // on confirmation
  Future<void> get userConfirmed => userConfirmation.future;
  void confirm() => userConfirmation.complete();

  // void initLoadingState() {
  //   pickCompleter = Completer<File?>();
  //   if (operationCompleter.isCompleted) operationCompleter = Completer();
  // }

  void initConfirmationState() {
    userConfirmation = Completer<void>();
    if (operationCompleter.isCompleted) operationCompleter = Completer();
  }

  // process with notify, async status,
  //  error thrown will pass to widget
  Future<R?> processWithNotify<R>(FutureOr<R> Function() operation) async {
    // status = FileStorageStatus.ok;
    // _statusNotifier.value = null;
    if (operationCompleter.isCompleted) operationCompleter = Completer();
    try {
      R result = await operation();
      // operationCompleted = operation();
      operationCompleter.complete(result);
      statusNotifier.value = null; // clear status on success
      return result;
      // return operation()..then(operationCompleter.complete);
      // } on FileStorageStatus catch (e) {
      //   status = e;
      //   operationCompleter.completeError(e);
    } on Exception catch (e) {
      statusNotifier.value = e.toString();
      operationCompleter.completeError(e);
    } catch (e) {
      // status = FileStorageStatus.unknownError; //or load error
      statusNotifier.value = 'Unknown Error: $e';
      operationCompleter.completeError(e);
    } finally {
      // _statusNotifier.value = status.message;
    }
    return null;
  }

  // operationCompleted   include entire operation
  // if operationCompleted is shared with caller operation, a stateless widget will load the last operation

  // full sequence for future builder
  // returns null for no file selected
  Future<T?> openWithNotify(Future<File?> value) async {
    // _pickedFile = value;
    // file = await _pickedFile;
    // return (file != null) ? processWithNotify<T?>(() async => openAsync(file!)) : null;
    // _pickedFile = value;
    // file = await _pickedFile;
    // is async with notify is  processed under try?
    return processWithNotify<T?>(() async => openAsync(pickedFile = value));
  }

  Future<Object?> openParseWithNotify(Future<File?> value) async {
    return processWithNotify<Object?>(() async => openParseAsync(pickedFile = value));
    // return openWithNotify(value).then((value) => processWithNotify<Object?>(() => fromNullableContents(value)));
    // try {
    //   //  fileStorage.fromContents(await openAsync());
    //   return await openAsync(value).then((value) => (value != null) ? fileCodec.fromContents(value) : null);
    // } catch (e) {
    //   statusNotifier.value = e.toString();
    // }
    // return null;
  }

  // Future<void> saveFileAndNotify(Future<File?> value, Map<K, V> contents) async {
  //   initLoadingState();
  //   file = await pickSaveFile();
  //   pickCompleter.complete(file);
  //   await tryProcess(() async => await writeAsMap(contents));

  //   // await tryProcess(() async {
  //   //   if (file != null) await write(file!, contents);
  //   // });
  // }

  // Future<void> buildSaveNotify(Future<File?> value, ) async {
  //   // status = FileStorageStatus.ok;
  //   _statusNotifier.value = null;
  //   try {
  //     await saveFileAndNotify(toContents());
  //   } catch (e) {
  //     _statusNotifier.value = e.toString();
  //   }
  // }

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
