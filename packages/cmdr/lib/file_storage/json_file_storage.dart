import 'file_storage.dart';

typedef JsonMap = Map<String, Object?>;

class const JsonFileCodec() extends FileStringCodec<JsonMap> {
  static const JsonEncoder _encoder = JsonEncoder.withIndent(' ');
  static const JsonDecoder _decoder = JsonDecoder();

  @override
  JsonMap decode(String encoded) => _decoder.convert(encoded);
  @override
  String encode(JsonMap input) => _encoder.convert(input);
}

abstract class const JsonFileStorage({super.defaultName, super.extensions = const ['json', 'txt']}) extends FileStorage<JsonMap> {
  this : super();

  factory JsonFileStorage.handlers(Object? Function(JsonMap value) fromJson, JsonMap Function() toJson, {String? defaultName}) = _JsonFileStorageWithHandlers;

  @override
  JsonFileCodec get stringCodec => const JsonFileCodec();

  @override
  Object? parseContents(JsonMap contents);
  @override
  JsonMap buildContents();
}

class const _JsonFileStorageWithHandlers(final void Function(JsonMap json) _fromJson, final JsonMap Function() _toJson, {super.defaultName}) extends JsonFileStorage {
  @override
  void parseContents(JsonMap json) => _fromJson(json);
  @override
  JsonMap buildContents() => _toJson();
}
