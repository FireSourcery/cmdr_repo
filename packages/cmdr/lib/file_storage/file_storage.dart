import 'dart:async';
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
  FileCodec<T, dynamic> get fileCodec; // getter over mixin for codecs with state to maintain encapsulation

  /// Abstract functions to handle file contents
  /// called by openAsync, saveAsync
  Object? fromContents(T contents); //parseContents
  T toContents(); //buildContents

  Object? _fromNullableContents(T? contents) => (contents != null) ? fromContents(contents) : null;

  Future<T> readContents(File file) async => fileCodec.read(file);
  Future<File> writeContents(File file, T contents) async => fileCodec.write(file, contents);

  // full sequence for future builder
  // returns null for no file selected
  Future<T?> open(File? file) async => (file != null) ? readContents(file) : null;
  Future<T?> openAsync(Future<File?> file) async => file.then(open);
  // openThenParse
  Future<Object?> openParseAsync(Future<File?> file) async => openAsync(file).then(_fromNullableContents);

  Future<File?> save(File? file, T contents) async => (file != null) ? writeContents(file, contents) : null;
  Future<File?> saveAsync(Future<File?> file, T contents) async => file.then((value) => save(value, contents));
  // saveAfterBuild
  Future<File?> saveBuildAsync(Future<File?> file) async => saveAsync(file, toContents());
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

  @override
  String encode(T input);
  @override
  T decode(String encoded);

  @override
  Future<File> write(File file, T input) async => file.writeAsString(encode(input));
  @override
  Future<T> read(File file) async => file.readAsString().then((value) => decode(value));
}

/// S e.g. Map from T
abstract mixin class FileContentCodec<S, T> implements FileCodec<S, T> {
  const FileContentCodec();

  FileCodec<T, dynamic> get innerCodec;
  @override
  T encode(S decoded); // buildContents, encodeOuter
  @override
  S decode(T contents); // parseContents, decodeInner

  @override
  Future<File> write(File file, S decoded) async => _FusedFileCodec(this, innerCodec).write(file, decoded);
  @override
  Future<S> read(File file) async => _FusedFileCodec(this, innerCodec).read(file);

  // Future<File> write(File file, S decoded) async => innerCodec.write(file, encode(decoded));
  // Future<S> read(File file) async => innerCodec.read(file).then((value) => decode(value));
}

// in encoding order
// e.g. mapCodec as first, stringCodec as second
class _FusedFileCodec<S, M, T> extends FileCodec<S, T> {
  _FusedFileCodec(this._first, this._second);

  final FileCodec<S, M> _first; // <Map, T>
  final FileCodec<M, T> _second; // <T, String>

  @override
  T encode(S input) => _second.encode(_first.encode(input));
  @override
  S decode(T encoded) => _first.decode(_second.decode(encoded));

  @override
  Future<File> write(File file, S input) async => _second.write(file, _first.encode(input));
  @override
  Future<S> read(File file) async => _second.read(file).then((value) => _first.decode(value));

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
