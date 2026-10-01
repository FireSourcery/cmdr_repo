import 'dart:async';
import 'dart:io';
import 'dart:convert';
export 'dart:convert';

/// FileStorage
///   abstract functions to handle file contents, interface with user application
///   a FileCodec for encoding/decoding, and File read/write
///   optionally mixin a notifier for UI updates
///   optionally cache contents or user controller
abstract class const FileStorage<T>({final List<String>? extensions, final String? defaultName}) {
  // per class/type
  // getter over mixin for codecs with state to maintain encapsulation
  // caller fuses to string codec
  Codec<T, String> get stringCodec;

  /// Abstract functions to handle file contents
  Object? parseContents(T contents); //parseContents
  T buildContents(); //buildContents

  Future<File> _write(File file, T input) async => file.writeAsString(stringCodec.encode(input));
  Future<T> _read(File file) async => file.readAsString().then(stringCodec.decode);

  // returns null for no file selected
  Future<T?> open(File? file) async => (file != null) ? _read(file) : null;
  Future<T?> openAsync(Future<File?> file) async => file.then(open);
  Future<File?> save(File? file, T contents) async => (file != null) ? _write(file, contents) : null;
  Future<File?> saveAsync(Future<File?> file, T contents) async => file.then((value) => save(value, contents));

  // full sequence for future builder
  Object? _fromNullable(T? contents) => (contents != null) ? parseContents(contents) : null;
  Future<Object?> openContents(Future<File?> file) async => openAsync(file).then(_fromNullable);
  Future<File?> saveContents(Future<File?> file) async => saveAsync(file, buildContents());
}

typedef FileStringCodec<T> = FileCodec<T, String>;

abstract class const FileCodec<S, T>() extends Codec<S, T> {
  @override
  T encode(S input);
  @override
  S decode(T encoded);

  @override
  Converter<S, T> get encoder => _SimpleConverter(encode);
  @override
  Converter<T, S> get decoder => _SimpleConverter(decode);
}

class const _SimpleConverter<S, T>(final T Function(S) _convert) extends Converter<S, T> {
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
