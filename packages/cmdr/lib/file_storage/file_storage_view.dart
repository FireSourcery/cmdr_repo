import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../widgets/dialog/dialog.dart';
import '../widgets/dialog/dialog_anchor.dart';
import 'file_storage_notifier.dart';
import 'file_storage.dart';

class const OpenFileButton({required super.fileNotifier, super.title = 'Open File', super.iconData = Icons.file_open, super.key}) extends FileLoadButton {
  @override
  Future<void> beginAsync() async => fileNotifier.openParseWithNotify(fileNotifier.pickFile());
}

class const SaveFileButton({required super.fileNotifier, super.title = 'Save File', super.iconData = Icons.file_copy, super.key}) extends FileLoadButton {
  @override
  Future<void> beginAsync() async => fileNotifier.processWithNotify<File?>(() async => await (fileNotifier.pickedFile = fileNotifier.pickAndSaveFile()));
}

// async notifier, refresh on show dialog
abstract class const FileLoadButton({
  required final FileStorageNotifier fileNotifier,
  required final String title, // e.g. open close
  required final IconData iconData, // e.g. Icons.file_open
  super.key,
}) extends StatelessWidget {
  Future<void> beginAsync(); // load initial async state referenced by dialog, sets fileNotifier.operationCompleted

  // Future object reference is set once initially. changes do not update without ChangeNotifier.
  // ConnectionState will not be ConnectionState.none in the case of StatelessWidget
  @override
  Widget build(BuildContext context) {
    Future<String?> showDialogBegin() {
      beginAsync().ignore(); // its error is shown by the dialog, through operationCompleted

      return showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            // insetPadding: EdgeInsets.all(10),
            title: Text(title),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // file name
                FutureBuilder(
                  future: fileNotifier.pickedFileName,
                  builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                    return switch (snapshot) {
                      AsyncSnapshot(connectionState: ConnectionState.done) => Text(snapshot.data ?? snapshot.error.toString()),
                      _ => const LinearProgressIndicator(),
                    };
                  },
                ),
                // file loading, then operation status
                FileOperationText(fileNotifier),
              ],
            ),
            actions: <Widget>[
              FutureBuilder(
                future: fileNotifier.operationCompleted,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  return switch (snapshot) {
                    AsyncSnapshot(connectionState: ConnectionState.done) => TextButton(onPressed: () => Navigator.of(context).pop(fileNotifier.status), child: const Text('Ok')),
                    _ => const CircularProgressIndicator(),
                  };
                },
              ),
            ],
          );
        },
      );
    }

    return ElevatedButton.icon(
      onPressed: showDialogBegin,
      icon: Icon(iconData),
      label: Text(title),
    );
  }
}

class const FileConfirmationDialogButton<R>({
  required final FileStorageNotifier fileNotifier,
  required final String title,
  required final IconData iconData,
  required final Future<R> Function() onConfirmOperation,
  required final AsyncWidgetBuilder<R> resultContent, // the completed operation, error or ok
  final String confirmationText = 'Confirm?',
  final DialogButtonStyle? styleId, // of the confirmation
  final bool enabled = true,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget content(List<Widget> status) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// FileName
          Text(fileNotifier.filePath ?? 'No file selected'),
          const Divider(color: Colors.transparent),

          /// Progress Status
          ...status,
        ],
      );
    }

    Future<R?> showDialogBegin() {
      return showDialog<R>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AsyncConfirmationDialog<R>(
            title: Text(title),
            styleId: styleId,
            initialContent: content([Text(confirmationText)]),
            onConfirm: () => fileNotifier.processWithNotify(onConfirmOperation),
            onConfirmContent: (BuildContext context, AsyncSnapshot<R> snapshot) => content([
              ValueListenableBuilder(
                valueListenable: fileNotifier.progressNotifier,
                builder: (context, value, child) => LinearProgressIndicator(value: value),
              ),
              ValueListenableBuilder(
                valueListenable: fileNotifier.statusNotifier,
                builder: (context, value, child) => Text(value ?? ''),
              ),
              if (snapshot.connectionState == ConnectionState.done) resultContent(context, snapshot),
            ]),
          );
        },
      );
    }

    return ElevatedButton.icon(onPressed: enabled ? showDialogBegin : null, icon: Icon(iconData), label: Text(title));
  }
}

class const FileOperationText(final FileStorageNotifier fileNotifier, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FutureBuilder(
        future: fileNotifier.operationCompleted,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          return switch (snapshot) {
            AsyncSnapshot(hasError: true) => Text('Error: ${snapshot.error}'), // if user operation throws error
            AsyncSnapshot(connectionState: ConnectionState.done) => Text('Complete: ${fileNotifier.status}'),
            AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.waiting) => ValueListenableBuilder(
              valueListenable: fileNotifier.statusNotifier,
              builder: (context, value, child) => Text(value ?? ''),
            ),
          };
        },
      ),
    );
  }
}

extension FileStoragePickFile on FileStorage {
  /// File picker using settings
  Future<File?> pickFile({List<String>? allowedExtensions}) async {
    allowedExtensions ??= extensions;
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      windowsOptions: const WindowsOptions(lockParentWindow: true),
    );
    return result != null ? File.fromUri(result.uri) : null;
  }

  /// Selects a destination and saves the built contents there.
  Future<File?> pickAndSaveFile({List<String>? allowedExtensions, String? defaultName}) async {
    allowedExtensions ??= extensions;
    defaultName ??= this.defaultName;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final contents = Uint8List.fromList(utf8.encode(stringCodec.encode(buildContents())));
      final uri = await FilePicker.saveFile(
        bytes: contents,
        windowsOptions: const WindowsOptions(lockParentWindow: true),
        dialogTitle: 'Save As:',
        fileName: '${defaultName ?? 'untitled'}.${allowedExtensions?.first ?? 'txt'}',
      );
      return uri != null ? File.fromUri(uri) : null;
    } else {
      return saveContents(pickFile(allowedExtensions: allowedExtensions));
    }
  }
}

// class FileButtonTheme extends ThemeExtension<FileButtonTheme> {
//   const FileButtonTheme({this.buttonStyle});

//   final ButtonStyle? buttonStyle;

//   final IconData openIcon = Icons.file_open;
//   final IconData saveIcon = Icons.file_copy;
//   final String openTitle = 'Open File';
//   final String saveTitle = 'Save File';

//   Color? get iconColorAsBackgroundColor => buttonStyle?.backgroundColor?.resolve({});

//   @override
//   FileButtonTheme copyWith({
//     ButtonStyle? buttonStyle,
//   }) {
//     return FileButtonTheme(
//       buttonStyle: buttonStyle ?? this.buttonStyle,
//     );
//   }

//   @override
//   ThemeExtension<FileButtonTheme> lerp(covariant ThemeExtension<FileButtonTheme>? other, double t) {
//     throw UnimplementedError();
//   }
// }
