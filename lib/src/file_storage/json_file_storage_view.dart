import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'file_notifier.dart';
import 'file_storage.dart';
import 'file_storage_view.dart';
import 'json_file_storage.dart';

// load and parse
class OpenJsonFileButton extends FileLoadButton {
  const OpenJsonFileButton({required this.jsonFile, super.title = 'Open File', super.iconData = Icons.file_open, super.key}) : super(fileNotifier: jsonFile);

  final JsonFileStorage jsonFile;
  @override
  Future<void> beginAsync() async => jsonFile.openParseNotify();
}

class SaveJsonFileButton extends FileLoadButton {
  const SaveJsonFileButton({required this.jsonFile, super.title = 'Save File', super.iconData = Icons.file_copy, super.key}) : super(fileNotifier: jsonFile);

  final JsonFileStorage jsonFile;
  @override
  Future<void> beginAsync() async => await jsonFile.buildSaveNotify();
}
