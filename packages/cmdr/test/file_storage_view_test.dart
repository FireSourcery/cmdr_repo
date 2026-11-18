import 'dart:io';
import 'dart:typed_data';

import 'package:cmdr/file_storage/file_storage.dart';
import 'package:cmdr/file_storage/file_storage_notifier.dart';
import 'package:cmdr/file_storage/file_storage_view.dart';
import 'package:cmdr/widgets/dialog/dialog_anchor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestStorage() extends FileStorage<String> with FileStorageNotifier<String> {
  this : super(extensions: ['txt'], defaultName: 'report');

  @override
  Codec<String, String> get stringCodec => const _IdentityCodec();

  @override
  String buildContents() => 'Hello, world!';

  @override
  Object? parseContents(String contents) => contents;
}

class const _IdentityCodec() extends Codec<String, String> {
  @override
  Converter<String, String> get decoder => const _IdentityConverter();

  @override
  Converter<String, String> get encoder => const _IdentityConverter();
}

class const _IdentityConverter() extends Converter<String, String> {
  @override
  String convert(String input) => input;
}

class TestPicker() extends FilePickerPlatform {
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

base class TestPlatformFile(
  @override
  final Uri uri) extends PlatformFile {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class const _FailingLoadButton({required super.fileNotifier, super.title = 'Load', super.iconData = Icons.file_open}) extends FileLoadButton {
  @override
  Future<void> beginAsync() => fileNotifier.processWithNotify<File?>(() async => throw Exception('read failed'));
}

/// The shape of an app's result builder: the error, else the value, else 'Complete'.
Widget resultContent(BuildContext context, AsyncSnapshot<String> snapshot) {
  return switch (snapshot) {
    AsyncSnapshot(hasError: true) => Text('Error: ${snapshot.error}'),
    AsyncSnapshot(connectionState: ConnectionState.done) => Text(snapshot.data ?? 'Complete'),
    _ => const SizedBox.shrink(),
  };
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

  testWidgets('a failing load shows its error in the dialog, and the error does not escape the dialog', (tester) async {
    // a storage made inside the test's fake-async zone, so its picked-file future resolves under pump
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _FailingLoadButton(fileNotifier: TestStorage())),
      ),
    );
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();

    expect(find.text('Error: Exception: read failed'), findsOneWidget);
  });

  group('FileConfirmationDialogButton', () {
    Future<void> pumpButton(WidgetTester tester, Future<String> Function() operation, {bool enabled = true, DialogButtonStyle? styleId}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileConfirmationDialogButton<String>(
              fileNotifier: storage,
              title: 'Program',
              iconData: Icons.file_download,
              enabled: enabled,
              styleId: styleId,
              onConfirmOperation: operation,
              resultContent: resultContent,
            ),
          ),
        ),
      );
    }

    Future<void> confirm(WidgetTester tester, Future<String> Function() operation) async {
      await pumpButton(tester, operation);
      await tester.tap(find.text('Program'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
    }

    testWidgets('a failing operation shows its error and the stage it stopped at, and no Complete', (tester) async {
      await confirm(tester, () async {
        storage.status = 'Erasing...';
        throw Exception('erase failed');
      });

      expect(find.text('Erasing...'), findsOneWidget);
      expect(find.text('Error: Exception: erase failed'), findsOneWidget);
      expect(find.textContaining('Complete'), findsNothing);
    });

    testWidgets('a succeeding operation shows its result once, in one dialog that Ok closes', (tester) async {
      await confirm(tester, () async {
        storage.status = 'Writing...';
        return 'Success';
      });

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);
      expect(find.textContaining('Complete'), findsNothing);

      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('disabled, it opens no confirmation', (tester) async {
      await pumpButton(tester, () async => 'Success', enabled: false);
      await tester.tap(find.text('Program'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a warning styleId puts the warning icon on its confirmation', (tester) async {
      await pumpButton(tester, () async => 'Success', styleId: DialogButtonStyle.warning);
      await tester.tap(find.text('Program'));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(AlertDialog), matching: find.byIcon(Icons.warning)), findsOneWidget);
    });
  });
}
