import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'file_storage.dart';

////////////////////////////////////////////////////////////////////////////////
/// with View State
////////////////////////////////////////////////////////////////////////////////
// change to convert with notifier?
abstract class FileStorageNotifier<T, K, V> = FileStorage<T, K, V> with FileNotifier<T, K, V> implements FileNotifier<T, K, V>;

// Notify with completer futures
abstract mixin class FileNotifier<T, K, V> implements FileStorage<T, K, V> {
  // async state notifiers
  @protected
  Completer<File?> pickCompleter = Completer();
  Future<File?> get pickCompleted => pickCompleter.future; // pick open and pick save
  Future<String?> get pickedFileName => pickCompleter.future.then((value) => value?.path);

  @protected
  Completer<Object?> operationCompleter = Completer(); // Load and operations common, returns value pass by user process function
  Future<Object?> get operationCompleted => operationCompleter.future;

  @protected
  Completer<void> userConfirmation = Completer(); // on confirmation
  Future<void> get userConfirmed => userConfirmation.future;
  void confirm() => userConfirmation.complete();

  // hold notifier values for caller update
  ValueNotifier<String?> statusNotifier = ValueNotifier(null);
  String get status => statusNotifier.value ?? 'Ok';

  ValueNotifier<double> progressNotifier = ValueNotifier(0);

  // set progress(double value) => progressNotifier.value = value;
  // double get progress => progressNotifier.value;

  ValueNotifier<File?> fileNotifier = ValueNotifier(null);
  @override
  set file(File? value) => fileNotifier.value = value;
  @override
  get file => fileNotifier.value;

  void initLoadingState() {
    pickCompleter = Completer<File?>();
    if (operationCompleter.isCompleted) operationCompleter = Completer();
  }

  void initConfirmationState() {
    userConfirmation = Completer<void>();
    if (operationCompleter.isCompleted) operationCompleter = Completer();
  }

  //set as try load?
  // process with async status, error thrown will pass to widget
  Future<R?> tryProcess<R>(Future<R> Function() operation) async {
    // status = FileStorageStatus.ok;
    // statusNotifier.value = null;
    try {
      R result = await operation();
      operationCompleter.complete(result);
      statusNotifier.value = null;
      return result;
      // if completer is use as load, further status update use statusNotifier
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
      // statusNotifier.value = status.message;
    }
    return null;
  }

  // full sequence with completers, for future builder
  // returns null for no file selected
  Future<Map<K, V>?> openFileAndNotify() async {
    initLoadingState();
    file = await pickFile();
    pickCompleter.complete(file);
    contentsMap = await tryProcess(readAsMap) ?? const {}; // wrap to ensure the operationCompleter completes if there is no file
    return (file == null) ? null : contentsMap;

    // await tryProcess(() async {
    //   // wrap to ensure the operationCompleter completes if there is no file
    //   contents = (file != null) ? await read(file!) : null;
    // });
    // return contents;
  }

  Future<void> saveFileAndNotify(Map<K, V> contents) async {
    initLoadingState();
    file = await pickSaveFile();
    pickCompleter.complete(file);
    await tryProcess(() async => await writeAsMap(contents));

    // await tryProcess(() async {
    //   if (file != null) await write(file!, contents);
    // });
  }

  Future<void> openParseNotify() async {
    // status = FileStorageStatus.ok;
    statusNotifier.value = null;
    try {
      //  fromMap(await openFileAndNotify());
      await openFileAndNotify().then((value) => (value != null) ? parseFromMap(value) : null);
    } catch (e) {
      statusNotifier.value = e.toString();
    }
  }

  Future<void> buildSaveNotify() async {
    // status = FileStorageStatus.ok;
    statusNotifier.value = null;
    try {
      await saveFileAndNotify(buildToMap());
    } catch (e) {
      statusNotifier.value = e.toString();
    }
  }
}
