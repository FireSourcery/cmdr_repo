import 'dart:async';
import 'dart:io';
import 'dart:convert';
export 'dart:convert';

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
  // caller fuses to string codec
  Codec<T, String> get stringCodec;

  /// Abstract functions to handle file contents
  Object? fromContents(T contents); //parseContents
  T toContents(); //buildContents

  Future<File> _write(File file, T input) async => file.writeAsString(stringCodec.encode(input));
  Future<T> _read(File file) async => file.readAsString().then(stringCodec.decode);

  // returns null for no file selected
  Future<T?> open(File? file) async => (file != null) ? _read(file) : null;
  Future<T?> openAsync(Future<File?> file) async => file.then(open);
  Future<File?> save(File? file, T contents) async => (file != null) ? _write(file, contents) : null;
  Future<File?> saveAsync(Future<File?> file, T contents) async => file.then((value) => save(value, contents));

  // full sequence for future builder
  Object? _fromNullable(T? contents) => (contents != null) ? fromContents(contents) : null;
  Future<Object?> openContents(Future<File?> file) async => openAsync(file).then(_fromNullable);
  Future<File?> saveContents(Future<File?> file) async => saveAsync(file, toContents());
}

typedef FileStringCodec<T> = FileCodec<T, String>;

abstract class FileCodec<S, T> extends Codec<S, T> {
  const FileCodec();

  @override
  T encode(S input);
  @override
  S decode(T encoded);

  @override
  Converter<S, T> get encoder => _SimpleConverter(encode);
  @override
  Converter<T, S> get decoder => _SimpleConverter(decode);
}

class _SimpleConverter<S, T> extends Converter<S, T> {
  const _SimpleConverter(this._convert);
  final T Function(S) _convert;
  @override
  T convert(S input) => _convert(input);
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

 