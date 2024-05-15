import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// FileStorage contains
///   abstract functions to handle file contents, interface with user application
///   a FileCodec for encoding/decoding, and File read/write
///   optionally mixin a notifier for UI updates
///   optionally cache contents or user controller
abstract class FileStorage<T> {
  const FileStorage(this.fileCodec, {this.extensions, this.defaultName});

  final FileCodec<T, dynamic> fileCodec; //possible make this a getter instead
  final List<String>? extensions;
  final String? defaultName;

  /// Abstract functions to handle file contents
  /// called by openAsync, saveAsync
  Object? fromContents(T contents); //parseContents
  T toContents(); //buildContents

  Future<T> readContents(File file) async => fileCodec.read(file);
  Future<File> writeContents(File file, T contents) async => fileCodec.write(file, contents);

  Object? fromNullableContents(T? contents) => (contents != null) ? fromContents(contents) : null;

  // full sequence for future builder
  // returns null for no file selected
  Future<T?> open(File? file) async => (file != null) ? readContents(file) : null;
  Future<T?> openAsync(Future<File?> file) async => file.then(open);
  Future<Object?> openParseAsync(Future<File?> file) async => openAsync(file).then(fromNullableContents);

  Future<File?> save(File? file, T contents) async => (file != null) ? writeContents(file, contents) : null;
  Future<File?> saveAsync(Future<File?> file, T contents) async => file.then((value) => save(value, contents));
  Future<File?> saveBuildAsync(Future<File?> file) async => saveAsync(file, toContents());

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

  _FusedFileCodec(this._first, this._second);
  // Converter<S, T> get encoder => _first.encoder.fuse<T>(_second.encoder);
  // Converter<T, S> get decoder => _second.decoder.fuse<S>(_first.decoder);
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

