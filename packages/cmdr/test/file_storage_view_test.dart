import 'dart:io';
import 'dart:typed_data';

import 'package:cmdr/file_storage/file_storage.dart';
import 'package:cmdr/file_storage/file_storage_notifier.dart';
import 'package:cmdr/file_storage/file_storage_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

class TestStorage extends FileStorage<String> with FileStorageNotifier<String> {
  TestStorage() : super(extensions: ['txt'], defaultName: 'report');

  @override
  Codec<String, String> get stringCodec => const _IdentityCodec();

  @override
  String buildContents() => 'Hello, world!';

  @override
  Object? parseContents(String contents) => contents;
}

class _IdentityCodec extends Codec<String, String> {
  const _IdentityCodec();

  @override
  Converter<String, String> get decoder => const _IdentityConverter();

  @override
  Converter<String, String> get encoder => const _IdentityConverter();
}

class _IdentityConverter extends Converter<String, String> {
  const _IdentityConverter();

  @override
  String convert(String input) => input;
}

class TestPicker extends FilePickerPlatform {
  Uri? savedUri;
  PlatformFile? selectedFile;
  String? fileName;
  Uint8List? bytes;
  WindowsOptions? windowsOptions;
  String? dialogTitle;
  FileType? type;
  List<String>? allowedExtensions;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    this.type = type;
    this.allowedExtensions = allowedExtensions;
    this.windowsOptions = windowsOptions;
    return selectedFile;
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    this.fileName = fileName;
    this.bytes = bytes;
    this.windowsOptions = windowsOptions;
    this.dialogTitle = dialogTitle;
    return savedUri;
  }
}

base class TestPlatformFile extends PlatformFile {
  TestPlatformFile(this.uri);

  @override
  final Uri uri;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FilePickerPlatform originalPicker;
  late TestPicker picker;
  late TestStorage storage;

  setUp(() {
    originalPicker = FilePickerPlatform.instance;
    picker = TestPicker();
    FilePickerPlatform.instance = picker;
    storage = TestStorage();
  });

  tearDown(() {
    FilePickerPlatform.instance = originalPicker;
  });

  test('open selects one file with the configured filter', () async {
    final path = File('test-input.txt').absolute.path;
    picker.selectedFile = TestPlatformFile(Uri.file(path));

    expect((await storage.pickFile())?.path, path);
    expect(picker.type, FileType.custom);
    expect(picker.allowedExtensions, ['txt']);
    expect(picker.windowsOptions!.lockParentWindow, isTrue);
  });

  test('cancelling open returns no file', () async {
    expect(await storage.pickFile(), isNull);
  });

  test('save button sends encoded contents to the picker and reports its file', () async {
    final path = File('test-output.txt').absolute.path;
    picker.savedUri = Uri.file(path);

    await SaveFileButton(fileNotifier: storage).beginAsync();

    expect(picker.fileName, 'report.txt');
    expect(utf8.decode(picker.bytes!), 'Hello, world!');
    expect(picker.dialogTitle, 'Save As:');
    expect(picker.windowsOptions!.lockParentWindow, isTrue);
    expect((await storage.pickedFile)?.path, path);
    expect(storage.file?.path, path);
  });

  test('cancelling save returns no file', () async {
    await SaveFileButton(fileNotifier: storage).beginAsync();

    expect(await storage.pickedFile, isNull);
    expect(storage.file, isNull);
  });
}
