import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Combine File with FileCodec
/// FileStorageCodec
///
/// FileStorage contains
///   abstract functions to handle file contents to application data
///   a FileCodec for encoding/decoding, and File read/write
///   optionally mixin a notifier for UI updates
///   optionally cache File handle, or user controller
abstract class FileStorage<T> {
  const FileStorage(this.fileCodec, {this.extensions, this.defaultName});

  final FileCodec<T, dynamic> fileCodec;
  final List<String>? extensions;
  final String? defaultName;

  /// Abstract functions to handle file contents
  /// called by openAsync, saveAsync
  Object? fromContents(T contents); //parseContents
  T toContents(); //buildContents

  Future<T> readContents(File file) async => fileCodec.read(file);
  Future<File> writeContents(File file, T contents) async => fileCodec.write(file, contents);

  // full sequence for future builder
  // returns null for no file selected
  Future<T?> open(File? file) async => (file != null) ? readContents(file) : null;
  Future<T?> openAsync(Future<File?> file) async => file.then(open);

  Object? fromNullableContents(T? contents) => (contents != null) ? fromContents(contents) : null;
  Future<Object?> openParseAsync(Future<File?> value) async => await openAsync(value).then(fromNullableContents);

  // final FileCodec<T> stringCodec;
  // final FileMapCodec<K, V, T> mapCodec;
  // Object? fromContents(Map<K, V> map) => throw UnimplementedError();
  // Map<K, V> toContents() => throw UnimplementedError();
  // Future<Map<K, V>> readToMap(File file) async => mapCodec.read(file);
  // Future<File> writeFromMap(File file, Map<K, V> map) async => mapCodec.write(file, map);

  // FileStorage<T> copyWith({
  //   FileCodec<T, dynamic>? fileCodec,
  //   List<String>? extensions,
  //   String? defaultName,
  // }) {
  //   return FileStorage<T>(
  //     fileCodec ?? this.fileCodec,
  //     extensions ?? this.extensions,
  //     defaultName ?? this.defaultName,
  //   );
  // }
}

// skip Converter encoder/decoder of Codec class for simplicity
abstract mixin class FileCodec<S, T> {
  const FileCodec();

  // Codec<S, T> get formatCodec;
  T encode(S input);
  S decode(T encoded);

  Future<File> write(File file, S input);
  Future<S> read(File file);

  // FileCodec<S, R> fuse<R>(FileCodec<T, R> other) => _FusedFileCodec<S, T, R>(this, other);
}

/// T from String
// implements Codec<T, String>
abstract mixin class FileStringCodec<T> implements FileCodec<T, String> {
  const FileStringCodec();

  String encode(T input);
  T decode(String encoded);

  Future<File> write(File file, T input) async => file.writeAsString(encode(input));
  Future<T> read(File file) async => file.readAsString().then((value) => decode(value));
}

/// S e.g. Map from T
abstract mixin class FileContentCodec<S, T> implements FileCodec<S, T> {
  const FileContentCodec();

  FileCodec<T, dynamic> get innerCodec;
  T encode(S decoded); // buildContents, encodeOuter
  S decode(T contents); // parseContents, decodeInner

  Future<File> write(File file, S decoded) async => _FusedFileCodec(this, innerCodec).write(file, decoded);
  Future<S> read(File file) async => _FusedFileCodec(this, innerCodec).read(file);

  // Future<File> write(File file, S decoded) async => innerCodec.write(file, encode(decoded));
  // Future<S> read(File file) async => innerCodec.read(file).then((value) => decode(value));
}

// mapCodec as first fuse stringCodec as second
// in encoding order
class _FusedFileCodec<S, M, T> extends FileCodec<S, T> {
  final FileCodec<S, M> _first; //<Map, T>
  final FileCodec<M, T> _second; // <T, String>

  @override
  T encode(S input) => _second.encode(_first.encode(input));
  @override
  S decode(T encoded) => _first.decode(_second.decode(encoded));

  Future<File> write(File file, S input) async => _second.write(file, _first.encode(input));
  Future<S> read(File file) async => _second.read(file).then((value) => _first.decode(value));

  // Converter<S, T> get encoder => _first.encoder.fuse<T>(_second.encoder);
  // Converter<T, S> get decoder => _second.decoder.fuse<S>(_first.decoder);

  _FusedFileCodec(this._first, this._second);
}

extension FileCodecExtension on File {
  Future<T> readAs<T>(FileCodec<T, dynamic> codec) async => codec.read(this);
  Future<File> writeAs<T>(FileCodec<T, dynamic> codec, T contents) async => codec.write(this, contents);

  // Future<Map<K, V>> readAsMap<K, V>(FileMapCodec codec) async => codec.read(this) as Map<K, V>;
  // Future<File> writeAsMap<K, V>(FileMapCodec codec, Map<K, V> map) async => codec.write(this, map);
}

// enum FileStorageStatus implements Exception {
//   ok,
//   processing,
//   invalidFile,
//   fileReadError,
//   fileWriteError,
//   unknownError,
//   ;

//   const FileStorageStatus();
//   String get message => name.sentenceCase;
//   @override
//   toString() => message;
// }

// static Type typeOf<T>() {
//   if (<T>[] is List<List>) return List;
//   if (<T>[] is List<Map>) return Map;
//   return T;
// }

// static T emptyCollection<T>() => switch (typeOf<T>()) { const (List) => [], const (Map) => {}, _ => throw Exception('Invalid Type') } as T;

// abstract mixin class FileCodec<T, K, V> {
//   String encode(T input);
//   T decode(String encoded);

//   T encodeFromMap(Map<K, V> map); // buildContents, encodeOuter
//   Map<K, V> decodeToMap(T contents); // parseContents, decodeInner

//   Future<T> read(File file) async => decode(await file.readAsString());
//   Future<File> write(File file, T contents) async => file.writeAsString(encode(contents));

//   Future<Map<K, V>> readToMap(File file) async => decodeToMap(await read(file));
//   Future<File> writeFromMap(File file, Map<K, V> map) async => write(file, encodeFromMap(map));
// }

/// Map from T
// implements Codec<Map, T>
// abstract mixin class FileMapCodec<K, V, T> implements FileCodec<Map<K, V>, T> {
//   const FileMapCodec();

//   FileStringCodec<T> get stringCodec;
//   T encode(Map<K, V> map); // buildContents, encodeOuter
//   Map<K, V> decode(T contents); // parseContents, decodeInner

//   // Future<File> write(File file, Map<K, V> map) async => stringCodec.write(file, encode(map));
//   // Future<Map<K, V>> read(File file) async => decode(await stringCodec.read(file));

//   Future<File> write(File file, Map<K, V> map) async => _FusedFileCodec(this, stringCodec).write(file, map);
//   Future<Map<K, V>> read(File file) async => _FusedFileCodec(this, stringCodec).read(file);
// }
