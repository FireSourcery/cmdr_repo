import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// FileStorage
///   abstract functions to handle file contents, interface with user application
///   a FileCodec for encoding/decoding, and File read/write
///   optionally mixin a notifier for UI updates
///   optionally cache contents or user controller
abstract class FileStorage<T> {
  const FileStorage({this.extensions, this.defaultName});

  final List<String>? extensions;
  final String? defaultName;

  // per class/type
  // getter over mixin for codecs with state to maintain encapsulation
  FileStorageCodec<T, dynamic> get fileCodec;

  /// Abstract functions to handle file contents
  /// called by openAsync, saveAsync
  Object? fromContents(T contents); //parseContents
  T toContents(); //buildContents

  Future<T> _read(File file) async => fileCodec.read(file);
  Future<File> _write(File file, T contents) async => fileCodec.write(file, contents);

  // returns null for no file selected
  Future<T?> open(File? file) async => (file != null) ? _read(file) : null;
  Future<T?> openAsync(Future<File?> file) async => file.then(open);
  Future<File?> save(File? file, T contents) async => (file != null) ? _write(file, contents) : null;
  Future<File?> saveAsync(Future<File?> file, T contents) async => file.then((value) => save(value, contents));

  // full sequence for future builder
  // openThenParse
  Object? _fromNullableContents(T? contents) => (contents != null) ? fromContents(contents) : null;
  Future<Object?> openParseAsync(Future<File?> file) async => openAsync(file).then(_fromNullableContents);
  // saveAfterBuild
  Future<File?> saveBuildAsync(Future<File?> file) async => saveAsync(file, toContents());
}

// skip Converter encoder/decoder of Codec class for simplicity
// implements Codec<S, T>
abstract mixin class FileCodec<S, T> {
  const FileCodec();

  T encode(S input);
  S decode(T encoded);

  FileCodec<S, R> fuse<R>(FileCodec<T, R> other) {
    return (other is FileStorageCodec<T, R>) ? _FusedFileStorageCodec<S, T, R>(this, other) : _FusedFileContentCodec<S, T, R>(this, other);
  }
}

/// write function with innerCodec only
/// S e.g. Map from T
abstract class FileContentCodec<S, T> with FileCodec<S, T> implements FileCodec<S, T> {
  const FileContentCodec();

  // @override
  // T encode(S decoded); // buildContents,
  // @override
  // S decode(T contents); // parseContents,

  // FileCodec<T, dynamic> get innerCodec;
  // @override
  // Future<File> write(File file, S decoded) async => _FusedFileCodec(this, innerCodec).write(file, decoded);
  // @override
  // Future<S> read(File file) async => _FusedFileCodec(this, innerCodec).read(file);
}

/// include file read/write
abstract mixin class FileStorageCodec<S, T> implements FileCodec<S, T> {
  const FileStorageCodec();

  // compile-time const return as subtype
  const factory FileStorageCodec.fuse(FileCodec<S, dynamic> format, FileStorageCodec<dynamic, T> storage) = _FusedFileStorageCodec<S, dynamic, T>;

  T encode(S input);
  S decode(T encoded);

  // Converter<S, T> get encoder;
  // Converter<T, S> get decoder;

  Future<File> write(File file, S input);
  Future<S> read(File file);
}

/// Base case with write/read as String
/// T to/from String
abstract class FileStringCodec<S> extends FileStorageCodec<S, String> with FileCodec<S, String> {
  const FileStringCodec();

  @override
  String encode(S input);
  @override
  S decode(String encoded);

  @override
  Future<File> write(File file, S input) async => file.writeAsString(encode(input));
  @override
  Future<S> read(File file) async => file.readAsString().then((value) => decode(value));
}

class _FusedFileContentCodec<S, M, T> extends FileContentCodec<S, T> {
  const _FusedFileContentCodec(this._first, this._second);

  final FileCodec<S, M> _first; // outer type <Map, T>
  final FileCodec<M, T> _second; // inner type <T, String>

  @override
  T encode(S input) => _second.encode(_first.encode(input));
  @override
  S decode(T encoded) => _first.decode(_second.decode(encoded));

  // Converter<S, T> get encoder => _first.encoder.fuse<T>(_second.encoder);
  // Converter<T, S> get decoder => _second.decoder.fuse<S>(_first.decoder);
}

// in encoding order
// e.g. mapCodec as first, stringCodec as second
class _FusedFileStorageCodec<S, M, T> extends _FusedFileContentCodec<S, M, T> implements FileStorageCodec<S, T> {
  const _FusedFileStorageCodec(super._first, FileStorageCodec<M, T> super._second) : super();

  @override
  FileStorageCodec<M, T> get _second => super._second as FileStorageCodec<M, T>;

  @override
  Future<File> write(File file, S input) async => _second.write(file, _first.encode(input));
  @override
  Future<S> read(File file) async => _second.read(file).then((value) => _first.decode(value));
}

extension FileCodecExtension on File {
  Future<T> readAs<T>(FileStorageCodec<T, dynamic> codec) async => codec.read(this);
  Future<File> writeAs<T>(FileStorageCodec<T, dynamic> codec, T contents) async => codec.write(this, contents);

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
