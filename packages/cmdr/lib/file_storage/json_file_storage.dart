import 'dart:convert';

import 'file_storage.dart';

typedef JsonMap = Map<String, Object?>;

class JsonFileCodec extends FileStringCodec<JsonMap> {
  const JsonFileCodec();
  static const JsonEncoder _encoder = JsonEncoder.withIndent(' ');
  static const JsonDecoder _decoder = JsonDecoder();

  @override
  JsonMap decode(String encoded) => _decoder.convert(encoded);
  @override
  String encode(JsonMap input) => _encoder.convert(input);
}

abstract class JsonFileStorage extends FileStorage<JsonMap> {
  const JsonFileStorage({super.defaultName, super.extensions = const ['json', 'txt']}) : super();

  factory JsonFileStorage.handlers(Object? Function(JsonMap value) fromJson, JsonMap Function() toJson, {String? defaultName}) = _JsonFileStorageWithHandlers;

  @override
  JsonFileCodec get stringCodec => const JsonFileCodec();

  @override
  Object? fromContents(JsonMap contents);
  @override
  JsonMap toContents();
}

class _JsonFileStorageWithHandlers extends JsonFileStorage {
  const _JsonFileStorageWithHandlers(this._fromJson, this._toJson, {super.defaultName});

  final void Function(JsonMap json) _fromJson;
  final JsonMap Function() _toJson;

  @override
  void fromContents(JsonMap json) => _fromJson(json);
  @override
  JsonMap toContents() => _toJson();
}
