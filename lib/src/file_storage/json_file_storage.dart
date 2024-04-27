import 'dart:convert';

import 'package:meta/meta.dart';

import 'file_notifier.dart';
import 'file_storage.dart';

// typedef JsonMap = Map<String, Object?>;

abstract class JsonFileStorage extends FileStorageNotifier<Map<String, Object?>, String, Object?> {
  JsonFileStorage({super.saveName}) : super(allowedExtensions: const ['json', 'txt']);

  factory JsonFileStorage.handlers(Object? Function(Map<String, Object?> value) fromJson, Map<String, Object?> Function() toJson, {String? saveName}) = _JsonFileStorageWithHandlers;

  @override
  Object? parseFromMap(Map<String, Object?> map);
  @override
  Map<String, Object?> buildToMap();

  static const JsonEncoder encoder = JsonEncoder.withIndent(' ');
  static const JsonDecoder decoder = JsonDecoder();

  // todo handle top level list as map {file: [list]}
  @override
  Map<String, Object?> decode(String encoded) => decoder.convert(encoded);
  @override
  String encode(Map<String, Object?> input) => encoder.convert(input);
  // json natively in map format, todo accept list
  @override
  Map<String, Object?> encodeFromMap(Map<String, Object?> map) => map;
  @override
  Map<String, Object?> decodeToMap(Map<String, Object?> contents) => contents;
}

class _JsonFileStorageWithHandlers extends JsonFileStorage {
  _JsonFileStorageWithHandlers(this._fromJson, this._toJson, {super.saveName});

  final void Function(Map<String, Object?> json) _fromJson;
  final Map<String, Object?> Function() _toJson;

  @override
  void parseFromMap(Map<String, Object?> json) => _fromJson(json);
  @override
  Map<String, Object?> buildToMap() => _toJson();
}
